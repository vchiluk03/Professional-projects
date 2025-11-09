#include <stdio.h>
#include <iostream>
#include <deque>
#include <cstdint>
#include <iomanip>
#include <stdlib.h>
#include <string.h>
#include <vector>
#include <inttypes.h>
#include <algorithm>
#include <map>
#include "sim_proc.h"

using namespace std;
// Define the structure for an instruction
struct Instruction {
    uint64_t pc = 0;
    int seq_no = -1;
    int op_type = -1;
    int dest = -1;
    int src1 = -1;
    int src2 = -1;
    bool src1_valid = false;
    bool src2_valid = false;
    bool dest_valid = false;
    int src1_renamed = -1;
    int src2_renamed = -1;
    int dest_renamed = -1;
    uint64_t fetch_entry_cycle = 0;
    uint64_t decode_entry_cycle = 0;
    uint64_t rename_entry_cycle = 0;
    uint64_t regread_entry_cycle = 0;
    uint64_t dispatch_entry_cycle = 0;
    uint64_t issue_entry_cycle = 0;
    uint64_t execute_entry_cycle = 0;
    uint64_t writeback_entry_cycle = 0;
    uint64_t retire_entry_cycle = 0;
    uint64_t regread_duration = 0;
};

struct ROBEntry {
    //bool valid;
    bool ready;
    bool valid;
    int destination;
    uint64_t pc;
    Instruction instruction;
};

struct RMTEntry {
    bool valid;
    int rob_tag;
};

struct ExecuteEntry {
    unsigned int seq_no; // Sequence number of the instruction
    int latency;         // Execution latency

    // Add this constructor
    ExecuteEntry(unsigned int s, int l) : seq_no(s), latency(l) {}
};


struct Issue_queue_table {
    bool valid;            // Indicates if the entry is valid (occupied)
    bool src1_ready;       // Indicates if source operand 1 is ready
    bool src2_ready;       // Indicates if source operand 2 is ready
    int src1_tag;          // Dependency tag for source operand 1
    int src2_tag;          // Dependency tag for source operand 2
    int dst_tag;           // Dependency tag for destination
    unsigned int seq_no;   // Sequence number to track the age of the instruction

    // Constructor to initialize the entry
    Issue_queue_table()
        : valid(false), src1_ready(false), src2_ready(false),
          src1_tag(-1), src2_tag(-1), dst_tag(-1), seq_no(0) {}
};


std::deque<Instruction> DE, RN, RR, DI, IS, EX, WB;  // Pipeline Buffers
std::deque<ExecuteEntry> execute_list; // List to store executing instructions
std::vector<ROBEntry> ROB;
std::vector<RMTEntry> RMT(67);
std::vector<bool> ARF(67, true); // 67 architectural registers, initially all ready
std::vector<Issue_queue_table> entries;


std::map<unsigned int, Instruction> instruction_map; // Map seq_no to Instruction

unsigned int current_cycle = 0; // Current simulation cycle
int seq_counter = 0;           // Global sequence number counter
int dynamic_instruction_count = 0; // Number of retired instructions
int ROB_head = 0;
int ROB_tail = 0;
bool ROB_is_full = false;
const int ROB_START = 67; // ROB tags start after ARF ends
int rob_tag = ROB_head + ROB_START;


/*========================================================================================================================================*/
void PrintROB() {
    std::cout << "\n[ROB Table]\n";
    std::cout << "ID\tReady\tvalid\tDest\tPC\n";
    for (size_t i = 0; i < ROB.size(); ++i) {
        std::cout << (ROB_START + i) << "\t" 
                  << ROB[i].ready << "\t"
                  << ROB[i].valid << "\t"
                  << ROB[i].destination << "\t"
                  << "0x" << std::hex << ROB[i].pc << std::dec << "\n";
    }
    std::cout << "\n";
}

void PrintRMT() {
    std::cout << "\n[RMT Table]\n";
    std::cout << "Reg\tValid\tROB Tag\n";
    for (size_t i = 0; i < RMT.size(); ++i) {
        std::cout << i << "\t" 
                  << RMT[i].valid << "\t" 
                  << RMT[i].rob_tag << "\n";
    }
    std::cout << "\n";
}

void PrintIssueQueueTable() {
    std::cout << "\n[Issue Queue Table]\n";
    std::cout << "Idx\tValid\tSrc1Ready\tSrc2Ready\tSrc1Tag\tSrc2Tag\tDstTag\tSeqNo\n";
    for (size_t i = 0; i < entries.size(); ++i) {
        const auto& entry = entries[i];
        std::cout << i << "\t" 
                  << entry.valid << "\t" 
                  << entry.src1_ready << "\t\t" 
                  << entry.src2_ready << "\t\t" 
                  << entry.src1_tag << "\t" 
                  << entry.src2_tag << "\t" 
                  << entry.dst_tag << "\t" 
                  << entry.seq_no << "\n";
    }
    std::cout << "\n";
}


