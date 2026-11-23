# DFT Scan Register and Fault Injection

Educational Verilog/SystemVerilog project demonstrating an 8-bit scan register and serial observation of selected injected state-bit faults.

## Design

`rtl/scan_register.v` implements eight state bits with active-low asynchronous reset. Priority: reset, scan shift, parallel load, hold. On scan shift, `q <= {q[6:0], scan_in}`; `scan_out = q[7]`. The testbenches shift input patterns MSB first and sample outgoing data before the rising edge.

## Run in ModelSim

Open ModelSim, change to this project's directory, then run:

```tcl
do run_scan.do
do run_faults.do
```

Each script compiles the required source and runs its test. Timestamped console logs and waveform files are written to `results/`. Run the scripts one at a time. To inspect scan waveforms, load the scan test with `+acc`, add signals before running, and zoom:

```tcl
quit -sim
vsim -voptargs="+acc" work.tb_scan_register
add wave -r sim:/tb_scan_register/*
run -all
wave zoom full
```

## Recorded results

The included logs were produced on the author's Windows machine using ModelSim SE-64 10.6d. They were reviewed when preparing this package; simulations were not rerun during packaging.

| Test | Recorded result |
| --- | --- |
| Scan register | 13 checks passed, simulation finished at 351 ns |
| Fault injection | 16/16 selected state-bit faults detected, finished at 676 ns |

The scan test checks reset, parallel capture, shift-in/shift-out, scanned pattern readback, hold, and reset after scan.

The fault test instantiates one reference register and sixteen faulty copies. Each faulty copy has one `q` bit permanently forced to zero or one using testbench `force`. Patterns `00`, `FF`, `55`, and `AA` are loaded through scan; serial outputs are compared with the reference. Unknown fault-model outputs cause failure.

## Scope and limitations

This is an RTL learning exercise in scan operation, controllability, observability, and fault injection. The 16/16 result applies only to the sixteen explicitly modeled state-bit faults. It is not gate-level fault coverage, ATPG, automated scan insertion, physical design, or silicon validation. The functional testbench is self-checking SystemVerilog, not UVM. The fault test exercises scan shifting; it does not establish functional combinational-logic fault coverage.

## Files

- `rtl/`: scan-register RTL.
- `sim/`: self-checking functional and fault-injection testbenches.
- `run_scan.do`, `run_faults.do`: ModelSim scripts.
- `results/*.log`: original recorded simulation evidence.
