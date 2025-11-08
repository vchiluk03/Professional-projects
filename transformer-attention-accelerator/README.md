# Transformer Scaled Dot-Product Attention Accelerator (ASIC Design)

This project presents the **design and synthesis of a Scaled Dot-Product Attention Accelerator**, the mathematical heart of the Transformer architecture used in modern NLP and AI systems.  
Developed as part of **ECE 564 – ASIC Design and Synthesis** at **North Carolina State University**, this design realizes the full attention pipeline in **Verilog/SystemVerilog** with a 15-state FSM, four SRAMs, and a pipelined multiply-accumulate datapath.

---

## 📂 Repository Structure
```bash
transformer-attention-accelerator/
├── rtl/                 # Synthesizable Verilog RTL (MyDesign.sv)
├── testbench/           # SystemVerilog testbench, SRAM models
├── run/                 # Makefile, waveform setup, logs
├── synthesis/           # DC synthesis scripts and reports
├── inputs/              # Positive testcases
├── negative_inputs/     # Negative testcases
├── docs/                # Figures and example explanation
│   └── attention_accelerator_example.md   # Linked example document
└── README.md
```

---

## 🎯 Objective
Design and synthesize a **dedicated ASIC accelerator** implementing the **Scaled Dot-Product Attention** mechanism.  
The goal is to translate software matrix operations into a **deterministic, area-efficient FSM** capable of:
- Computing Q, K, V matrices  
- Forming the Score matrix **S = Q × Kᵀ**  
- Producing the final Attention output **Z = S × V**

---

## 📘 System Overview

**Attention(Q, K, V) = softmax((Q × Kᵀ) / √dₖ) × V**

<p align="center">
  <img src="docs/attention_block_diagram.png" width="700"/>
</p>
<p align="center"><b>Figure 1 – Transformer Attention dataflow: Q, K, V → Score (QKᵀ) → Output (SV).</b></p>

**Key operations implemented**
1. **Q, K, V formation**  
&nbsp;&nbsp;&nbsp;&nbsp;• Q = I × Wq  
&nbsp;&nbsp;&nbsp;&nbsp;• K = I × Wk  
&nbsp;&nbsp;&nbsp;&nbsp;• V = I × Wv  
2. **Score matrix**: S = Q × Kᵀ  
3. **Final output**: Z = S × V

---

## 🚀 Motivation — Why Dedicated Hardware?

Transformer models have changed how modern AI understands language, speech, and vision. They allow computers to process entire sentences or images all at once, rather than step by step like older RNNs.  
At the center of every Transformer is the **attention mechanism**, which decides how much “focus” to give to each word or token when generating meaning. But this process involves thousands of matrix multiplications — heavy mathematical operations that must run again and again for every layer of the model.  

Running these computations on general-purpose CPUs or GPUs is fast, but still consumes a lot of energy and memory bandwidth. For small embedded devices or real-time applications (like voice assistants, translation chips, or on-device generative AI), that level of compute is inefficient and too slow.  

This project was designed to solve that problem. It builds a **dedicated hardware accelerator** — a focused piece of logic that performs the attention math directly in silicon. Instead of relying on large processors, this accelerator performs  
**Attention(Q, K, V) = softmax((Q × Kᵀ) / √dk) × V**  
using a tightly controlled FSM and local SRAMs. The result is a faster, energy-efficient, and predictable hardware unit that can be integrated into a real SoC to power Transformer-based workloads.

➡️ **Want to see an intuitive real-world example?**  
Check out the [Example: Why This Design Matters in Real SoCs](docs/attention_accelerator_example.md).

---

## 🧩 Where It Fits Inside a Real SoC

<p align="center">
  <img src="docs/soc_integration_overview.png" width="780"/>
</p>
<p align="center"><b>Figure 2 – Typical SoC placement: Attention Accelerator IP inside an NPU/AI subsystem.</b></p>

In a full System-on-Chip (SoC), this accelerator would be part of the **AI or NPU subsystem**.  
The host CPU sends control signals through a memory-mapped interface (AXI or Wishbone) and loads the input/weight matrices into on-chip SRAM. Once computation begins, the accelerator handles all the Q, K, V, S, and Z computations internally.  
When done, it signals completion to the CPU (using `dut_ready` or an interrupt).  

This type of block is typically used in:
- **Edge AI processors** – smartphones, IoT, automotive SoCs  
- **Neural Processing Units (NPUs)** – to accelerate Transformer layers  
- **Vision Transformers (ViT)** – where spatial attention replaces convolution  
- **Speech and NLP chips** – for real-time attention inference  

---

## 🧠 Control and FSM Operation

The design is orchestrated by a **15-state FSM** managing all compute and memory phases.

**FSM sequence**
```
IDLE → READ_DIMENSIONS → Q/K/V MULTIPLY + WRITE
→ SCORE_MATRIX → WRITE_SCORE_RESULT
→ ATTENTION_MATRIX → WRITE_ATTENTION_MATRIX → COMPLETE
```

Each state controls:
- SRAM read/write enables and addresses  
- Row/column counters and element iterators  
- `multiply_accum` for MAC operations  
- `dut_ready` / `dut_valid` handshake

---

## 🔁 Handshake Protocol

<p align="center">
  <img src="docs/dut_handshake_timing.png" width="700"/>
</p>
<p align="center"><b>Figure 3 – DUT ↔ Testbench handshake timing for <code>dut_valid</code> / <code>dut_ready</code>.</b></p>

