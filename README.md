# NonTrivialMIPS

NonTrivial-MIPS is a synthesizable superscalar MIPS processor with branch prediction and FPU support, and it is capable of booting linux.

## Directory Structure

* `loongson`: files from Loongson, some are adapted
  * `cpu_gs232`: RTL code of GS232 CPU (__not committed for copyright reason__), packaged as Vivado IP
  * `soc_axi_func`: Vivado project and RTL code of functional test (using NonTrivialMIPS CPU)
  * `soc_axi_perf`: Vivado project and RTL code of performance test (using NonTrivialMIPS CPU)
  * `soc_run_os`: Vivado project and RTL code of a whole SoC (using GS232 CPU, upgraded to 2018.3)
* `src`: RTL code of NonTrivialMIPS CPU
* `vivado`: Vivado project and block design of NSCSCC SoC (now using GS232 IP)
* `testbench`: Testbenches of NonTrivialMIPS CPU / NSCSCC Soc
* `material`: references
