#!/bin/bash

RETRY_COUNT=1

CONFIG_PATH="scripts/matrix/config"
RESULT_PATH="scripts/matrix/result"

# Initial setup
sed -i "s/ICACHE_NO_INVALIDATE *0/ICACHE_NO_INVALIDATE 1/" src/compile_options.svh
sed -i "s/CPU_PERFORMANCE *0/CPU_PERFORMANCE 1/" src/compile_options.svh
sed -i "s/\`define COMPILE_FULL_M/\\/\\/ \`define COMPILE_FULL_M/" src/compile_options.svh

# Set clocking commands
declare -A CLK_CMDS=(
#   ["80"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {80} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {12} CONFIG.MMCM_CLKOUT0_DIVIDE_F {15} CONFIG.MMCM_CLKOUT1_DIVIDE {12} CONFIG.CLKOUT1_JITTER {120.663} CONFIG.CLKOUT1_PHASE_ERROR {87.180} CONFIG.CLKOUT2_JITTER {115.831} CONFIG.CLKOUT2_PHASE_ERROR {87.180}] [get_ips clk_pll]"
#   ["90"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {90} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {9} CONFIG.MMCM_CLKOUT0_DIVIDE_F {10} CONFIG.MMCM_CLKOUT1_DIVIDE {9} CONFIG.CLKOUT1_JITTER {140.709} CONFIG.CLKOUT1_PHASE_ERROR {105.461} CONFIG.CLKOUT2_JITTER {137.681} CONFIG.CLKOUT2_PHASE_ERROR {105.461}] [get_ips clk_pll]"
#   ["100"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {9} CONFIG.MMCM_CLKOUT0_DIVIDE_F {9} CONFIG.MMCM_CLKOUT1_DIVIDE {9} CONFIG.CLKOUT1_JITTER {137.681} CONFIG.CLKOUT1_PHASE_ERROR {105.461} CONFIG.CLKOUT2_JITTER {137.681} CONFIG.CLKOUT2_PHASE_ERROR {105.461}] [get_ips clk_pll]"
#  ["105"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {105} CONFIG.MMCM_DIVCLK_DIVIDE {3} CONFIG.MMCM_CLKFBOUT_MULT_F {50} CONFIG.MMCM_CLKOUT0_DIVIDE_F {16} CONFIG.MMCM_CLKOUT1_DIVIDE {17} CONFIG.CLKOUT1_JITTER {109.153} CONFIG.CLKOUT1_PHASE_ERROR {147.831} CONFIG.CLKOUT2_JITTER {110.049} CONFIG.CLKOUT2_PHASE_ERROR {147.831}] [get_ips clk_pll]"
  ["108"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {108} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {14} CONFIG.MMCM_CLKOUT0_DIVIDE_F {13} CONFIG.MMCM_CLKOUT1_DIVIDE {14} CONFIG.CLKOUT1_JITTER {101.304} CONFIG.CLKOUT1_PHASE_ERROR {79.592} CONFIG.CLKOUT2_JITTER {102.665} CONFIG.CLKOUT2_PHASE_ERROR {79.592}] [get_ips clk_pll]"
  ["110"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {110} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {11} CONFIG.MMCM_CLKOUT0_DIVIDE_F {10} CONFIG.MMCM_CLKOUT1_DIVIDE {11} CONFIG.CLKOUT1_JITTER {121.476} CONFIG.CLKOUT1_PHASE_ERROR {92.672} CONFIG.CLKOUT2_JITTER {123.670} CONFIG.CLKOUT2_PHASE_ERROR {92.672}] [get_ips clk_pll]"
  ["112"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {112} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {9} CONFIG.MMCM_CLKOUT0_DIVIDE_F {8} CONFIG.MMCM_CLKOUT1_DIVIDE {9} CONFIG.CLKOUT1_JITTER {134.399} CONFIG.CLKOUT1_PHASE_ERROR {105.461} CONFIG.CLKOUT2_JITTER {137.681} CONFIG.CLKOUT2_PHASE_ERROR {105.461}] [get_ips clk_pll]"
  ["115"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {115} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {15} CONFIG.MMCM_CLKOUT0_DIVIDE_F {13} CONFIG.MMCM_CLKOUT1_DIVIDE {15} CONFIG.CLKOUT1_JITTER {93.870} CONFIG.CLKOUT1_PHASE_ERROR {76.967} CONFIG.CLKOUT2_JITTER {96.283} CONFIG.CLKOUT2_PHASE_ERROR {76.967}] [get_ips clk_pll]"
  ["120"]="set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {120} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {12} CONFIG.MMCM_CLKOUT0_DIVIDE_F {10} CONFIG.MMCM_CLKOUT1_DIVIDE {12} CONFIG.CLKOUT1_JITTER {112.035} CONFIG.CLKOUT1_PHASE_ERROR {87.180} CONFIG.CLKOUT2_JITTER {115.831} CONFIG.CLKOUT2_PHASE_ERROR {87.180}] [get_ips clk_pll]"
)

