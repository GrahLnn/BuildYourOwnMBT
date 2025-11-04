///|
pub fn Context::let_mut_stmt_to_knf(
  self : Context,
  let_mut_stmt : @typecheck.LetMutStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let name = let_mut_stmt.name
  let ty = let_mut_stmt.ty
  let expr = let_mut_stmt.expr
  let (stmts, expr) = self.expr_to_knf(expr)
  let ty = self.typekind_to_knf(ty)
  let name = self.add_new_name(name, ty)
  stmts.push(LetMut(name, ty, expr))
  stmts
}
