///|
pub fn Context::block_codegen(
  self : Self,
  block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  ignore(self)
  ignore(block)
  raise CodegenError("block_codegen not implemented yet")
}
