update_compile_order -fileset sources_1

set sim [get_fileset $env(SIMULATION)]

update_compile_order -fileset $sim
launch_simulation -simset $sim

cd [get_property DIRECTORY [current_project]]

set tests {bitcount bubble_sort coremark crc32 dhrystone quick_sort select_sort sha stream_copy stringsearch}

foreach test $tests {
    file copy -force ../../../soft/perf_func/obj/$test/axi_ram.mif ./mycpu.sim/sim_1/behav/xsim/axi_ram.mif
    restart
    puts {Running on testcase $test}
    run all
}

puts {All tests done!}

exit
