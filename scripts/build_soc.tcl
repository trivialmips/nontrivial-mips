update_compile_order -fileset sources_1
upgrade_ip [get_ips]

create_ip_run [get_files -of_objects [get_fileset sources_1] bd_soc.bd]

reset_run impl_1
reset_run synth_1

launch_runs -quiet impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

exit
