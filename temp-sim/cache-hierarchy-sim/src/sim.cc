#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <math.h>
#include <bitset>
#include <vector>
#include <iomanip>
#include <algorithm>  
#include <deque>
#include "sim.h"

using namespace std;


//Function for Block Offset Extraction
   uint32_t extract_bo (uint32_t test_addr, int bo_bits){
   uint32_t bo_mask = (1 << bo_bits) - 1; // Mask Created 
   return  (bo_mask & test_addr); 
   }

//Function for Index Extraction
uint32_t extract_index (uint32_t test_addr, int idx_bits, int blk_offset_bits){
   uint32_t index_mask = (1 << idx_bits) - 1; // Mask Created 
   uint32_t shift_addr = test_addr >> blk_offset_bits;
   return  (shift_addr & index_mask);
}

//Function for Tag Extraction
uint32_t extract_tag (uint32_t test_addr, int tag_bits){
   uint32_t tag_mask = (1 << tag_bits) - 1; // Mask Created 
   uint32_t shift_addr = test_addr >> (32-tag_bits);
   return  (shift_addr & tag_mask);
}

// Stream Buffer structure
struct stream_buffer {
    bool valid;
    std::deque<uint32_t> blocks;  // Using deque to manage the prefetch blocks as a queue
    int maxSize;  // Maximum size of stream buffer (number of blocks it can hold)
   int lru_counter;

    // Constructor to initialize the stream buffer
    stream_buffer(int size) : valid(false), maxSize(size), lru_counter(0) {}

    // Check if requested block is in the stream buffer
    bool access(uint32_t address) {
        for (std::size_t i = 0; i < blocks.size(); ++i) {
            if (blocks[i] == address) {
                return true;  // Found the address in stream buffer
            }
        }
        return false;
    }

    // Prefetch a sequence of blocks starting from the given address
    void prefetch(uint32_t startAddress, int blockSize) {
        valid = true;  // Mark buffer as valid
        blocks.clear();  // Clear the deque before loading new blocks
        for (int i = 0; i < maxSize; ++i) {
            blocks.push_back(startAddress + (i * blockSize));  // Add the next blocks into the buffer
        }
    }

    // Shift the buffer and add new prefetch blocks
    void shiftAndPrefetchMore(uint32_t blockSize) {
        if (blocks.size() >= static_cast<std::size_t>(maxSize)) {
            blocks.pop_front();  // Remove the oldest block
        }
        uint32_t nextBlock = blocks.back() + blockSize;  // Get the next block to prefetch
        blocks.push_back(nextBlock);  // Add the new block to the buffer
    }
};

struct cacheblk {
    bool valid;
    char dirty;
    int lru_counter;
    uint32_t tag;

    // Constructor to initialize the block
    cacheblk() : valid(false), dirty('C'), lru_counter(0), tag(0) {}
};