void PrintBuffer(const std::deque<Instruction>& buffer, const std::string& name) {
    std::cout << "[" << name << "] Buffer Contents:\n";
    for (const auto& inst : buffer) {
        std::cout << "Seq_no: " << inst.seq_no
                  << " | PC: 0x" << std::hex << inst.pc << std::dec
                  << " | Src1: " << inst.src1 << " (Renamed: " << inst.src1_renamed << ")"
                  << " | Src2: " << inst.src2 << " (Renamed: " << inst.src2_renamed << ")"
                  << " | Dest: " << inst.dest << " (Renamed: " << inst.dest_renamed << ")"
                  << " | Fetch Cycle: " << inst.fetch_entry_cycle
                  << " | Decode Cycle: " << inst.decode_entry_cycle
                  << " | Rename Cycle: " << inst.rename_entry_cycle
                  << " | RegRead Cycle: " << inst.regread_entry_cycle
                  << " | Duration: " << inst.regread_duration << "\n";
    }
    if (buffer.empty()) {
        std::cout << "[" << name << "] Buffer is empty.\n";
    }
}

void PrintExecuteList() {
    std::cout << "[Execute List] Contents:\n";
    if (execute_list.empty()) {
        std::cout << "[Execute List] is empty.\n";
    } else {
        for (const auto& entry : execute_list) {
            std::cout << "Seq_no: " << entry.seq_no
                      << " | Latency Remaining: " << entry.latency << "\n";
        }
    }
    std::cout << "\n";
}
/*=======================================================================================================================================*/
void Fetch(FILE* FP, unsigned int WIDTH) {
    //std::cout << "[FETCH] Cycle: " << current_cycle << " | Fetching instructions...\n";
    while (!feof(FP) && DE.size() < WIDTH) {
        Instruction inst;
        if (fscanf(FP, "%lx %d %d %d %d", &inst.pc, &inst.op_type, &inst.dest, &inst.src1, &inst.src2) == 5) {
            inst.fetch_entry_cycle = current_cycle;
            inst.seq_no = seq_counter++;
            //std::cout << "inst.fetch_entry_cycle :  "  << inst.fetch_entry_cycle  << std::endl;
            //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;
            // Initialize validity flags for source and destination registers
            inst.src1_valid = (inst.src1 >= 0 && static_cast<size_t>(inst.src1) < RMT.size());
            inst.src2_valid = (inst.src2 >= 0 && static_cast<size_t>(inst.src2) < RMT.size());
            inst.dest_valid = (inst.dest >= 0 && static_cast<size_t>(inst.dest) < RMT.size());

            DE.push_back(inst);

            // Debug print for the fetched instruction
            // std::cout << "[FETCH] Instruction fetched: "
            //           << "PC: 0x" << std::hex << inst.pc
            //           << " | Seq_no: " << std::dec << inst.seq_no
            //           << " | Src1: " << inst.src1 << " | Src2: " << inst.src2
            //           << " | Dest: " << inst.dest << "\n";
        } else {
            break; // Stop fetching if input is invalid
        }
    }
    // Print the DE buffer after fetching
    //PrintBuffer(DE, "DE (After Fetch)");
    //PrintROB();
    //PrintRMT();
}

void Decode(unsigned int WIDTH) {
    //std::cout << "[DECODE] Cycle: " << current_cycle << " | Decoding instructions...\n";
    while (RN.size() < WIDTH && !DE.empty()) {
        Instruction inst = DE.front();
        inst.decode_entry_cycle = current_cycle;
        //std::cout << "inst.decode_entry_cycle :  "  << inst.decode_entry_cycle  << std::endl;
         //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;
        RN.push_back(inst);
        DE.pop_front();

        // Debug print for the decoded instruction
        // std::cout << "[DECODE] Instruction decoded: "
        //           << "Seq_no: " << inst.seq_no
        //           << " | Src1: " << inst.src1 << " | Src2: " << inst.src2
        //           << " | Dest: " << inst.dest << "\n";
    }
    //PrintROB();
    //PrintRMT();
    // Print buffers after decoding
    //PrintBuffer(DE, "DE (After Decode)");
    //PrintBuffer(RN, "RN (After Decode)");
    
}

