
onerror {abort}
catch {quit -sim}
cd [file dirname [file normalize [info script]]]
file mkdir results
if {![file isdirectory work]} {vlib work}
vmap work work
set stamp [clock seconds]


transcript file "results/tb_scan_faults_$stamp.log"
transcript on
vlog rtl/scan_register.v
vlog -sv sim/tb_scan_faults.sv
vsim -wlf "results/tb_scan_faults_$stamp.wlf" -voptargs="+acc" work.tb_scan_faults
run -all

