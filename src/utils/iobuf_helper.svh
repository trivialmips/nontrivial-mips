`ifndef IOBUF_HELPER_SVH
`define IOBUF_HELPER_SVH

`define IOBUF_GEN(IN, OUT) wire OUT``_i, OUT``_o, OUT``_t; \
IOBUF IN``_buf ( \
    .IO(IN), \
    .I(OUT``_o), \
    .O(OUT``_i), \
    .T(OUT``_t) \
);

`define IOBUF_GEN_SIMPLE(IN) `IOBUF_GEN(IN, IN)

`define IOBUF_GEN_VEC(IN, OUT) wire [$bits(IN) - 1:0] OUT``_i, OUT``_o, OUT``_t; \
genvar IN``_gen_var; \
generate \
  for(IN``_gen_var = 0; IN``_gen_var < $bits(IN); IN``_gen_var = IN``_gen_var + 1) begin: IN``_buf_gen \
    IOBUF IN``_buf ( \
      .IO(IN[IN``_gen_var]), \
      .O(OUT``_i[IN``_gen_var]), \
      .I(OUT``_o[IN``_gen_var]), \
      .T(OUT``_t[IN``_gen_var]) \
    ); \
  end \
endgenerate

`define IOBUF_GEN_VEC_SIMPLE(IN) `IOBUF_GEN_VEC(IN, IN)

`define IOBUF_GEN_VEC_UNIFORM(IN, OUT) wire [$bits(IN) - 1:0] OUT``_i, OUT``_o; \
wire OUT``_t; \
genvar IN``_gen_var; \
generate \
  for(IN``_gen_var = 0; IN``_gen_var < $bits(IN); IN``_gen_var = IN``_gen_var + 1) begin: IN``_buf_gen \
    IOBUF IN``_buf ( \
      .IO(IN[IN``_gen_var]), \
      .O(OUT``_i[IN``_gen_var]), \
      .I(OUT``_o[IN``_gen_var]), \
      .T(OUT``_t) \
    ); \
  end \
endgenerate

`define IOBUF_GEN_VEC_UNIFORM_SIMPLE(IN) `IOBUF_GEN_VEC_UNIFORM(IN, IN)

`endif