void Rename(unsigned int ROB_SIZE, unsigned int WIDTH) {
    // std::cout << "[RENAME] Cycle: " << current_cycle << " | Renaming instructions...\n";
    // std::cout << "Initial ROB state: ROB Head = " << ROB_head
    //           << ", ROB Tail = " << ROB_tail
    //           << ", ROB Size = " << ROB_SIZE << std::endl;

    // Calculate free ROB entries
    int free_rob_entries;
    if (ROB_is_full) {
        free_rob_entries = 0; // If the ROB is full, no free entries
    } else if (ROB_head == ROB_tail) {
        free_rob_entries = ROB_SIZE; // Empty ROB
    } else if (ROB_head < ROB_tail) {
        free_rob_entries = ROB_SIZE - (ROB_tail - ROB_head);
    } else {
        free_rob_entries = ROB_head - ROB_tail;
}

    //std::cout << " Calculated free ROB Entries = " << free_rob_entries << std::endl;

    // Check if there are enough free ROB entries for all instructions in RN
    if (free_rob_entries < static_cast<int>(RN.size())) {
        // std::cout << "[RENAME] Not enough ROB entries for all instructions in RN. Free entries: "
        //           << free_rob_entries << ", Instructions in RN: " << RN.size() << "\n";
        return; // Exit early if there aren't enough free entries
    }

    // Rename instructions while adhering to WIDTH constraint
    while (RR.size() < WIDTH && !RN.empty()) {
        // Get the oldest instruction from RN
        Instruction inst = RN.front();
        RN.pop_front();

        // Stall if the ROB is full
        if (ROB_is_full) {
            // std::cout << "[RENAME] ROB is full. Stalling...\n";
            RN.push_front(inst); // Push the instruction back to RN
            return; // Exit early
        }

        // Allocate ROB entry
        int rob_id = ROB_tail;

        // Mark the ROB entry
        ROB[rob_id].ready = false; // Initializing the fields
        ROB[rob_id].valid = true;
        ROB[rob_id].destination = inst.dest;
        ROB[rob_id].pc = inst.pc;

        // Debug: Print updated ROB state
        // std::cout << "Updated ROB state: ROB Head = " << ROB_head
        //           << ", ROB Tail = " << ROB_tail
        //           << ", ROB ID = " << rob_id
        //           << ", Free Entries = " << free_rob_entries << "\n";

        // Rename source registers
        if (inst.src1_valid) {
            if (RMT[inst.src1].valid) {
                size_t rob_index = RMT[inst.src1].rob_tag;
                inst.src1_renamed = (rob_index < ROB.size() && ROB[rob_index].ready)
                                        ? inst.src1   // Keep original if ready
                                        : RMT[inst.src1].rob_tag; // Rename if not ready
            } else {
                inst.src1_renamed = inst.src1; // No renaming needed
            }
        } else {
            inst.src1_renamed = -1; // Invalid source
        }

        if (inst.src2_valid) {
            if (RMT[inst.src2].valid) {
                size_t rob_index = RMT[inst.src2].rob_tag;
                inst.src2_renamed = (rob_index < ROB.size() && ROB[rob_index].ready)
                                        ? inst.src2   // Keep original if ready
                                        : RMT[inst.src2].rob_tag; // Rename if not ready
            } else {
                inst.src2_renamed = inst.src2; // No renaming needed
            }
        } else {
            inst.src2_renamed = -1; // Invalid source
        }
        
        // Rename destination register
        inst.dest_renamed = rob_id + ROB_START; // Use ROB_START for logical ROB tag
        if (inst.dest_valid) {
            RMT[inst.dest] = {true, inst.dest_renamed}; // Store the ROB tag in the RMT
        }

        // Update rename entry cycle
        inst.rename_entry_cycle = current_cycle; // Assign current cycle to the rename stage
        //std::cout << "inst.rename_entry_cycle :  "  << inst.rename_entry_cycle  << std::endl;
         //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;
         ROB[rob_id].instruction = inst;

        // Debug print for the renamed instruction
        // std::cout << "[RENAME] Instruction renamed: "
        //           << "Seq_no: " << inst.seq_no
        //           << " | Src1 Renamed: " << inst.src1_renamed
        //           << " | Src2 Renamed: " << inst.src2_renamed
        //           << " | Dest Renamed: " << inst.dest_renamed
        //           << " | ROB ID: " << rob_id + ROB_START << "\n";

        // Push the instruction to the RR buffer
        RR.push_back(inst);

        // Update ROB tail pointer and handle wrap-around
        if (ROB_tail == ROB_SIZE - 1) {
            // If ROB tail reaches the end, consider it full
            if (ROB_head == 0) {
                ROB_is_full = true; // Set the ROB_is_full flag
            } else {
                ROB_tail = 0; // Wrap around to 0 if space is available
            }
        } else {
            ROB_tail++;
        }
    }

    // Print buffers after renaming
    // PrintBuffer(RN, "RN (After Rename)");
    // PrintBuffer(RR, "RR (After Rename)");
    // PrintROB(); // ROB tags will start at ROB_START in this function
    // PrintRMT();
}





