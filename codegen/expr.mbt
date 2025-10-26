///|
///
/// 注意这里的expr_codegen的返回值是Option[&@llvm.Value]
/// 对于Unit类型的表达式，应当返回None做特殊处理。
///
/// 对于像let a: Unit = (); 这种表达式，可以考虑把a的值设为null指针，
/// 使用llvm_ctx.getConstPointerNull(llvm_ctx.getPtrTy())
pub fn Context::expr_codegen(
  self : Self,
  expr : @knf.KnfExpr,
) -> &@llvm.Value? raise {
  match expr {
    Int(i) => (self.llvm_ctx.getConstInt32(i) : &@llvm.Value) |> Some
    e => raise CodegenError("Unsupported expression in codegen: \{e}")
  }
}
