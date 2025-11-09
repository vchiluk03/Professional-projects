#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sim_bp.h"
#include <vector>
#include <iostream>
#include <math.h>
#include <stdint.h>
#include <iomanip>

using namespace std;

int extract_index(int pc, int m, int n, int ghr) {
   uint32_t index = ((pc >> 2) & ((1 << m) - 1)); // m-bit segment
   if (n > 0) {
       uint32_t upper_n_bits = (index >> (m - n)) & ((1 << n) - 1);
       uint32_t lower_m_minus_n_bits = index & ((1 << (m - n)) - 1);
       uint32_t xor_result = upper_n_bits ^ ghr;
       index = (xor_result << (m - n)) | lower_m_minus_n_bits;
   }
   return index;
}

int main(int argc, char* argv[]) {
    FILE *FP;
    char *trace_file;
    bp_params params = {0}; // Initialize all fields of params to 0
    char outcome;
    unsigned long int addr;
    uint32_t mispredictions = 0, total_predictions = 0;

    int gshare_table_size = 0;
    int ghr = 0;
    int bimodal_table_size = 0;
    int chooser_table_size = 0;

    if (!(argc == 4 || argc == 5 || argc == 7)) {
        cerr << "Error: Wrong number of inputs: " << argc - 1 << endl;
        return EXIT_FAILURE;
    }

    params.bp_name = argv[1];

    if (strcmp(params.bp_name, "bimodal") == 0) {
        if (argc != 4) {
            cerr << "Error: " << params.bp_name << " wrong number of inputs: " << argc - 1 << endl;
            return EXIT_FAILURE;
        }
        params.M2 = strtoul(argv[2], NULL, 10);
        trace_file = argv[3];
        bimodal_table_size = 1 << params.M2;
        cout << "COMMAND\n" << argv[0] << " " << params.bp_name << " " << params.M2 << " " << trace_file << endl;

    }
    else if (strcmp(params.bp_name, "gshare") == 0) {
        if (argc != 5) {
            cerr << "Error: " << params.bp_name << " wrong number of inputs: " << argc - 1 << endl;
            return EXIT_FAILURE;
        }
        params.M1 = strtoul(argv[2], NULL, 10);
        params.N = strtoul(argv[3], NULL, 10);
        trace_file = argv[4];
        gshare_table_size = 1 << params.M1;
        cout << "COMMAND\n" << argv[0] << " " << params.bp_name << " " << params.M1 << " " << params.N << " " << trace_file << endl;
    }
    else if (strcmp(params.bp_name, "hybrid") == 0) {
        if (argc != 7) {
            cerr << "Error: " << params.bp_name << " wrong number of inputs: " << argc - 1 << endl;
            return EXIT_FAILURE;
        }
        params.K = strtoul(argv[2], NULL, 10);
        params.M1 = strtoul(argv[3], NULL, 10);
        params.N = strtoul(argv[4], NULL, 10);
        params.M2 = strtoul(argv[5], NULL, 10);
        trace_file = argv[6];
        gshare_table_size = 1 << params.M1;
        bimodal_table_size = 1 << params.M2;
        chooser_table_size = 1 << params.K;
        cout << "COMMAND\n" << argv[0] << " " << params.bp_name << " " << params.K << " " << params.M1 << " " << params.N << " " << params.M2 << " " << trace_file << endl;
    }
    else {
        cerr << "Error: Wrong branch predictor name: " << params.bp_name << endl;
        return EXIT_FAILURE;
    }

    // // Print the COMMAND line as per the expected output
    // cout << "COMMAND" << endl;
    // cout << " ./sim";
    // for (int i = 1; i < argc; i++) {
    //     cout << " " << argv[i];
    // }
    // cout << endl;

    // Initialize prediction tables
    vector<int> gshare_table(gshare_table_size, 2);
    vector<int> bimodal_table(bimodal_table_size, 2);
    vector<int> chooser_table(chooser_table_size, 1);

    FP = fopen(trace_file, "r");
    if (FP == NULL) {
        cerr << "Error: Unable to open file " << trace_file << endl;
        return EXIT_FAILURE;
    }

    char str[2];
    while (fscanf(FP, "%lx %s", &addr, str) != EOF) {
        outcome = str[0];
        
        // // Calculate indices
        // int gshare_index = gshare_table_size ? extract_index(addr, params.M1, params.N, gshare_history) : 0;
        // int bimodal_index = bimodal_table_size ? extract_index(addr, params.M2, 0, 0) : 0;
        // int chooser_index = chooser_table_size ? ((addr >> 2) & (chooser_table_size - 1)) : 0;

        int gshare_index = extract_index(addr, params.M1, params.N, ghr);
        int bimodal_index =  extract_index(addr, params.M2, 0, 0);
        int chooser_index = ((addr >> 2) & (chooser_table_size - 1));

        bool actual_outcome = (outcome == 't');
        bool gshare_prediction = gshare_index < gshare_table_size && gshare_table[gshare_index] >= 2;
        bool bimodal_prediction = bimodal_index < bimodal_table_size && bimodal_table[bimodal_index] >= 2;
        bool chosen_prediction;

        if (strcmp(params.bp_name, "hybrid") == 0) {
            chosen_prediction = chooser_index < chooser_table_size && chooser_table[chooser_index] >= 2 ? gshare_prediction : bimodal_prediction;
            if (chosen_prediction != actual_outcome) mispredictions++;

            if (chooser_index < chooser_table_size) {
                if (chooser_table[chooser_index] >= 2) {
                    if (gshare_index < gshare_table_size) {
                        if (actual_outcome) {
                            if (gshare_table[gshare_index] < 3) gshare_table[gshare_index]++;
                        } else {
                            if (gshare_table[gshare_index] > 0) gshare_table[gshare_index]--;
                        }
                    }
                } else {
                    if (bimodal_index < bimodal_table_size) {
                        if (actual_outcome) {
                            if (bimodal_table[bimodal_index] < 3) bimodal_table[bimodal_index]++;
                        } else {
                            if (bimodal_table[bimodal_index] > 0) bimodal_table[bimodal_index]--;
                        }
                    }
                }

                if (gshare_prediction == actual_outcome && bimodal_prediction != actual_outcome) {
                    if (chooser_table[chooser_index] < 3) chooser_table[chooser_index]++;
                } else if (bimodal_prediction == actual_outcome && gshare_prediction != actual_outcome) {
                    if (chooser_table[chooser_index] > 0) chooser_table[chooser_index]--;
                }
            }
        }
        else if (strcmp(params.bp_name, "gshare") == 0) {
            chosen_prediction = gshare_prediction;
            if (chosen_prediction != actual_outcome) mispredictions++;

            if (gshare_index < gshare_table_size) {
                if (actual_outcome) {
                    if (gshare_table[gshare_index] < 3) gshare_table[gshare_index]++;
                } else {
                    if (gshare_table[gshare_index] > 0) gshare_table[gshare_index]--;
                }
            }
        }
        else { // bimodal predictor
            chosen_prediction = bimodal_prediction;
            if (chosen_prediction != actual_outcome) mispredictions++;

            if (bimodal_index < bimodal_table_size) {
                if (actual_outcome) {
                    if (bimodal_table[bimodal_index] < 3) bimodal_table[bimodal_index]++;
                } else {
                    if (bimodal_table[bimodal_index] > 0) bimodal_table[bimodal_index]--;
                }
            }
        }

        // Always update GHR for gshare predictor
        if ((strcmp(params.bp_name, "gshare") == 0 || strcmp(params.bp_name, "hybrid") == 0) && params.N > 0) {
            ghr = (ghr >> 1) | (actual_outcome << (params.N - 1));
        }

        total_predictions++;
    }

    fclose(FP);

    cout << "OUTPUT\n";
    cout << "number of predictions:    " << total_predictions << endl;
    cout << "number of mispredictions: " << mispredictions << endl;
    cout << "misprediction rate:       " << fixed << setprecision(2) << static_cast<double>(mispredictions) / total_predictions * 100 << "%" << endl;

    if (strcmp(params.bp_name, "bimodal") == 0) {
        cout << "FINAL BIMODAL CONTENTS" << endl;
        for (int i = 0; i < bimodal_table_size; i++) {
            cout << i << "\t" << bimodal_table[i] << endl;
        }
    } else if (strcmp(params.bp_name, "gshare") == 0) {
        cout << "FINAL GSHARE CONTENTS" << endl;
        for (int i = 0; i < gshare_table_size; i++) {
            cout << i << "\t" << gshare_table[i] << endl;
        }
    } else { // hybrid
        cout << "FINAL CHOOSER CONTENTS" << endl;
        for (int i = 0; i < chooser_table_size; i++) {
            cout << i << "\t" << chooser_table[i] << endl;
        }
        cout << "FINAL GSHARE CONTENTS" << endl;
        for (int i = 0; i < gshare_table_size; i++) {
            cout << i << "\t" << gshare_table[i] << endl;
        }
        cout << "FINAL BIMODAL CONTENTS" << endl;
        for (int i = 0; i < bimodal_table_size; i++) {
            cout << i << "\t" << bimodal_table[i] << endl;
        }
    }

    return 0;
}
