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
  let stmts = block_expr.stmts.map(s => self.check_stmt(s))
  let ty = match stmts.last() {
    None => TypeKind::Unit
    Some(stmt) =>
      match stmt.kind {
        ExprStmt(expr) => self.analysis_type(expr.ty)
        ReturnStmt(expr) =>
          match expr {
            Some(expr) => self.analysis_type(expr.ty)
            None => TypeKind::Unit
          }
        _ => TypeKind::Unit
      }
  }
  self.exit_scope()
  BlockExpr::{ stmts, ty }
}

///|
pub fn Context::substitute_block_expr(
  self : Context,
  block_expr : BlockExpr,
) -> BlockExpr raise TypeCheckError {
  let stmts = block_expr.stmts.map(s => self.substitute_stmt(s))
  let ty = self.analysis_type(block_expr.ty)
  BlockExpr::{ stmts, ty }
}
