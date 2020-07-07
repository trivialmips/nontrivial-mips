# NonTrivialMIPS

NonTrivial-MIPS is a synthesizable superscalar MIPS processor with branch prediction and CP1 (FPU), CP2 (AES accelerator) support, and it is capable of booting fully-functional Linux.

## Authors

See `AUTHORS` for information about the authors of this project.

## Directory Structure

* `loongson`: files from Loongson, some are adapted
  * `cpu_gs232`: RTL code of GS232 CPU (__not included for copyright reason__), packaged as Vivado IP
  * `soc_axi_func`: Vivado project, RTL code and testbench of functional test (using NonTrivialMIPS CPU)
  * `soc_axi_perf`: Vivado project, RTL code and testbench of performance test (using NonTrivialMIPS CPU)
  * `soc_run_os`: Vivado project and RTL code of a whole SoC (using GS232 CPU, upgraded to 2018.3)
  * `soft`: RAM initialization files used by the projects above
* `src`: RTL code of NonTrivialMIPS CPU
* `vivado`: Vivado project and block design of NSCSCC SoC
* `testbench`: Testbenches of NonTrivialMIPS CPU / NSCSCC Soc
* `report`: Design reports (LaTeX srouce code and rendered PDF)

*Remark*: `out-of-order` branch contains a toy dual-issue out-of-order processor.

## Build Project

### Update submodules

We use git submodules to manage external code. Run `git submodule update --init` after cloning this project to ensure everything is up-to-date.

### Compiling options

NonTrivialMIPS CPU has some compiling flags that can control the features that will be enabled and parameters (such as cache size and associativity) that will be used. See `src/compile_options.svh` for details.

Note that inappropriate changes made to these flags may lead to strange or WRONG behaviors of the CPU.

### Generate bitstream

You can generate bitstreams that can be programmed to FPGA by following commands:

```bash
# for soc project
/path/to/vivado -mode tcl -source scripts/build_soc.tcl vivado/TrivialMIPS.xpr
# for loongson functional test
/path/to/vivado -mode tcl -source scripts/generate_bitstream.tcl loongson/soc_axi_func/run_vivado/mycpu_prj1/mycpu.xpr
# for loongson performance test
/path/to/vivado -mode tcl -source scripts/generate_bitstream.tcl loongson/soc_axi_perf/run_vivado/mycpu_prj1/mycpu.xpr
```

Vivado 2018.3 is required.

## License

All source code under `src/` is released under the MIT License with the following exceptions:

* `src/asic/aes/` is licensed under BSD-2-Clause License (source code from [GitHub](https://github.com/secworks/aes/))
* `src/utils/fifo_v3.sv` is licesed under [The Solderpad Hardware Licence](https://solderpad.org/licenses/) (source code from [GitHub](https://github.com/pulp-platform/ariane))

Other directories might contain source code or materials that are proprietary or subject to open source licenses and kept in this repository as-is.
Should you use these contents, you are aware that you will bear any corresponding legal responsibility or consequences.