//-------------------------------------------------RR STAGE-------------------------------------------------/
void RegRead(unsigned int WIDTH, unsigned int ROB_SIZE) {
    //std::cout << "[REGREAD] Cycle: " << current_cycle << " | Starting RegRead stage...\n";

    // Print the RR buffer before processing
    //PrintBuffer(RR, "RR (Before RegRead)");
    
    // If the Dispatch (DI) buffer is full, return immediately
    if (DI.size() >= WIDTH) {
        //std::cout << "[REGREAD] DI buffer is full. Cannot move instructions.\n";
        return;
    }
    

    unsigned int instructions_moved = 0; // Counter for instructions moved in this cycle

    // Process up to WIDTH instructions from the RR buffer
    while (!RR.empty() && instructions_moved < WIDTH) {
        Instruction& inst = RR.front(); // Access the oldest instruction in the RR buffer
        inst.regread_entry_cycle = current_cycle;
        //std::cout << "inst.regread_entry_cycle :  "  << inst.regread_entry_cycle  << std::endl;
         //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;
        
    // std::cout << "[REGREAD] Processing instruction | Seq_no: " << inst.seq_no
    //         << " | Src1 Renamed: " << (inst.src1_renamed != -1 ? std::to_string(inst.src1_renamed) : "None")
    //         << " | Src2 Renamed: " << (inst.src2_renamed != -1 ? std::to_string(inst.src2_renamed) : "None")
    //         << " | Dest Renamed: " << inst.dest_renamed
    //         << " | RegRead Entry Cycle: " << inst.regread_entry_cycle << "\n";


    if (inst.src1_renamed != -1 && inst.src1_renamed >= ROB_START) {
        int rob_index = inst.src1_renamed - ROB_START;
       if (rob_index >= 0 && rob_index < static_cast<int>(ROB.size()) && ROB[rob_index].ready) {
            inst.src1_renamed = -1; // Mark source as un-renamed
        }
    }
    if (inst.src2_renamed != -1 && inst.src2_renamed >= ROB_START) {
        int rob_index = inst.src2_renamed - ROB_START;
        if (rob_index >= 0 && rob_index < static_cast<int>(ROB.size()) && ROB[rob_index].ready) {
            inst.src2_renamed = -1; // Mark source as un-renamed
        }
    }


        // Move the instruction to the DI buffer regardless of readiness
        //inst.regread_duration = current_cycle - inst.regread_entry_cycle + 1;
        DI.push_back(inst);
        // DI entry cycle = current_cycle + 1;
        RR.pop_front();
        instructions_moved++;

        // std::cout << "[REGREAD] Moved instruction Seq_no: " << inst.seq_no
        //           << " to DI buffer | RegRead Duration: " << inst.regread_duration << "\n";
    }

    // Print the buffers after processing
    //PrintBuffer(RR, "RR (After RegRead)");
    //PrintBuffer(DI, "DI (After RegRead)");
    
    //std::cout << "[REGREAD] Instructions moved: " << instructions_moved << " | Remaining in RR: " << RR.size() << "\n";
    //PrintROB();
    //PrintRMT();
}


void Dispatch(unsigned int IQ_SIZE) {
    //std::cout << "[DISPATCH] Cycle: " << current_cycle << " | Starting Dispatch stage...\n";
    
    // Print the DI buffer before processing
    //PrintBuffer(DI, "DI (Before Dispatch)");

    // Calculate the number of free slots in the Issue Queue
    unsigned int free_slots = 0;
    for (const auto& entry : entries) {
        if (!entry.valid) free_slots++;
    }
    // std::cout << "[DISPATCH] Free slots in Issue Queue: " << free_slots
    //           << " | DI size: " << DI.size() << "\n";

    // Ensure there are enough free slots for all instructions in DI
    if (free_slots < DI.size()) {
        //std::cout << "[DISPATCH] Not enough free slots in Issue Queue for DI instructions.\n";
        return;
    }

    unsigned int instructions_dispatched = 0;

    // Dispatch instructions from DI to the Issue Queue
    while (!DI.empty()) {
        Instruction inst = DI.front();
        DI.pop_front();
        inst.dispatch_entry_cycle = current_cycle;
        // std::cout << "inst.dispatch_entry_cycle :  "  << inst.dispatch_entry_cycle  << std::endl;
        //  std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;
        // std::cout << "[DISPATCH] Attempting to dispatch instruction Seq_no: " << inst.seq_no
        //           << " | Src1 Renamed: " << inst.src1_renamed
        //           << " | Src2 Renamed: " << inst.src2_renamed
        //           << " | Dest Renamed: " << inst.dest_renamed << "\n";

        for (auto& iq_entry : entries) {
            if (!iq_entry.valid) {
                iq_entry.valid = true;
                // Check readiness of src1
        iq_entry.src1_ready = (inst.src1_renamed == -1) || // Not renamed
                              (inst.src1_renamed < 67) ||  // ARF partition (always ready)
                              (inst.src1_renamed >= 67 && 
                               static_cast<size_t>(inst.src1_renamed - 67) < ROB.size() &&
                               ROB[inst.src1_renamed - 67].ready);

        // Check readiness of src2
        iq_entry.src2_ready = (inst.src2_renamed == -1) || // Not renamed
                              (inst.src2_renamed < 67) ||  // ARF partition (always ready)
                              (inst.src2_renamed >= 67 && 
                               static_cast<size_t>(inst.src2_renamed - 67) < ROB.size() &&
                               ROB[inst.src2_renamed - 67].ready);
                //std::cout<< "ROB[inst.src1_renamed - 67].ready" << ROB[inst.src1_renamed - 67].ready << std::endl;
                //std::cout<< "ROB[inst.src2_renamed - 67].ready" << ROB[inst.src2_renamed - 67].ready << std::endl;
                iq_entry.src1_tag = inst.src1_renamed;
                iq_entry.src2_tag = inst.src2_renamed;
                iq_entry.dst_tag = inst.dest_renamed;
                // Assign the sequence number from the instruction
                iq_entry.seq_no = inst.seq_no;
                instruction_map[inst.seq_no] = inst; // Add instruction to map
                //inst.dispatch_entry_cycle = current_cycle;

                // std::cout << "[DISPATCH] Instruction dispatched to IQ: Seq_no: " << inst.seq_no
                //           << " | Src1 Ready: " << iq_entry.src1_ready
                //           << " | Src2 Ready: " << iq_entry.src2_ready
                //           << " | Dest Tag: " << iq_entry.dst_tag << "\n";

                instructions_dispatched++;
                break;
            }
        }
    }

    if (instructions_dispatched == 0) {
        //std::cout << "[DISPATCH] No instructions were dispatched this cycle.\n";
    } else {
        // std::cout << "[DISPATCH] Instructions dispatched: " << instructions_dispatched
        //           << " | Remaining in DI: " << DI.size() << "\n";
    }

    // Print the DI and IQ buffers after processing
    //PrintBuffer(DI, "DI (After Dispatch)");
    //PrintIssueQueueTable();
}





