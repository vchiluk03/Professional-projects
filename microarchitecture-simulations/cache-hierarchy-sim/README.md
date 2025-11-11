# Cache and Memory Hierarchy Simulator - L1/L2 with Stream Buffer Prefetching
This repository documents my implementation of a **configurable cache and memory hierarchy simulator** written in **C++**, developed as part of **ECE 563 - Microprocessor Architecture (Prof. Eric Rotenberg, NC State University)**.  

The project models realistic **two-level cache hierarchies** (L1 and L2) and integrates a **Stream-Buffer-based Prefetcher** to explore performance, area, and energy trade-offs.

## Overview
Modern processors depend on multi-level cache hierarchies to bridge the performance gap between CPU and main memory. This simulator emulates that hierarchy, allowing configurable exploration of:
- **Cache parameters:** size, associativity, block size  
- **Policies:** Write-Back + Write-Allocate (WBWA), LRU replacement  
- **Prefetching:** Stream Buffer Prefetcher (N buffers × M blocks)  
- **Metrics:** miss rates, writebacks, prefetches, total memory traffic, and AAT (Average Access Time)

All configurations and results were validated using **Gradescope autograder outputs** and benchmark traces (`gcc_trace.txt`, `stream_trace.txt`).

## Repository Structure
```bash
cache-hierarchy-sim/
├── src/                    # C++ source: cache, hierarchy, stream buffer
├── traces/                 # Memory access traces (SPEC / microbenchmarks)
├── report/
│   └── report.pdf          # Full project report with graphs and answers
├── ref_validation_runs/    # Sample Gradescope validation outputs
├── Makefile                # Builds simulator → ./sim
└── README.md
```

## Architecture
<p align="center">
  <img src="./assets/architecture-diagram.png" width="600"><br>
  <em>Figure 1: Cache and Memory Hierarchy Overview</em>
</p>

### Cache Module (`CACHE`)
A generic cache model that can be used as L1, L2, or any other level:
- Parameterized by `SIZE`, `ASSOC`, and `BLOCKSIZE`
- Implements **LRU** replacement and **Write-Back + Write-Allocate (WBWA)** policy
- Handles reads, writes, dirty evictions, and block allocations to the next level 

### Stream Buffer Prefetcher
Integrated within the cache. Each Stream Buffer holds `M` consecutive blocks and prefetches new blocks on misses.
| Symbol | Meaning |
|---------|----------|
| `N` | Number of stream buffers |
| `M` | Blocks per buffer |
| **Policy** | LRU selection among buffers |
| **Action** | On miss: prefetch X+1 to X+M ; on hit: shift and continue stream |

This reduces Average Access Time (AAT) by overlapping future memory fetches.

## Compilation
You can compile the simulator using the provided Makefile or manually.

### Using Makefile (recommended)
```bash 
make
```
This compiles `src/sim.cc` and produces an executable named `sim`.

To clean build files:
```bash
make clean
```

### Manual compilation
```bash
g++ -std=c++11 -O3 src/sim.cc -o sim -lm
```

## Running the Simulator
Run the simulator with:
```bash 
./sim <BLOCKSIZE> <L1_SIZE> <L1_ASSOC> <L2_SIZE> <L2_ASSOC> <PREF_N> <PREF_M> <trace_file>
```
Example:
```bash
./sim 32 8192 4 262144 8 3 10 traces/gcc_trace.txt
```

| Argument | Description |
|-----------|-------------|
| `BLOCKSIZE` | Bytes per block (power of 2) |
| `L1_SIZE`, `L1_ASSOC` | L1 cache size and associativity |
| `L2_SIZE`, `L2_ASSOC` | L2 cache size and associativity (0 = disabled) |
| `PREF_N`, `PREF_M` | Stream buffer count and depth (0 0 = disabled) |
| `trace_file` | Input memory trace file |

## Trace Format
Each line in the trace represents a memory access:
```bash
r|w <hex_address>
```

Example:
```bash
r ffe04540
w 0eff2340
r ffe04548
```

## Output Statistics
The simulator prints results following Gradescope’s format:
| Metric | Description |
|---------|-------------|
| L1 reads / L1 writes | Total accesses |
| L1 miss rate (MRL1) | Read + write misses / total |
| L2 miss rate (MRL2) | Miss rate from CPU’s perspective |
| Writebacks | Dirty block evictions |
| Prefetch requests | Stream-buffer generated requests |
| Total memory traffic | Total blocks transferred to/from memory |
| AAT | Average Access Time (ns) |


## Performance Equations
*Note:* Hit times and energy numbers are obtained from **CACTI 7.0** simulations for various cache configurations.
### Average Access Time (AAT)
**AAT = HT<sub>L1</sub> + MR<sub>L1</sub> × (HT<sub>L2</sub> + MR<sub>L2</sub> × MP)**
where  
- **HT** – Hit Time (from CACTI)  
- **MR** – Miss Rate (from simulator)  
- **MP** – Miss Penalty (main memory latency)

### Area & Energy (CACTI-based)
The CACTI tool provides:
- Access time (ns)
- Area (mm²)
- Energy per access (nJ)

These values are used to estimate overall performance, area, and energy.

## Experimental Evaluation
A set of experiments were conducted to explore cache design trade-offs:
1. **L1 Cache Exploration — Size vs. Associativity**
   Analyzed how cache capacity and associativity affect miss rate and AAT.
2. **L1 + L2 Hierarchy**
   Compared performance of two-level hierarchies versus L1-only systems.
3. **Block Size Study**
   Demonstrated trade-offs between spatial locality and cache pollution.
4. **Stream Buffer Prefetching (ECE 563 Extension)**
   Implemented configurable `(PREF_N, PREF_M)` stream buffers and evaluated their impact on sequential traces.

## Summary
- Moderate associativity (4-way) provides optimal performance-to-area ratio.
- Adding an L2 cache significantly lowers AAT compared to single-level hierarchies.
- Small caches favor smaller blocks; large caches benefit from spatial locality.
- Stream Buffer Prefetching improves miss rate and AAT for sequential patterns (~10–15% latency reduction).

Detailed numerical results and plots are available in the project report.

## Full Report
[View Full Report (PDF)](./report/report.pdf)

---
**Tools and Environment:**  
C++ (C++11), Linux / ETX Cluster, Makefile, Gradescope Autograder  
Traces: SPEC 2006 / 2017, custom microbenchmarks  
Analysis: CACTI tool for area and energy estimation

**Author:** Vishnuvardhan Chilukoti 

