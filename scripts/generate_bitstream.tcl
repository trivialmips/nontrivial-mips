update_compile_order -fileset sources_1

reset_run impl_1
reset_run synth_1
launch_runs -jobs 2 impl_1 -to_step write_bitstream
wait_on_run impl_1

exit