//========================================ISSUE FUNCTION=============================================================================/
void Issue(unsigned int WIDTH) {
    //std::cout << "[ISSUE] Cycle: " << current_cycle << " | Starting Issue stage...\n";
    // Print the Issue Queue before processing
    //PrintIssueQueueTable();
    // Print the Execute List before processing
    //PrintExecuteList();
    unsigned int issued = 0;
    while (issued < WIDTH) {
        int oldest_index = -1;
        unsigned int min_seq_no = UINT32_MAX;
        // Find the next oldest ready instruction
        for (size_t i = 0; i < entries.size(); ++i) {
            const auto& iq_entry = entries[i];
            // Check if the instruction is ready to issue
            if (iq_entry.valid && iq_entry.src1_ready && iq_entry.src2_ready) {
                if (iq_entry.seq_no < min_seq_no) {
                    oldest_index = i;
                    min_seq_no = iq_entry.seq_no;
                }
            }
        }
        // If no ready instruction is found, stop issuing
        if (oldest_index == -1) {
            break;
        }
        // Issue the selected instruction
        auto& iq_entry = entries[oldest_index];
        unsigned int seq_no = iq_entry.seq_no;
        // Fetch the instruction using seq_no
    
        Instruction inst = instruction_map[seq_no];
        inst.issue_entry_cycle = current_cycle;

        //std::cout << "inst.issue_entry_cycle :  "  << inst.issue_entry_cycle  << std::endl;
         //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;


        // Persist the updated instruction  
        instruction_map[seq_no] = inst;
        // Determine execution latency
        int latency = 1; // Default latency
        switch (inst.op_type) {
            case 0: latency = 1; break;  // ADD
            case 1: latency = 2; break;  // MUL
            case 2: latency = 5; break;  // DIV
            default: latency = 1; break; // Default latency
        }
        // Add the instruction to the execute list
        execute_list.push_back(ExecuteEntry(seq_no, latency));
        inst.issue_entry_cycle = current_cycle;
        // std::cout << "[ISSUE] Instruction issued: Seq_no: " << seq_no
        //           << " | Src1 Ready: " << iq_entry.src1_ready
        //           << " | Src2 Ready: " << iq_entry.src2_ready
        //           << " | Latency: " << latency << "\n";
        // Remove the instruction from the IQ (reset entry)
        iq_entry.valid = false;
        iq_entry.src1_ready = false;
        iq_entry.src2_ready = false;
        iq_entry.src1_tag = -1;
        iq_entry.src2_tag = -1;
        iq_entry.dst_tag = -1;
        iq_entry.seq_no = 0;
        ++issued;
    }
    if (issued == 0) {
        //std::cout << "[ISSUE] No instructions were issued this cycle.\n";
    } else {
        // std::cout << "[ISSUE] Instructions issued: " << issued
        //           << " | Remaining in IQ: " << (entries.size() - issued) << "\n";
    }
    // Print the Issue Queue and Execute List after processing
    //PrintIssueQueueTable();
    //PrintExecuteList();
}
//====================================EXECUTE STAGE===============================================================================/