class cache {
public:
    int bo_bits,idx_bits,tag_bits;
    int num_sets,assoc,blksize;// Number of Sets, Associativity and Block size of the cache
    int reads,read_misses,writes,write_misses,write_backs,memory_traffic;
    int prefetches,prefetch_reads,prefetch_read_misses;
    cache* next;     // Pointer to next cache level
    std::vector<std::vector<cacheblk>> total_sets;// 2D vector representing the cache cotainer, with data type cacheblk
    std::vector <stream_buffer> prefetch_unit;
    
// Initialize the cache by creating sets and adding blocks to each set
    void initialize_cache() {
        for (int i = 0; i < num_sets; i++)
        {
            std::vector<cacheblk> set;  // Create an empty individual set
            for (int j = 0; j < assoc; j++) {
                cacheblk block;
                set.push_back(block);  // Add block to the set
            }
            total_sets.push_back(set);
        }
    }
// Constructor to initialize the cache
    cache(int size, int assoc, int blksize, int num_stream_buffers, int mem_blocks, cache* nextLevel = nullptr) 
        : assoc(assoc), blksize(blksize), next(nextLevel) {
         num_sets  = size/(assoc * blksize);
         bo_bits = log2(blksize);
         idx_bits = log2(num_sets);
         tag_bits = 32 - (idx_bits + bo_bits);
         reads=read_misses=writes=write_misses=write_backs=memory_traffic = 0;
         prefetches=prefetch_reads=prefetch_read_misses = 0;
         prefetch_unit.resize(num_stream_buffers, stream_buffer(mem_blocks));
        initialize_cache();
    }

    
// Function to simulate cache lookup (read or write)
   bool request(uint32_t addr, bool write) {
        uint32_t tag = extract_tag(addr,tag_bits);
        int index    = extract_index(addr, idx_bits, bo_bits);

    //Corresponding set based on the index
        auto& set = total_sets[index];

    // Look for corresponding block based on tag
        for(int i=0; i<assoc; i++){
            if(set[i].valid && set[i].tag == tag) {           //cache hit
                if(write){
                    writes++;
                    set[i].dirty = 'D';
                } else{
                    reads++;
                }
            //update LRU of block 
            updateLRU(set,i);
            return true;
            }
        }

    // Cache miss: Check stream buffers
        for (auto& buffer : prefetch_unit) {
            if (buffer.valid && buffer.access(addr)) {
                // Stream buffer hit: Copy block from stream buffer to cache
                handle_miss(set, addr, tag, write, index);

                // Shift stream buffer and prefetch more blocks
                buffer.shiftAndPrefetchMore(blksize);

                // Update LRU for stream buffers
                updateLRUCounters(&buffer - &prefetch_unit[0]);
                prefetch_reads++;

                // Cache hit after stream buffer copy
                return true;
            }
        }

    //cache miss ? handle the miss
        if (write) {  
            write_misses++;  // Increment write miss counter for write misses
        } else {
            read_misses++;   // Increment read miss counter for read misses
        }

        if(handle_miss(set,addr,tag,write,index)){
            if(write){
                writes++;
            } else {
                reads++;
            }
            } else {
                prefetch_read_misses++;
        }
    //return handle_miss(set,addr,tag,write,index);
        return false;
    } 

//IMPLEMENTING LRU POLICY:
//First find LRU block and then update the block based on that 
    int findLRU(const std::vector<cacheblk>& set){
    int lru_index=0;
    for(int i=1; i<assoc; i++){
        if(set[i].lru_counter > set[lru_index].lru_counter)
        {
            lru_index = i;
        }
    }
    return lru_index;
    }

//After Finding LRU, update the LRU
    void updateLRU(std::vector<cacheblk>& set, int accessed_blk_index){
    for(int i=0;i<assoc;i++){
        if (i != accessed_blk_index){   //First increment all counter values other than the accessed block counter
            set[i].lru_counter++;
        } 
    }
    set[accessed_blk_index].lru_counter = 0; //Now, make the accessed block counter value to zero
    }

//Function for Handling miss
    bool handle_miss(std::vector<cacheblk>& set, uint32_t addr, uint32_t tag, bool write, int index){
    int lru_index = findLRU(set); //Find LRU  
    if(set[lru_index].valid && set[lru_index].dirty=='D'){             //Write-back, if its dirty
        uint32_t victim_block_address =  set[lru_index].tag << (idx_bits+bo_bits) | (index << bo_bits); //Write-back: Victim block address:
        write_backs++;
        if(next){
            next->request(victim_block_address, true); 
        } else {
            memory_traffic++;
        }
    }

    if(next){            
        next->request(addr,false); //Now send read request to next level, if it is there 
    } else{
        memory_traffic++;
    }

    set[lru_index].valid = true;   
    set[lru_index].tag   = tag;
    set[lru_index].dirty = write ? 'D' : ' ';

    updateLRU(set,lru_index); //Update the LRU
    return true; //Miss was hanlded successfully
    }

// Function to find the least recently used stream buffer
    int findLRUBuffer() {
    size_t lru_index = 0;
    for (std::size_t i = 1; i < prefetch_unit.size(); i++) {
        if (prefetch_unit[i].lru_counter > prefetch_unit[lru_index].lru_counter) {
            lru_index = i;
        }
    }
    return static_cast<int>(lru_index);
    }
// Function to update LRU counters for all stream buffers
    void updateLRUCounters(int used_index) {
    for (size_t i = 0; i < prefetch_unit.size(); i++) {
        if (static_cast<int>(i) != used_index) {
            prefetch_unit[i].lru_counter++;  // Increment LRU counters for other buffers
        }
    }
    prefetch_unit[used_index].lru_counter = 0;  // Reset LRU counter for the most recently used buffer
    }

// Print cache information
    void print_cache_info(const std::string& cache_name) {
    if (cache_name == "L2") {  // Only add a blank line before L2 contents, not L1
        cout << endl;  // Add a blank line before printing the L2 contents section
    }
    cout << "===== " << cache_name << " contents =====" << endl;
    for (int i = 0; i < num_sets; i++) {
        bool set_valid = false;
        for (int j = 0; j < assoc; j++) {
            if (total_sets[i][j].valid) {
                set_valid = true;
                break;
            }
        }
        if (!set_valid) continue;  // Skip sets with no valid blocks

        // Sort the blocks in the set by LRU counter before printing
        std::vector<cacheblk> sorted_set = total_sets[i];  // Copy the set
        std::sort(sorted_set.begin(), sorted_set.end(), [](const cacheblk& a, const cacheblk& b) {
            return a.lru_counter < b.lru_counter;  // Sort by LRU counter (ascending)
        });

        cout << "Set      " << dec << i << ":   ";
        for (int j = 0; j < assoc; j++) {
            if (sorted_set[j].valid) {
                cout << hex << sorted_set[j].tag << " "; 
                cout << (sorted_set[j].dirty == 'D' ? 'D' : ' ') << "  ";
            }
        }
        cout << endl;
    }
    }

//Function for Printing tream Buffer Contents
    void print_stream_buffer_contents() {
    cout << "===== Stream Buffer(s) contents =====" << endl;
    for (size_t i = 0; i < prefetch_unit.size(); i++) {
        if (prefetch_unit[i].valid) {
            for (const auto& block : prefetch_unit[i].blocks) {
                    cout << hex << block << " ";
            }
            cout << endl;
        }
    }
    }
};

