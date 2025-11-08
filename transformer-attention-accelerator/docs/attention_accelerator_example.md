# Example: Why This Design Matters in Real SoCs

Let’s understand the motivation behind this design with a simple example.

---

## 🧠 The Attention Problem

Imagine you’re reading a sentence:
> “The cat sat on the mat because it was tired.”

When the Transformer processes the word “it”, it must decide whether “it” refers to the **cat** or the **mat**.  
To do this, it calculates how strongly “it” relates to every other word — that’s the **attention mechanism**.

It builds three key matrices:
- **Q (Query):** Represents the current word (“it”)
- **K (Key):** Represents all other words
- **V (Value):** Contains the meaning of each word

![Query and Key generation](../docs/query_key_generation.png)

Then it computes:
> **S = Q × Kᵀ** → attention scores  
> **Z = softmax(S) × V** → weighted output

![Score matrix multiplication](../docs/score_matrix_multiplication.png)

---

## ⚙️ The Problem on CPUs and GPUs

For a sentence with 512 tokens:
- Q, K, V are 512×512 matrices  
- That’s over **134 million multiplications** just to find attention scores  
- And Transformers repeat this across **dozens of layers**

CPUs and GPUs can compute this but waste energy moving data between memory and compute units — fine for data centers, not for **real-time or on-device AI**.

---

## ⚡ What the Hardware Accelerator Does Better

Your design focuses **only on this math** — nothing else.  
It uses:
1. A **15-state FSM** to control every operation precisely  
2. **Local SRAMs** for Input, Weight, Result, and Scratchpad data  
3. A **Multiply-Accumulate unit** that runs continuously  
4. Smart **transposed memory storage** for efficient V access during `Z = S×V`

💡 **Result:**  
- No wasted cycles  
- No cache misses  
- Lower energy per operation  
- Deterministic latency

---

## 🧩 In a Real SoC

Inside a modern SoC (e.g., Qualcomm Snapdragon or Apple M-series):
- The **CPU** sends data to your accelerator  
- Your block performs the Q, K, V, S, Z computations  
- Results go back to system memory or the next AI pipeline stage  
- The **NPU or AI engine** repeats this across multiple attention heads and layers

This accelerator becomes a **building block** for Transformer-based workloads:
- Speech recognition  
- On-device translation  
- Vision Transformers (object detection)  
- LLM inference acceleration  

---

## 🔚 Summary

Transformers are huge relational calculators.  
Your design builds a **small, specialized calculator** that performs just the attention math — perfectly, efficiently, and at hardware speed.  
That’s why such accelerators are becoming a key part of **modern AI SoCs**.