void WakeupDependentInstructions(int dest_reg) {
    bool dependents_woken = false; // Flag to check if any dependents are woken up

    // Wake up dependents in Issue Queue table
    for (auto& iq_entry : entries) {
        if (iq_entry.valid) {
            if (iq_entry.src1_tag == dest_reg) {
                iq_entry.src1_ready = true;  // Mark source 1 as ready
                //iq_entry.src1_tag = -1;     // Clear the dependency tag
                 //std::cout << "[WAKEUP] IQ Entry Source 1 dependency resolved for Dest Reg " << dest_reg << ".\n";
                // PrintIssueQueueTable();
                dependents_woken = true;
            }
            if (iq_entry.src2_tag == dest_reg) {
                iq_entry.src2_ready = true;  // Mark source 2 as ready
                //iq_entry.src2_tag = -1;     // Clear the dependency tag
                 //std::cout << "[WAKEUP] IQ Entry Source 2 dependency resolved for Dest Reg " << dest_reg << ".\n";
                // PrintIssueQueueTable();
                dependents_woken = true;
            }
        }
    }

    // Wake up dependents in Dispatch (DI) buffer
    for (auto& inst : DI) {
        if (inst.src1_renamed == dest_reg) {
            inst.src1_renamed = inst.src1;  // Clear the dependency
            //std::cout << "[WAKEUP] DI Buffer Source 1 dependency resolved for Dest Reg " << dest_reg << ".\n";
            dependents_woken = true;
        }
        if (inst.src2_renamed == dest_reg) {
            inst.src2_renamed = inst.src2;  // Clear the dependency
            //std::cout << "[WAKEUP] DI Buffer Source 2 dependency resolved for Dest Reg " << dest_reg << ".\n";
            dependents_woken = true;
        }
    }

    // Wake up dependents in RegRead (RR) buffer
    for (auto& inst : RR) {
        if (inst.src1_renamed == dest_reg) {
            inst.src1_renamed = -1;  // Clear the dependency
            //std::cout << "[WAKEUP] RR Buffer Source 1 dependency resolved for Dest Reg " << dest_reg << ".\n";
            dependents_woken = true;
        }
        if (inst.src2_renamed == dest_reg) {
            inst.src2_renamed = -1;  // Clear the dependency
            //std::cout << "[WAKEUP] RR Buffer Source 2 dependency resolved for Dest Reg " << dest_reg << ".\n";
            dependents_woken = true;
        }
    }

    // Final debug statement
    if (dependents_woken) {
        //std::cout << "[WAKEUP] Dependents of Dest Reg " << dest_reg << " have been successfully woken up.\n";
    } else {
        //std::cout << "[WAKEUP] No dependents found for Dest Reg " << dest_reg << ".\n";
    }
}

void Execute() {
    //std::cout << ColorText("[EXECUTE] Cycle: " + std::to_string(current_cycle) + " | Processing Execute stage...\n", CYAN);
    //std::cout << "[EXECUTE] Cycle: " << current_cycle << " | Processing Execute stage...\n";

    // Print the Execute List before processing
    //PrintExecuteList();

    for (auto it = execute_list.begin(); it != execute_list.end();) {
        ExecuteEntry& entry = *it;
        Instruction& inst = instruction_map[entry.seq_no];
        // Set the execution entry cycle if not already set
            if (inst.execute_entry_cycle == 0) {
                inst.execute_entry_cycle = current_cycle;
                //std::cout << "inst.execute_entry_cycle :  "  << inst.execute_entry_cycle  << std::endl;
                 //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;
            }
            //std::cout<< "Execute start cycle  : " << inst.execute_entry_cycle << "Sequence Number  :  " << entry.seq_no << std::endl;

        if (entry.latency == 1) {
            // Fetch the instruction corresponding to the seq_no
            

            // Wake up dependents in DI, RR, and IQ during the last cycle of execution
            //  std::cout << "[EXECUTE] Instruction in last cycle: Seq_no: " << entry.seq_no
            //            << " | Waking up dependents for Dest Renamed: " << inst.dest_renamed << ".\n";
            WakeupDependentInstructions(inst.dest_renamed);

            // Push the instruction to Writeback (WB) buffer
            WB.push_back(inst);
            // std::cout << "[EXECUTE] Instruction moved to Writeback: Seq_no: " << inst.seq_no << "\n";

            // Remove the instruction from the execute list
            it = execute_list.erase(it);

            continue; // Skip incrementing iterator since the current entry was erased
        }

        // Decrement the latency timer for this instruction
        entry.latency--;

        // Debug statement for instructions still in execution
        // std::cout << "[EXECUTE] Instruction in progress: Seq_no: " << entry.seq_no
        //           << " | Latency Remaining: " << entry.latency << "\n";
        ++it;
    }

    // Print the Execute List after processing
    //PrintExecuteList();
}


/*===========================================================================================================================================================*/
bool is_in_writeback(int tag) {
    for (const auto& inst : WB) {
        if (inst.dest_renamed == tag) {
            return true;
        }
    }
    return false;
}
 