// Print statistics after the simulation (unchanged)
void print_stats(cache* L1_cache, cache* L2_cache) {
    cout << endl;
    cout << "===== Measurements =====" << endl;
    cout << dec;
    cout << "a. L1 reads:                   " << L1_cache->reads << endl;
    cout << "b. L1 read misses:             " << L1_cache->read_misses << endl;
    cout << "c. L1 writes:                  " << L1_cache->writes << endl;
    cout << "d. L1 write misses:            " << L1_cache->write_misses << endl;
    double L1_miss_rate = (double)(L1_cache->read_misses + L1_cache->write_misses) / (L1_cache->reads + L1_cache->writes);
    cout << "e. L1 miss rate:               " << fixed << setprecision(4) << L1_miss_rate << endl;
    cout << "f. L1 writebacks:              " << L1_cache->write_backs << endl;
    cout << "g. L1 prefetches:              " << L1_cache->prefetches << endl;

    if (L2_cache != nullptr) {
        cout << "h. L2 reads (demand):          " << L2_cache->reads << endl;
        cout << "i. L2 read misses (demand):    " << L2_cache->read_misses << endl;
        cout << "j. L2 reads (prefetch):        " << L2_cache->prefetch_reads << endl;
        cout << "k. L2 read misses (prefetch):  " << L2_cache->prefetch_read_misses << endl;
        cout << "l. L2 writes:                  " << L2_cache->writes << endl;
        cout << "m. L2 write misses:            " << L2_cache->write_misses << endl;
        double L2_miss_rate = (double)L2_cache->read_misses / L2_cache->reads;
        cout << "n. L2 miss rate:               " << fixed << setprecision(4) << L2_miss_rate << endl;
        cout << "o. L2 writebacks:              " << L2_cache->write_backs << endl;
        cout << "p. L2 prefetches:              " << L2_cache->prefetches << endl;
        cout << "q. memory traffic:             " << L1_cache->memory_traffic + L2_cache->memory_traffic << endl;
    } else {
        cout << "h. L2 reads (demand):          " << 0 << endl;
        cout << "i. L2 read misses (demand):    " << 0 << endl;
        cout << "j. L2 reads (prefetch):        " << 0 << endl;
        cout << "k. L2 read misses (prefetch):  " << 0 << endl;
        cout << "l. L2 writes:                  " << 0 << endl;
        cout << "m. L2 write misses:            " << 0 << endl;
        cout << "n. L2 miss rate:               " << 0.0000 << endl;
        cout << "o. L2 writebacks:              " << 0 << endl;
        cout << "p. L2 prefetches:              " << 0 << endl;
        cout << "q. memory traffic:             " << L1_cache->memory_traffic << endl;
    }
}



