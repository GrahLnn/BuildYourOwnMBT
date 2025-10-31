///|
pub(all) struct LetMutStmt {
  name : String
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub fn Context::check_let_mut_stmt(
  self : Context,
  stmt : @parser.LetMutStmt,
) -> LetMutStmt raise TypeCheckError {
  let expr = self.check_expr(stmt.expr)
  let ty = match stmt.ty {
    Some(ty) => self.check_parser_type(ty).kind
    None => self.tyvar()
  }
  let name = stmt.name
  guard self.confirm_type(ty, expr.ty, name, true) else {
    raise TypeCheckError("Type mismatch in let_mut_stmt")
  }
  LetMutStmt::{ name, ty: expr.ty, expr }
}
