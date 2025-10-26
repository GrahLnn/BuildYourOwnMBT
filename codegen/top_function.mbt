///|
///
/// 注意区分main函数与其他函数的codegen。
pub fn Context::top_function_codegen(
  self : Self,
  func : @knf.KnfFunction,
) -> @llvm.Function raise {
  ignore(self)
  ignore(func)
  raise CodegenError("top_function_codegen unimplemented")
}