| Signal | Direction | Description |
|:--|:--|:--|
| `clk` | In | System clock |
| `reset_n` | In | Active-low reset |
| `dut_valid` | In | Valid input window |
| `dut_ready` | Out | High = ready or completed |
| `dut__tb__sram_*` | In/Out | 4× SRAM interfaces (Input, Weight, Result, Scratchpad) |

**Protocol behavior**  
1️⃣ After reset: `dut_ready = 1` (IDLE)  
2️⃣ Testbench asserts `dut_valid` → FSM starts; `dut_ready = 0`  
3️⃣ On completion: `dut_ready = 1` again

---

## 💾 SRAM Architecture & Timing

<p align="center">
  <img src="docs/sram_interface_ports.png" width="700"/>
</p>
<p align="center"><b>Figure 4 – Four SRAM interfaces mapped to Input, Weight, Result, Scratchpad.</b></p>

- **Input SRAM**: Stores input embeddings (I) + dimensions  
- **Weight SRAM**: Stores Wq, Wk, Wv tiles  
- **Result SRAM**: Holds Q, K, V, S, Z matrices sequentially  
- **Scratchpad SRAM**: Holds **Kᵀ** and **transposed V** for reuse  

<p align="center">
  <img src="docs/sram_timing_diagram.png" width="780"/>
</p>
<p align="center"><b>Figure 5 – One-cycle read latency and safe scheduling to avoid RAW hazards.</b></p>

**Timing rules enforced by FSM**
- Read data appears **one cycle** after address  
- Writes take effect on the **next cycle**  
- No immediate **read-after-write to the same address**  
- Read/write phases separated to guarantee correctness

---

## ⚙️ RTL Highlights (MyDesign.sv)

- **MAC pipeline**: `multiply_accum` accumulates partial products per output element  
- **Transposed V optimization**: store V column-major in scratchpad for fast **Z = S × V**  
- **SystemVerilog features**: `typedef enum logic [3:0]` states, `logic` typing for clean synthesis  
- **Handshake**: `dut_valid` to start; `dut_ready` asserted when all outputs are committed to SRAM

**Representative snippet**
```verilog
always @(posedge clk or negedge reset_n) begin
  if (!reset_n)
    current_state <= IDLE;
  else
    current_state <= next_state;
end
```

---

## 🔌 Interface Summary

| Signal | Dir | Width | Description |
|:--|:--|:--|:--|
| `reset_n` | In | 1 | Active-low reset |
| `clk` | In | 1 | System clock |
| `dut_valid` | In | 1 | Input is valid / start |
| `dut_ready` | Out | 1 | Completion / ready for next |
| `dut__tb__sram_input_*` | In/Out | 32 | Input SRAM |
| `dut__tb__sram_weight_*` | In/Out | 32 | Weight SRAM |
| `dut__tb__sram_result_*` | In/Out | 32 | Result SRAM |
| `dut__tb__sram_scratchpad_*` | In/Out | 32 | Scratchpad SRAM |

---

## 📊 Synthesis Results (45 nm Library)

| Metric | Value | Units | Notes |
|:--|:--|:--|:--|
| Logic Area | 12,508.9161 | µm² | Post-synthesis |
| Clock Period | 10 | ns | Achieved target |
| Total Cycles | 3,432 | cycles | Full attention pass |
| Total Latency | 34,320 | ns | 10 ns × 3,432 |
| Efficiency | 2.329 × 10⁻⁹ | ns⁻¹·µm⁻² | 1 / (Delay × Area) |

---

## 🧪 Verification Summary

- **Simulator**: ModelSim (QuestaSim)  
- **Testcases**: Positive (`inputs/`) and Negative (`negative_inputs/`)  
- **Coverage**: All 15 FSM states hit  
- **Golden reference**: Software model compares for Q, K, V, S, Z  
- **Timing**: SRAM latency & RAW rules validated in waves

---

## 🧰 Build & Run

```bash
# Build and simulate
cd run
make build
make eval

# Negative tests
make eval INPUT_DIR=../negative_inputs

# Debug with GUI
make debug

# Cleanup
make clean

# Optional synthesis (45 nm)
cd ../synthesis
make all CLOCK_PER=10
```

---

## 📈 Results Summary

| Parameter | Value |
|:--|:--|
| Technology | 45 nm Synopsys Library |
| Clock Period | 10 ns |
| Latency | 34,320 ns |
| Logic Area | 12,508.9 µm² |
| FSM States | 15 |
| Functional Status | ✅ All testcases passed |

---

## 🧩 Conclusion
The **Transformer Scaled Dot-Product Attention Accelerator** implements Q/K/V, Score, and Output stages entirely in hardware with deterministic timing.  
By colocating compute with scratchpad SRAM and reusing **Kᵀ** and **Vᵀ**, it achieves high throughput and energy efficiency — a practical building block for **NPU/AI subsystems** in modern SoCs.

---

## 📚 References
- *ECE 564 – ASIC Design and Synthesis*, North Carolina State University  
- Vaswani et al., “*Attention Is All You Need*,” NeurIPS 2017  
- *Synopsys Design Compiler User Guide*  
- *45 nm Standard Cell Library Documentation*

---

**Author:** Vishnuvardhan Chilukoti  
**Course:** ECE 564 – ASIC Design and Synthesis, North Carolina State University  
📫 **Contact:** [vchiluk3@gmail.com](mailto:vchiluk3@gmail.com)
