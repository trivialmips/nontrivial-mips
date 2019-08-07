# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "RESET_POSEDGE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RESET_STAGE" -parent ${Page_0}


}

proc update_PARAM_VALUE.RESET_POSEDGE { PARAM_VALUE.RESET_POSEDGE } {
	# Procedure called to update RESET_POSEDGE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RESET_POSEDGE { PARAM_VALUE.RESET_POSEDGE } {
	# Procedure called to validate RESET_POSEDGE
	return true
}

proc update_PARAM_VALUE.RESET_STAGE { PARAM_VALUE.RESET_STAGE } {
	# Procedure called to update RESET_STAGE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RESET_STAGE { PARAM_VALUE.RESET_STAGE } {
	# Procedure called to validate RESET_STAGE
	return true
}


proc update_MODELPARAM_VALUE.RESET_STAGE { MODELPARAM_VALUE.RESET_STAGE PARAM_VALUE.RESET_STAGE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RESET_STAGE}] ${MODELPARAM_VALUE.RESET_STAGE}
}

proc update_MODELPARAM_VALUE.RESET_POSEDGE { MODELPARAM_VALUE.RESET_POSEDGE PARAM_VALUE.RESET_POSEDGE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RESET_POSEDGE}] ${MODELPARAM_VALUE.RESET_POSEDGE}
}

