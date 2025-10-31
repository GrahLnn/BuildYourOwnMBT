///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_block_expr(
  self : Context,
  block_expr : @parser.BlockExpr,
) -> BlockExpr raise TypeCheckError {
  self.enter_scope()
  println("typevar start: \{self.type_vars}")
  let stmts = block_expr.stmts.map(s => self.check_stmt(s))
  let ty = match stmts.last() {
    None => TypeKind::Unit
    Some(stmt) =>
      match stmt.kind {
        ExprStmt(expr) => expr.ty
        ReturnStmt(expr) =>
          match expr {
            Some(expr) => expr.ty
            None => TypeKind::Unit
          }
        _ => TypeKind::Unit
      }
  }
  println("typevar end: \{self.type_vars}")
  self.type_vars.clear()
  self.exit_scope()
  BlockExpr::{ stmts, ty }
}
