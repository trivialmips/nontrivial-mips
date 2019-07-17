update_compile_order -fileset sources_1

# If IP cores are used
if { [llength [get_ips]] != 0} {
    upgrade_ip [get_ips]

    foreach ip [get_ips] {
        create_ip_run [get_ips $ip]
    }

    set ip_runs [get_runs -filter {SRCSET != sources_1 && IS_SYNTHESIS && STATUS != "synth_design Complete!"}]
    
    if { [llength $ip_runs] != 0} {
        launch_runs -quiet -jobs 2 {*}$ip_runs
        
        foreach r $ip_runs {
            wait_on_run $r
        }
    }

}

exit
