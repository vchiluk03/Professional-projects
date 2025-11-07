# Interrupt Controller - Design and Verification
This repository documents my design and verification of a programmable Interrupt Controller in Verilog HDL. It manages multiple interrupt requests from peripherals, prioritizes them at runtime, and forwards the highest-priority interrupt to the CPU. 

I built this project to strengthen my understanding of hardware interrupt handling, priority arbitration, and bus-based configuration. I built this project independently as part of my ongoing learning in RTL design and verification.

## What Is an Interrupt Controller?
An Interrupt Controller is a hardware block that receives interrupt signals from different peripherals (like UARTs, timers, or GPIOs) and decides which one should reach the CPU first.

Instead of the CPU constantly polling each device, interrupts allow it to focus on other work until a peripheral actually requires service.
When multiple interrupts occur simultaneously, the controller resolves them using priority information, ensuring that critical events (like timers or DMA completions) are serviced before lower-priority ones.

In real-world SoCs, interrupt controllers are essential for balancing system responsiveness and efficiency. Modern designs like ARM GIC, RISC-V PLIC, and x86 APIC follow the same core principle, just on a much larger scale.

## Design Overview
### Module: intp_ctrl_top.v
The controller accepts interrupt requests from several peripherals and outputs the ID of the one with the highest priority.
Priorities are programmable at runtime through an APB-like interface.
| **Parameter** | **Description** |
|----------------|-----------------|
| `NUM_OF_PERIPHERALS` | Number of interrupt sources |
| `ADDR_WIDTH` | Address width for configuration access |
| `DATA_WIDTH` | Priority register width |

### Key Design Features
- Priority-based arbitration among multiple interrupt sources
- FSM-driven control for request → service → clear sequence
- Configurable number of peripherals
- Runtime test selection using `$value$plusargs("test_name=%s", test_name);`
- APB-style register interface for configuration

## Internal Architecture
### FSM States
| **State** | **Description** |
|------------|----------------|
| **IDLE** | Waits for interrupt requests. |
| **GOT_INTP_AND_SEND_TO_PROC** | Finds and forwards the highest-priority interrupt to the CPU. |
| **WAITING_FOR_INTP_TO_BE_SERVICED** | Waits for CPU acknowledgment before accepting new interrupts. |

### Priority Register Bank
Each peripheral has a register (`priority_regA[i]`) that holds its priority level.
These registers are written or read through an **APB-like interface**.

### About the “APB-like” Interface
This interface borrows APB signal naming (`paddr_i`, `pwrite_i`, `penable_i`, `pready_o`, etc.) for familiarity, but it is a simplified version and does not fully implement the APB SETUP/ACCESS phase protocol.

| **APB Spec** | **This Design** |
|---------------|----------------|
| `PSEL` phase | Not used |
| Setup + Access | Combined in one enable phase |
| `PREADY` | Asserted when `penable_i` is high |
| `PSLVERR` | Modeled as `perror_o` (unused) |

It’s **APB-style** in structure, but functionally a simple register access interface for learning and simulation.

## Verification Environment
**Testbench:** `intp_ctrl_tb.v`  
**Task File:** `tasks.v`

The verification setup uses a **task-based Verilog testbench** that drives stimuli, configures registers, and observes controller behavior.  
Each test scenario is selected dynamically through runtime plusargs, allowing quick re-simulation without recompilation.

### Components
- Clock and reset generation
- APB-like register driver
- Random and directed interrupt generation
- Interrupt servicing logic

### Testcases
| **Test Name** | **Description** |
|----------------|-----------------|
| `LOWEST_PERP_CTRL_w/HIGHEST_PRIORITY` | Lowest-index peripherals get highest priority. |
| `LOWEST_PERP_CTRL_w/LOWEST_PRIORITY` | Lowest-index peripherals get lowest priority. |
| `PERP_CTRL_RANDOM_PRIORITY` | Each peripheral gets a unique random priority using `$urandom_range`. |

## Simulation Flow
``` bash 
# Compilation
vlog rtl/intp_ctrl_top.v
vlog tb/intp_ctrl_tb.v

# Simulation
vsim -novopt -suppress 12110 intp_ctrl_tb +test_name=LOWEST_PERP_CTRL_w/HIGHEST_PRIORITY
vsim -novopt -suppress 12110 intp_ctrl_tb +test_name=LOWEST_PERP_CTRL_w/LOWEST_PRIORITY
vsim -novopt -suppress 12110 intp_ctrl_tb +test_name=PERP_CTRL_RANDOM_PRIORITY

# View waveform
add wave -r *
run -all
```

## Example Simulation Log
``` yaml
=========== COLLECTION OF INTERRUPTERS: 1010010110010010 ===========
Peripheral Controller 1 raised interrupt request, priority = 5
Peripheral Controller 4 raised interrupt request, priority = 9
Peripheral Controller 10 raised interrupt request, priority = 2
Peripheral Controller 15 raised interrupt request, priority = 12
# 200 >> Interrupt valid asserted
# 230 >> Servicing and de-asserting interrupt[15]
# 240 >> Next highest-priority interrupt selected: [4]
```
## Key Takeaways
- Designing FSM-based arbitration logic
- Building configurable and parameterized RTL
- Using `$value$plusargs` for flexible simulation control
- Writing clean, reusable tasks for testbench automation
- Understanding the difference between APB protocol and APB-style modeling

Working on this project gave me a much clearer sense of how hardware prioritization and interrupt dispatch work inside real SoCs.
Debugging priority conflicts taught me how easily race conditions appear when control logic and register access overlap, and how FSM structuring can resolve them cleanly.

---
## References
- AMBA APB Specification, ARM Ltd.
- ChipVerify – Verilog Testbench Tutorials.
- ASIC-World – Verilog Examples.
- Verification Guide – SystemVerilog Plusargs.

---
**Author:** Vishnuvardhan Chilukoti  
**Project:** Interrupt Controller - Design & Verification (Verilog)  
**Note:** This is an independent project designed and verified entirely by me.  
**Email:** vchiluk3@gmail.com


