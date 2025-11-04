///|
pub fn Context::if_expr_to_knf(
  self : Context,
  if_expr : @typecheck.IfExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  let stmts = Array::new()
  let (cond_stmts, cond_knf_expr) = self.expr_to_knf(if_expr.cond)
  stmts.append(cond_stmts)
  let then_knf_block = self.block_expr_to_knf(if_expr.then_block)
  let else_knf_block = match if_expr.else_block {
    Some(Left(else_if_expr)) => {
      let (else_stmts, nested_if_knf) = self.if_expr_to_knf(else_if_expr)
      stmts.append(else_stmts)
      KnfBlock::{
        stmts: [KnfStmt::ExprStmt(nested_if_knf)],
        ty: self.typekind_to_knf(else_if_expr.ty),
      }
    }
    Some(Right(else_block_expr)) => self.block_expr_to_knf(else_block_expr)
    None => KnfBlock::{ stmts: [], ty: self.typekind_to_knf(if_expr.ty) }
  }
  (stmts, If(cond_knf_expr, then_knf_block, else_knf_block))
}
