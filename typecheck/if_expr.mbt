///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_if_expr(
  self : Context,
  if_expr : @parser.IfExpr,
) -> IfExpr raise TypeCheckError {
  let cond = self.check_expr(if_expr.cond)
  guard cond.ty is Bool else {
    raise TypeCheckError("if condition must be a boolean")
  }
  let then_block = self.check_block_expr(if_expr.then_block)
  let t_then = then_block.ty
  let else_block : Either[IfExpr, BlockExpr]? = match if_expr.else_block {
    Some(Left(e)) => Some(Left(self.check_if_expr(e)))
    Some(Right(b)) => Some(Right(self.check_block_expr(b)))
    None => None
  }
  let t_else = match else_block {
    Some(Left(e)) => e.ty
    Some(Right(b)) => b.ty
    None => Unit
  }
  guard self.is_type_compatible(t_then, t_else) else {
    raise TypeCheckError("if and else branches must have the same type")
  }
  IfExpr::{ cond, then_block, else_block, ty: t_then }
}

///|
fn Context::substitute_if_expr(
  self : Context,
  expr : IfExpr,
) -> IfExpr raise TypeCheckError {
  IfExpr::{
    cond: self.substitute_expr(expr.cond),
    then_block: self.substitute_block_expr(expr.then_block),
    else_block: match expr.else_block {
      Some(Left(e)) => Some(Left(self.substitute_if_expr(e)))
      Some(Right(b)) => Some(Right(self.substitute_block_expr(b)))
      None => None
    },
    ty: self.analysis_type(expr.ty),
  }
}
