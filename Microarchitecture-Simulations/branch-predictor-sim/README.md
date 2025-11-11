# Branch Predictor Simulator – Bimodal, Gshare & Hybrid
This repository documents my implementation of a **dynamic branch prediction simulator** written in **C++**, developed as part of **ECE 563 – Microprocessor Architecture (Prof. Eric Rotenberg, North Carolina State University)**.  

The simulator models and compares three key dynamic branch predictors (**Bimodal**, **Gshare**, and **Hybrid**) to analyze control flow accuracy, prediction efficiency, and design trade-offs in a single-core CPU pipeline.

## Overview
Modern processors rely on branch prediction to maintain instruction-level parallelism and minimize pipeline stalls. This simulator provides an architectural exploration framework to study:

- **Predictor types:** Bimodal, Gshare, Hybrid  
- **Configurable parameters:** table size (`m`), global history (`n`), chooser bits (`k`)  
- **Metrics:** total predictions, mispredictions, and misprediction rate (%)  
- **Traces:** real benchmark traces (`gcc`, `jpeg`, `perl`)  
- **Validation:** verified using **Gradescope autograder** reference outputs  

## Repository Structure
```bash
branch-predictor-sim/
├── src/                    # C++ sources: bimodal, gshare, hybrid, simulator main
├── traces/                 # Input benchmark traces (gcc, jpeg, perl)
├── ref_validation_runs/    # Sample Gradescope validation outputs
├── report/
│   └── report.pdf          # Detailed project report with graphs & discussion
├── Makefile                # Builds simulator → ./sim
└── README.md
```

# Architecture
<p align="center"><em>Figure 1 – Bimodal, Gshare, and Hybrid Predictor Architecture</em></p>

```bash
                   +-------------------+
                   |     PC bits       |
                   +-------------------+
                              |
          +-------------------+-------------------+
          |                                       |
  +---------------+                       +---------------+
  |   Bimodal     |                       |    Gshare     |
  |  Table (2^M2) |                       |  Table (2^M1) |
  +---------------+                       +---------------+
          |                                       |
          +-------------------+-------------------+
                              |
                      +---------------+
                      |   Chooser     |
                      |   Table (2^K) |
                      +---------------+
                              |
                        Final Prediction
```

### 1. Bimodal Predictor
- Indexed by low-order *m* bits of the PC (excluding 2 LSBs).  
- Each entry = 2-bit saturating counter (initialized to 2).  
- **Prediction:** counter ≥ 2 → taken; else not-taken.  
- **Update:** increment on taken, decrement on not-taken (saturating 0–3).

### 2. Gshare Predictor
- Combines global branch history (`n` bits) with the PC index.  
- **Index = PC[n bits] ⊕ GHR**.  
- Global History Register (GHR) shifts each cycle.
- Improves accuracy for correlated branches.

### 3. Hybrid Predictor 
- Merges bimodal and gshare using a 2-bit **chooser table** (size 2ᵏ).
- **Chooser ≥ 2 → select Gshare; else select Bimodal**.  
- Initialization: all chooser counters start at 1 (weakly favoring Bimodal).
- Only the selected predictor updates its table.  
- Chooser is trained based on which predictor was correct.

## Compilation
You can compile the simulator using the provided Makefile or manually.

### Using Makefile
```bash 
make
```
This compiles `src/sim_bp.cc` and produces an executable named `sim`.

To clean build files:
```bash
make clean
```

### Manual compilation
```bash
g++ -std=c++11 -O3 src/sim_bp.cc -o sim -lm
```

## Running the Simulator
### Bimodal
```bash 
./sim bimodal <M2> <tracefile>
```

### Gshare
```bash 
./sim gshare <M1> <N> <tracefile>
```

### Hybrid
```bash 
./sim hybrid <K> <M1> <N> <M2> <tracefile>
```
| Argument    | Description                         |
| ----------- | ----------------------------------- |
| `M1`        | # of PC bits for Gshare table       |
| `M2`        | # of PC bits for Bimodal table      |
| `N`         | # of Global History bits            |
| `K`         | # of Chooser table index bits       |
| `tracefile` | Input trace (e.g., `gcc_trace.txt`) |

## Trace Format
Each line in the trace represents a branch and its actual outcome:
```bash
<hex PC> t|n
```

Example:
```bash
00a3b5fc t
00a3b604 t
00a3b60c n
```

## Output Statistics
Simulator output (follows Gradescope format):
```bash
COMMAND
number of predictions: XXXXXXX
number of mispredictions: XXXX
misprediction rate: XX.XX%
FINAL CONTENTS OF BIMODAL TABLE:
[index] [value]
FINAL CONTENTS OF GSHARE TABLE:
[index] [value]
FINAL CONTENTS OF CHOOSER TABLE:
[index] [value]
```

## Experimental Evaluation
### Bimodal Predictor Analysis
- Simulated 7 ≤ m ≤ 20 on `gcc`, `jpeg`, `perl`.
- Misprediction rate drops with larger tables and stabilizes beyond m≈18

| Benchmark | Best m | Lowest Rate |
| :-------- | :----- | :---------- |
| gcc       | 18     | 11.17 %     |
| jpeg      | 13     | 7.59 %      |
| perl      | 14     | 8.82 %      |

> Table growth beyond m≈18 yields diminishing returns and each branch gets its own counter.

### Gshare Predictor Analysis
- Explored 7 ≤ m ≤ 20 and 0 ≤ n ≤ m on `gcc`.
- Optimal balance at m = 20, n = 11 yields 6.37 % misprediction.
- Baseline (bimodal n = 0) ≈ 11.17 %.

> History helps when table is large and hurts when table is small.

### Hybrid Predictor Analysis
- Combines bimodal and gshare via chooser training.
- Adapts to different branch behaviors in a single trace.
- Consistently outperforms both predictors individually.
- Validated on Gradescope val_hybrid and mystery traces.

## Summary
| Predictor | Key Strength              | Typical Improvement         |
| :-------- | :------------------------ | :-------------------------- |
| Bimodal   | Simple and fast           | Baseline accuracy           |
| Gshare    | Correlates global history | ≈ 40 % fewer mispredictions |
| Hybrid    | Adaptive selection        | Best overall accuracy       |

> Dynamic hybrid selection reduces mispredictions by ≈ 45 % over bimodal baseline on `gcc`.

## Full Report
[View Full Report (PDF)](./report/report.pdf)

---
**Tools and Environment:**  
C++ (C++11), Linux / ETX Cluster, Makefile, Gradescope Autograder  
Benchmarks: gcc, jpeg, perl  
Analysis: Python & Excel for graphs  

**Author:** Vishnuvardhan Chilukoti  


