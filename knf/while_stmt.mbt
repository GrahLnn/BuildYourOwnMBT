///|
pub fn Context::while_stmt_to_knf(
  self : Context,
  while_stmt : @typecheck.WhileStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let (cond_stmts, cond_expr) = self.expr_to_knf(while_stmt.cond)
  let body = self.block_expr_to_knf(while_stmt.body)
  cond_stmts.push(ExprStmt(cond_expr))
  let cond_block = KnfBlock::{ stmts: cond_stmts, ty: Bool }
  [While(cond_block, body)]
}
