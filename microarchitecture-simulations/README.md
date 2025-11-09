# Microarchitecture Simulations – Single-Core CPU Design

This repository hosts a collection of **C++ simulators** developed as part of **ECE 563 – Microprocessor Architecture (Prof. Eric Rotenberg, North Carolina State University)**.  
Each project models a fundamental aspect of **single-core CPU microarchitecture**, exploring key design and performance trade-offs that shape modern superscalar processors.

Together, these simulators progressively build an understanding of how processors exploit **instruction-level parallelism (ILP)** through cache efficiency, branch prediction, and dynamic scheduling.

---

## 🧩 Projects Overview

| Project | Description | Key Concepts |
|----------|--------------|---------------|
| [**Cache Hierarchy Simulator**](./cache-hierarchy-sim) | Models a two-level cache with configurable size, associativity, and block size. Evaluates hit/miss rates and average access time. | Cache organization, locality, AAT, CACTI analysis |
| [**Branch Predictor Simulator**](./branch-predictor-sim) | Implements **Bimodal**, **Gshare**, and **Hybrid** branch predictors for analyzing control flow accuracy. | Global/local correlation, chooser tables, prediction accuracy |
| [**Out-of-Order Superscalar Processor Simulator**](./out-of-order-superscalar-sim) | Simulates a **Tomasulo-based** OOO pipeline with register renaming, dynamic scheduling, and in-order retirement. | Reorder Buffer (ROB), Issue Queue (IQ), Rename Map Table (RMT), ILP |

---

## 🧠 Architectural Context

Each simulator represents one layer of a single-core CPU’s execution model:

<p align="center">
  <img src="./assets/core-flow.png" width="750"><br>
  <em>Figure – Conceptual flow of the single-core architecture simulated across projects.</em>
</p>

- The **Cache Simulator** models memory hierarchy behavior and latency.
- The **Branch Predictor** models control speculation for better instruction flow.
- The **Out-of-Order Processor** models dynamic scheduling and register renaming.

Combined, they form a modular exploration of **core-level microarchitecture** — from memory and control subsystems to pipeline execution and retirement.

---

## 🧰 Tools and Environment

All simulators were developed and validated in a consistent academic environment:

| Category | Details |
|-----------|----------|
| **Language** | C++ (C++11) |
| **Platform** | Linux / ETX Cluster |
| **Build System** | Makefile |
| **Validation** | Gradescope Autograder |
| **Benchmarks / Traces** | SPEC 2006 / 2017, gcc, perl, jpeg, and custom microbenchmarks |
| **Analysis Tools** | CACTI (for cache energy/area), Python & Excel (for performance graphs) |

---

## 📚 References

- **ECE 563 – Microprocessor Architecture**, North Carolina State University  
- N. Jouppi, “*Improving Direct-Mapped Cache Performance by the Addition of a Small Fully Associative Cache and Prefetch Buffers*,” *ISCA 1990*  
- John L. Hennessy & David A. Patterson, *Computer Architecture: A Quantitative Approach*  
- CACTI Tool Documentation – HP Labs  

---

## 👤 Author

**Vishnuvardhan Chilukoti**  
*MS in Computer Engineering, North Carolina State University*  
📧 **vchiluk3@gmail.com**

> Part of *The Logic Artisan* — crafting precision in silicon.
