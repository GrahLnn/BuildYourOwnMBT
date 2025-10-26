///|
pub fn Context::if_codegen(
  self : Self,
  cond : @knf.KnfExpr,
  then_block : @knf.KnfBlock,
  else_block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  ignore(self)
  ignore(cond)
  ignore(then_block)
  ignore(else_block)
  raise CodegenError("if_codegen not implemented")
}