CLK_FREQS=$(sort -n <<< "$(printf '%s\n' "${!CLK_CMDS[@]}")")
echo "[MATRIX] All freqs: $(printf '%s ' $CLK_FREQS)"

function alter_clocking {
  tmpfile=$(mktemp)
  echo "[MATRIX] Alter clk freq to $freq"
  echo "[MATRIX] Using temp file as tcl source: $tmpfile"
  echo ${CLK_CMDS["$freq"]} > $tmpfile
  echo "exit" >> $tmpfile

  $VIVADO_PATH -mode tcl -source $tmpfile loongson/soc_axi_perf/run_vivado/mycpu_prj1/mycpu.xpr | tee "$FREQ_PATH/vivado.clk.log"

  echo "[MATRIX] generate all IP"
  $VIVADO_PATH -mode tcl -source scripts/generate_all_ips.tcl loongson/soc_axi_perf/run_vivado/mycpu_prj1/mycpu.xpr | tee "$FREQ_PATH/vivado.gen.log"
}

# Apply parameters
function apply_parameters {
  sed -i "s/ICACHE_SIZE.*$/ICACHE_SIZE $ICACHE_SIZE/" src/compile_options.svh
  sed -i "s/DCACHE_SIZE.*$/DCACHE_SIZE $DCACHE_SIZE/" src/compile_options.svh
  sed -i "s/ICACHE_SET_ASSOC.*$/ICACHE_SET_ASSOC $ICACHE_SET_ASSOC/" src/compile_options.svh
  sed -i "s/DCACHE_SET_ASSOC.*$/DCACHE_SET_ASSOC $DCACHE_SET_ASSOC/" src/compile_options.svh
  sed -i "s/DCACHE_WB_FIFO_DEPTH.*$/DCACHE_WB_FIFO_DEPTH $DCACHE_WB_FIFO_DEPTH/" src/compile_options.svh
  sed -i "s/BPU_SIZE.*$/BPU_SIZE $BPU_SIZE/" src/compile_options.svh
}

# Execute
function run_iterations {
  apply_parameters
  alter_clocking
  for i in $(seq 1 $RETRY_COUNT); do
    ITER_PATH="$FREQ_PATH/$i"
    mkdir -p $ITER_PATH

    echo "[MATRIX] Running for case $STUB, freq $freq, iteration $i"
    $VIVADO_PATH -mode tcl -source scripts/generate_bitstream.tcl loongson/soc_axi_perf/run_vivado/mycpu_prj1/mycpu.xpr | tee "$ITER_PATH/vivado.bit.log"

    cp loongson/soc_axi_perf/run_vivado/mycpu_prj1/mycpu.runs/impl_1/soc_axi_lite_top.bit $ITER_PATH/soc.bit
    mkdir -p "$ITER_PATH/rpt"
    for file in $(find loongson/soc_axi_perf/run_vivado/mycpu_prj1/mycpu.runs/impl_1 -mindepth 1 | grep -E "routed|route_status"); do
      bfn=$(basename $file)
      sliced_bfn=$(echo $bfn | sed "s/soc_axi_lite_top_//")
      cp $file $ITER_PATH/rpt/$sliced_bfn
    done

    cp loongson/soc_axi_perf/run_vivado/mycpu_prj1/mycpu.runs/impl_1/route_design.pb $ITER_PATH/route_design.pb

    WORST_LINE=$(cat $ITER_PATH/rpt/timing_summary_routed.rpt | grep "^Slack" | head -n 1)
    WORST_SLACK=$(echo $WORST_LINE | grep -Eo -- "-?[0-9.]+ns")

    if echo $WORST_LINE | grep VIOLATED; then
      echo "[MATRIX] Timing violated. Slack: $WORST_SLACK"
      echo "VIOLATED\n$WORST_SLACK" > $ITER_PATH/result
    else
      echo "[MATRIX] Timing met. Slack: $WORST_SLACK"
      echo "MET\n$WORST_SLACK" > $ITER_PATH/result
      return 0
    fi
  done

  echo "[MATRIX] Case $STUB failed freq $freq"
  return 1
}

for config in $(find $CONFIG_PATH -mindepth 1); do
  STUB=$(basename $config)
  echo "[MATRIX] Running case $STUB"

  # Loads config
  source $config

  CASE_PATH="$RESULT_PATH/$STUB"

  mkdir -p "$CASE_PATH"

  for freq in $CLK_FREQS; do
    FREQ_PATH="$CASE_PATH/$freq"
    mkdir -p "$FREQ_PATH"

    run_iterations

    if [[ $? = 1 ]]; then
      break
    fi
  done
done
