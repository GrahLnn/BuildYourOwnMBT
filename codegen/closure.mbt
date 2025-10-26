///|
pub fn Context::closure_codegen(
  self : Context,
  closure_def : @knf.KnfClosure,
) -> Unit raise {
  ignore(self)
  ignore(closure_def)
  raise CodegenError("closure_codegen not implemented")
}