void Writeback() {
    //std::cout << "[WRITEBACK] Cycle: " << current_cycle << " | Processing Writeback stage...\n";

    if (WB.empty()) {
        //std::cout << "[WRITEBACK] Writeback buffer is empty.\n";
        return;
    }

    unsigned int instructions_written_back = 0;

    while (!WB.empty()) {
        // Fetch the instruction at the front of the WB buffer
        Instruction inst = WB.front();
        WB.pop_front();

        // Record the writeback entry cycle
        inst.writeback_entry_cycle = current_cycle;
        //std::cout << "inst.writeback_entry_cycle :  "  << inst.writeback_entry_cycle  << std::endl;
         //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;

        // std::cout << "[WRITEBACK] Instruction completing Writeback: Seq_no: " << inst.seq_no
        //           << " | Dest Renamed: " << inst.dest_renamed << "\n";

        // Update the ROB entry with the writeback cycle
        if (inst.dest_renamed >= 0 && static_cast<size_t>(inst.dest_renamed - ROB_START) < ROB.size()) {
            size_t rob_index = inst.dest_renamed - ROB_START;
            ROB[rob_index].ready = true;  
            //ROB[rob_index].valid = false;             // Mark ROB entry as ready
            ROB[rob_index].instruction = inst;         // Update instruction in ROB

            // std::cout << "[WRITEBACK] Marked ready in ROB: ROB Index: " << rob_index
            //           << " | Dest Renamed: " << inst.dest_renamed << "\n";
            //Wake up dependents using the function
            WakeupDependentInstructions(inst.dest_renamed);
        } else {
            // std::cout << "[WRITEBACK] Invalid destination tag: " << inst.dest_renamed
            //           << " (No update to ROB).\n";
        }

        instructions_written_back++;
    }
    // PrintROB();
    // PrintRMT();
    // std::cout << "[WRITEBACK] Instructions written back this cycle: " << instructions_written_back << "\n";
}


void Retire(unsigned int WIDTH) {
    //std::cout << "[RETIRE] Cycle: " << current_cycle << " | Processing Retire stage...\n";

    unsigned int retired = 0; // Counter for retired instructions
    //std::cout<<"ROB_head  :  " << ROB_head << "ROB_tail  :  " << ROB_tail<< std::endl;
    // Retire up to WIDTH consecutive instructions
    while (retired < WIDTH ) {
        ROBEntry& rob_entry = ROB[ROB_head];

        // Check if the head instruction is ready to retire
        if (!rob_entry.ready) {
            //std::cout << "[RETIRE] ROB Head instruction not ready: ROB Index: " << ROB_head << "\n";
            break; // Stop retiring if the head instruction is not ready
        }

        // Retire the instruction
        Instruction& inst = rob_entry.instruction;

        // Record the retire cycle
        inst.retire_entry_cycle = current_cycle;
        //std::cout << "inst.retire_entry_cycle :  "  << inst.retire_entry_cycle  << std::endl;
         //std::cout << "Instruction Number  :  " << inst.seq_no << std::endl;

        // Calculate the cycles for each stage and ensure proper increments
        inst.regread_duration = inst.regread_entry_cycle > 0
            ? inst.dispatch_entry_cycle - inst.regread_entry_cycle
            : 0; // Ensure non-negative duration

        // Print the instruction's lifecycle in the required format
        //std::cout << "[RETIRE] Retiring instruction: Seq_no: " << inst.seq_no << "\n";
        std::cout << inst.seq_no << " fu{" << inst.op_type << "} "
                  << "src{" << inst.src1 << "," << inst.src2 << "} "
                  << "dst{" << inst.dest << "} "
                  << "FE{" << inst.fetch_entry_cycle << "," 
                  << (inst.decode_entry_cycle - inst.fetch_entry_cycle) << "} "
                  << "DE{" << inst.decode_entry_cycle << "," 
                  << (inst.rename_entry_cycle - inst.decode_entry_cycle) << "} "
                  << "RN{" << inst.rename_entry_cycle << "," 
                  << (inst.regread_entry_cycle - inst.rename_entry_cycle) << "} "
                  << "RR{" << inst.regread_entry_cycle << "," 
                  << (inst.dispatch_entry_cycle - inst.regread_entry_cycle) << "} "
                  << "DI{" << inst.dispatch_entry_cycle << "," 
                  << (inst.issue_entry_cycle - inst.dispatch_entry_cycle) << "} "
                  << "IS{" << inst.issue_entry_cycle << "," 
                  <<  (inst.execute_entry_cycle - inst.issue_entry_cycle)<< "} "
                  << "EX{" << inst.execute_entry_cycle << "," 
                  << (inst.writeback_entry_cycle - inst.execute_entry_cycle) << "} "
                  << "WB{" << inst.writeback_entry_cycle << "," 
                  << (inst.retire_entry_cycle - inst.writeback_entry_cycle) << "} "
                  << "RT{" << inst.retire_entry_cycle << "," 
                  << (current_cycle - inst.retire_entry_cycle + 1) << "}\n";

         //PrintROB(); 
         //PrintRMT();
         // Clear the RMT entry if the ROB tag matches
        int dest_reg = inst.dest; // Destination register
        //std::cout<< "ROB_head  :  " << ROB_head << std::endl;
        //std::cout<< "dest_reg :  " << dest_reg << "RMT[dest_reg].valid  :  " << RMT[dest_reg].valid << "RMT[dest_reg].rob_tag  :  " << RMT[dest_reg].rob_tag << std::endl; 
        if (dest_reg >= 0 && RMT[dest_reg].valid && RMT[dest_reg].rob_tag == ROB_head + ROB_START) {
            RMT[dest_reg] = {false, 0}; // Clear the RMT entry
            // std::cout << "[RETIRE] Cleared RMT entry for Dest Reg: " << dest_reg
            //           << " | ROB Tag: " << ROB_head << "\n";
        }
        //PrintRMT();
        // Clear the ROB entry
        rob_entry = {false, false, -1, 0, {}}; // Reset the ROB entry
        //std::cout << "[RETIRE] Cleared ROB entry at index: " << ROB_head << "\n";

        // Advance the ROB head
        ROB_head = (ROB_head + 1) % ROB.size();
        if (ROB_is_full && ROB_head != ROB_tail) {
            ROB_is_full = false;
            ROB_tail = 0;
            //std::cout << "[RETIRE] ROB is no longer full. Cleared ROB_is_full flag.\n";
        } 
        // else {
        //     ROB_tail++;
        // }
        //ROB_tail = 0;
        //std::cout << "[RETIRE] Advanced ROB Head to index: " << ROB_head << "\n";

        retired++; // Increment the retired counter
        dynamic_instruction_count++;
    }

    if (retired == 0) {
        //std::cout << "[RETIRE] No instructions retired this cycle.\n";
    } else {
        //std::cout << "[RETIRE] Total instructions retired this cycle: " << retired << "\n";
    }

    // Debug print for ROB head after retiring
    //std::cout << "[RETIRE] ROB Head after retiring: " << (ROB_head + ROB_START) << "\n";
}



