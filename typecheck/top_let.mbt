///|
pub(all) struct TopLet {
  name : String
  ty : Type
  expr : Expr
} derive(Show)

///|
pub fn Context::check_top_let(
  self : Context,
  top_let : @parser.TopLet,
) -> TopLet raise TypeCheckError {
  let expr = self.check_expr(top_let.expr)
  let ty = match top_let.ty {
    Some(ty) => self.check_parser_type(ty).kind
    None => self.tyvar()
  }
  let name = top_let.name
  guard self.confirm_type(ty, expr.ty, name, false) else {
    raise TypeCheckError("Type mismatch in top_let")
  }
  let ty = Type::{ kind: expr.ty, mutable: false }
  TopLet::{ name, ty, expr }
}

///|
fn Context::substitute_top_let(
  self : Context,
  top_let : TopLet,
) -> TopLet raise TypeCheckError {
  let expr = self.substitute_expr(top_let.expr)
  let ty = self.subst_type(top_let.ty)
  TopLet::{ name: top_let.name, ty, expr }
}
