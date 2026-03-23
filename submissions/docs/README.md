# Assignment 2: Synchronous FIFO & Verilog Testbench Techniques

**Author:** Akash M R  
**ID:** 2024AAPS0758G 

## Project Overview
[cite_start]This repository contains the RTL implementation and automated verification environment for a Synchronous First-In-First-Out (FIFO) memory module[cite: 1, 16]. [cite_start]The FIFO is designed to be a sequential storage structure that preserves data ordering, ensuring the first data written is the first data read out[cite: 3, 4]. [cite_start]Read and write operations share the same clock[cite: 16].

## File Structure
[cite_start]The project is organized into the following directories as per the submission requirements[cite: 262, 265, 267]:

* `rtl/` 
    * [cite_start]`sync_fifo.v`: The core behavioral logic of the FIFO, including memory, pointers, and the occupancy counter[cite: 50, 264].
    * [cite_start]`sync_fifo_top.v`: The top-level wrapper module that instantiates the core FIFO[cite: 20, 21, 263].
* `tb/`
    * [cite_start]`tb_sync_fifo.v`: The automated, self-checking testbench used for verification[cite: 102, 266].
* `docs/`
    * [cite_start]`README.md`: Project documentation[cite: 268].

## Design Specifications (Device Under Test)
[cite_start]The RTL implementation meets the following hardware criteria[cite: 49, 50, 71]:
* [cite_start]**Parameters:** Configurable `DATA_WIDTH` (default 8) and `DEPTH` (default 16)[cite: 24, 25].
* [cite_start]**Storage:** Data is stored in a register array (`mem`)[cite: 51, 52].
* [cite_start]**Pointers & Counters:** Utilizes write and read pointers that wrap to zero after reaching `DEPTH - 1`, alongside an occupancy counter tracking the number of stored elements[cite: 53, 54, 55, 65].
* [cite_start]**Flags:** `rd_empty` and `wr_full` status flags are derived synchronously from the occupancy counter[cite: 67, 68, 69].

## Verification Strategy
[cite_start]Manual waveform inspection is minimized by utilizing a highly structured, automated testbench[cite: 101, 175]. 

### 1. Golden Reference Model
[cite_start]A cycle-accurate behavioral model is implemented independently within the testbench[cite: 103, 104]. [cite_start]It maintains its own state variables (`model_mem`, `model_wr_ptr`, `model_rd_ptr`, `model_count`) and computes the expected outputs based solely on the applied input stimulus[cite: 106, 114].

### 2. Automated Scoreboard
[cite_start]An integrated scoreboard automatically compares the DUT outputs against the Golden Model outputs on every clock cycle[cite: 138, 139]. It explicitly verifies:
* [cite_start]DUT `rd_data` vs. `model_rd_data` [cite: 142]
* [cite_start]DUT `count` vs. `model_count` [cite: 143]
* [cite_start]DUT `rd_empty` vs. `(model_count == 0)` [cite: 144]
* [cite_start]DUT `wr_full` vs. `(model_count == DEPTH)` [cite: 145]

[cite_start]Any mismatch triggers an immediate simulation termination and prints a detailed diagnostic error message[cite: 156, 169].

### 3. Directed Tests & Coverage
[cite_start]The testbench executes a series of deterministic sequences targeting specific functionality[cite: 178, 179]:
* [cite_start]Reset Test [cite: 185]
* [cite_start]Single Write / Read Test [cite: 191]
* [cite_start]Fill Test (Full Condition) [cite: 198]
* [cite_start]Drain Test (Empty Condition) [cite: 203]
* [cite_start]Overflow Attempt Test [cite: 209]
* [cite_start]Underflow Attempt Test [cite: 215]
* [cite_start]Simultaneous Read/Write Test [cite: 220]
* [cite_start]Pointer Wrap-Around Test [cite: 226]

[cite_start]Manual coverage counters (`cov_full`, `cov_empty`, `cov_wrap`, etc.) are tracked throughout the simulation to ensure all critical edge cases and illegal operations are successfully exercised[cite: 232, 240, 241, 242].