bool Advance_Cycle(FILE* FP) {
    return !(DE.empty() && RN.empty() && RR.empty() && DI.empty() &&
         IS.empty() && execute_list.empty() && WB.empty() && feof(FP));

}

/**
 * Main function:
 * Simulates all pipeline stages and prints the configuration and summary at the end.
 */
int main(int argc, char* argv[]) {
    if (argc != 5) {
        std::cerr << "Error: Wrong number of inputs: " << argc - 1 << std::endl;
        std::cerr << "Usage: " << argv[0] << " <ROB_SIZE> <IQ_SIZE> <WIDTH> <TRACE_FILE>" << std::endl;
        return EXIT_FAILURE;
    }

    proc_params params;
    params.rob_size = strtoul(argv[1], NULL, 10);
    params.iq_size = strtoul(argv[2], NULL, 10);
    params.width = strtoul(argv[3], NULL, 10);
    const char* trace_file = argv[4];

    // Initialize ROB and RMT
    ROB.resize(params.rob_size, {false, false, -1, 0, {}}); // All fields are reset
    RMT.resize(67, RMTEntry());
    ARF.assign(67, true); // All registers initially ready
    // Initialize Issue Queue Table
    entries.resize(params.iq_size, Issue_queue_table());
    //std::cout << "[INIT] ROB, RMT, ARF, and Issue Queue Table initialized.\n";

    // Open trace file
    FILE* FP = fopen(trace_file, "r");
    if (FP == NULL) {
        std::cerr << "Error: Unable to open file " << trace_file << std::endl;
        return EXIT_FAILURE;
    }

    // Main simulation loop
    do {
        //std::cout<<"================================ENTERING RETIRE===================================================================="<< std::endl;
        Retire(params.width);
        //std::cout<<"================================ENTERING WRITEBACK================================================================="<< std::endl;
        Writeback();
        //std::cout<<"================================ENTERING EXECUTE==================================================================="<< std::endl;
        Execute();
        //std::cout<<"================================ENTERING ISSUE====================================================================="<< std::endl;
        Issue(params.width);
        //std::cout<<"================================ENTERING DISPATCH=================================================================="<< std::endl;
        Dispatch(params.iq_size);
        //std::cout<<"================================ENTERING REGREAD==================================================================="<< std::endl;
        RegRead(params.width, params.rob_size);
        //std::cout<<"================================ENTERING RENAME===================================================================="<< std::endl;
        Rename(params.rob_size, params.width);
        //std::cout<<"================================ENTERING DECODE===================================================================="<< std::endl;
        Decode(params.width);
        //std::cout<<"================================ENTERING FETCH====================================================================="<< std::endl;
        Fetch(FP, params.width);
        ++current_cycle;
    } while (Advance_Cycle(FP));

    fclose(FP);

    // Print simulation summary
    std::cout << "# === Simulator Command =========" << std::endl;
    std::cout << "# ./sim " << params.rob_size << " " << params.iq_size << " " << params.width << " " << trace_file << std::endl;
    std::cout << "# === Processor Configuration ===" << std::endl;
    std::cout << "# ROB_SIZE = " << params.rob_size << std::endl;
    std::cout << "# IQ_SIZE  = " << params.iq_size << std::endl;
    std::cout << "# WIDTH    = " << params.width << std::endl;
    std::cout << "# === Simulation Results ========" << std::endl;
    std::cout << "# Dynamic Instruction Count    = " << dynamic_instruction_count << std::endl;
    std::cout << "# Cycles                       = " << current_cycle << std::endl;
    std::cout << "# Instructions Per Cycle (IPC) = " << std::fixed << std::setprecision(2)
              << static_cast<float>(dynamic_instruction_count) / current_cycle << std::endl;

    return EXIT_SUCCESS;
}
