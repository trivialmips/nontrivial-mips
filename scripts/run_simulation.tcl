update_compile_order -fileset sources_1

set simulations [get_fileset $env(SIMULATION)]

if { [llength simulations] != 0} {
	foreach sim $simulations {
                update_compile_order -fileset $sim
                launch_simulation -simset $sim
                # make simulation complete
                run all
	}
}

exit
