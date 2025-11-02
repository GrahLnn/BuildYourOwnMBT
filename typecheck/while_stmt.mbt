///|
pub(all) struct WhileStmt {
  cond : Expr
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_while_stmt(
  self : Context,
  while_stmt : @parser.WhileStmt,
) -> WhileStmt raise TypeCheckError {
  let cond = self.check_expr(while_stmt.cond)
  guard cond.ty is Bool else {
    raise TypeCheckError("while condition must be a boolean")
  }
  let body = self.check_block_expr(while_stmt.body)
  WhileStmt::{ cond, body }
}

///|
fn Context::substitute_while_stmt(
  self : Context,
  while_stmt : WhileStmt,
) -> WhileStmt raise TypeCheckError {
  let cond = self.substitute_expr(while_stmt.cond)
  let body = while_stmt.body
  WhileStmt::{ cond, body }
}
