# Run cdXadc first to set the correct directory

# Create output directory and clear contents
set outputdir ./synthesis
file mkdir $outputdir

# Sets the files variable to get the names of all the files
# present in the output directory
# glob returns all files that match the pattern specified
#set files [glob -nocomplain "$outputdir/*"]

# puts will output the a message to the console
#if {[llength $files] != 0} {
#    puts "Deleting the Contents of $outputdir"
#    file delete -force {*}[glob -directory $outputdir *];
#} else {
#    puts "$outputdir is empty"
#}

if {[catch {current_project} errMsg]} {

} else {
    close_project
}

# Create project
create_project -part xc7a100tcsg324-1 xadc_top $outputdir -force

# Add testbench source file
add_files -fileset sim_1 ./tb/xadc_if_tb.v
add_files [glob ../../base_components/verilog/src/*.v]
add_files ./src/xadc_top.v
add_files -fileset constrs_1 ../constraint.xdc
set_property library work [get_files [glob ../../base_components/verilog/src/*.v]]

# Set top level module and update compile order
set_property top top [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Launch synthesis
launch_runs synth_1
wait_on_run synth_1
puts "Synthesis Done"

puts -nonewline "Do you want to continue with implementation/bitstream? y/n"
flush stdout
# set answer [gets stdin]
set answer "y"

if {$answer != "y"} {
    puts "Exiting at implementation stage"
} else {
    # Run Implementation and generate bitstream
    set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
    #set_property STEPS.OPT_DESIGN.TCL.PRE [pwd]/pre_opt_design.tcl [get_runs impl_1]
    #set_property STEPS.OPT_DESIGN.TCL.POST [pwd]/post_opt_design.tcl [get_runs impl_1]
    #set_property STEPS.PLACE_DESIGN.TCL.POST [pwd]/post_place_design.tcl [get_runs impl_1]
    #set_property STEPS.PHYS_OPT_DESIGN.TCL.POST [pwd]/post_phys_opt_design.tcl [get_runs impl_1]
    #set_property STEPS.ROUTE_DESIGN.TCL.POST [pwd]/post_route_design.tcl [get_runs impl_1]
    launch_runs impl_1 -to_step write_bitstream
    wait_on_run impl_1
    puts "Implementation and Bitstream Done"
}

# Connect to the Digilent Cable on localhost:3121
open_hw_manager
connect_hw_server -url localhost:3121
puts "Connect done"
#current_hw_target [get_hw_targets */xilinx_tcf/Digilent/12345]
open_hw_target

puts "HW DEVICES LIST"
puts [get_hw_devices]

#current_hw_device [get_hw_devices xc7a100t_0]
#refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7a100t_0] 0]
# Program and Refresh the XC7K325T Device
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {C:/Users/Jak/win_shared/projs/xadc_if/verilog/synthesis/xadc_if.runs/impl_1/xadc_if.bit} [lindex [get_hw_devices] 0]
set_property PROBES.FILE {} [lindex [get_hw_devices] 0]

program_hw_devices [lindex [get_hw_devices] 0]
refresh_hw_device [lindex [get_hw_devices] 0]

# "vivado -mode tcl" will open vivado TCL command line (doesn't work on Windows unless you have the path set up, currently broken)
# "source xadc_if.tcl" will run this script. -notrace will stop the command line from displaying the TCL code