int main (int argc, char *argv[]) {
   FILE *fp;			// File pointer.
   char *trace_file;		// This variable holds the trace file name.
   cache_params_t params;	// Look at the sim.h header file for the definition of struct cache_params_t.
   char rw;			// This variable holds the request's type (read or write) obtained from the trace.
   uint32_t addr;		// This variable holds the request's address obtained from the trace.
				// The header file <inttypes.h> above defines signed and unsigned integers of various sizes in a machine-agnostic way.  "uint32_t" is an unsigned integer of 32 bits.

   // Exit with an error if the number of command-line arguments is incorrect.
   if (argc != 9) {
      printf("Error: Expected 8 command-line arguments but was provided %d.\n", (argc - 1));
      exit(EXIT_FAILURE);
   }
    
   // "atoi()" (included by <stdlib.h>) converts a string (char *) to an integer (int).
   params.BLOCKSIZE = (uint32_t) atoi(argv[1]);
   params.L1_SIZE   = (uint32_t) atoi(argv[2]);
   params.L1_ASSOC  = (uint32_t) atoi(argv[3]);
   params.L2_SIZE   = (uint32_t) atoi(argv[4]);
   params.L2_ASSOC  = (uint32_t) atoi(argv[5]);
   params.PREF_N    = (uint32_t) atoi(argv[6]);
   params.PREF_M    = (uint32_t) atoi(argv[7]);
   trace_file       = argv[8];

   
   
   // Debugging output for configuration print
   //cout << "*****Starting configuration print******" << endl;
   // Print simulator configuration.
   cout << "===== Simulator configuration ====="<< endl;
   cout << "BLOCKSIZE:  " << params.BLOCKSIZE << endl;
   cout << "L1_SIZE:    " << params.L1_SIZE   << endl;
   cout << "L1_ASSOC:   " << params.L1_ASSOC  << endl;
   cout << "L2_SIZE:    " << params.L2_SIZE   << endl;
   cout << "L2_ASSOC:   " << params.L2_ASSOC  << endl;
   cout << "PREF_N:     " << params.PREF_N    << endl;
   cout << "PREF_M:     " << params.PREF_M    << endl;
   cout << "trace_file: " << trace_file       << endl;
   cout << " " << endl;


   // Open the trace file for reading.
   fp = fopen(trace_file, "r");
   if (fp == (FILE *) NULL) {
      // Exit with an error if file open failed.
      printf("Error: Unable to open file %s\n", trace_file);
      exit(EXIT_FAILURE);
   }

    cache L1_cache(params.L1_SIZE, params.L1_ASSOC, params.BLOCKSIZE, params.PREF_N, params.PREF_M);
    cache* L2_cache = nullptr;
    if(params.L2_SIZE > 0){
      L2_cache = new cache(params.L2_SIZE, params.L2_ASSOC, params.BLOCKSIZE, params.PREF_N, params.PREF_M);
      L1_cache.next = L2_cache; //Linking L1 to L2
    }
    
    

   // Read requests from the trace file and echo them back.
    while (fscanf(fp, "%c %x\n", &rw, &addr) == 2) {	// Stay in the loop if fscanf() successfully parsed two tokens as specified.
      if (rw == 'r') {
         // printf("r %x\n", addr);
          L1_cache.request(addr, false);
      } else if (rw == 'w'){
          //printf("w %x\n", addr);
          L1_cache.request(addr, true);
      } else {
          printf("Error: Unknown request type %c.\n", rw);
	       exit(EXIT_FAILURE);
      }

}

    // Print cache contents and statistics
    L1_cache.print_cache_info("L1");
    if (L2_cache != nullptr) {
        L2_cache->print_cache_info("L2");
    }
   //  L1_cache.print_stats();
   //  if (L2_cache != nullptr) {
   //     L2_cache->print_stats();
   //     delete L2_cache;  // Clean up 
   // }
   //    L1_cache.print_stream_buffer_contents();
   //     if (L2_cache != nullptr) {
   //         L2_cache->print_stream_buffer_contents();
   //     }
    
    print_stats(&L1_cache, L2_cache);
    
     //print_stats();
    fclose(fp);
    return(0);
}
