# Verification of I2CMB Master with Wishbone Interface

This repository documents the structure, verification flow, and insights from four interdependent SystemVerilog verification projects. The project is divided into four subsections.

## Project Overview

### Objective
Verify an I2C Master Bridge (I2CMB) module that communicates using a Wishbone-compliant bus interface.

### Verification Goals
- Ensure correct I2C protocol behavior (read/write/acknowledge handling).
- Validate Wishbone bus transactions for proper integration.
- Detect and address edge cases and protocol violations.
- Ensure both functional correctness and coverage closure using a layered testbench.

### I2CMB DUT Architecture
![I2CMB Architecture](./assets/i2cmb_architecture.png)
*Figure 1: I2CMB DUT Architecture.*

where, **wb_if** is the Wishbone interface, **i2c_if** is the I2C slave model, and **I2CMB** represents the Master (DUT), serving as the bridge connecting both.

```bash
module top;
  // Instantiate Wishbone and I2C interfaces
  wb_if wb_if_inst();
  i2c_if i2c_if_inst();

  // Connect DUT
  i2cmb i2cmb_inst (
    .wb_clk_i (wb_if_inst.clk),
    .wb_rst_i (wb_if_inst.rst),
    .scl      (i2c_if_inst.scl),
    .sda      (i2c_if_inst.sda)
  );
endmodule
