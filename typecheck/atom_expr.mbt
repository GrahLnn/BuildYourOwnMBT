///|
pub(all) struct AtomExpr {
  kind : AtomExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum AtomExprKind {
  Int(Int) // 1, 42, etc
  Double(Double) // 1.0, 3.14, etc
  Bool(Bool) // true | false
  String(String) // "hello", etc
  Ident(String) // var
  Unit // ()
  Paren(Expr) // (expr)
  Tuple(Array[Expr]) // (expr, expr, ...)
  Array(Array[Expr]) // [expr, expr, ...]
  ArrayMake(Expr, Expr) // Array::make(size, init)
  StructConstruct(StructConstructExpr) // StructName::{ field: expr, ... }
} derive(Show)

///|
pub fn Context::check_atom_expr(
  self : Self,
  atom_expr : @parser.AtomExpr,
) -> AtomExpr raise TypeCheckError {
  match atom_expr.kind {
    Int(v) => AtomExpr::{ kind: Int(v), ty: Int }
    Double(v) => AtomExpr::{ kind: Double(v), ty: Double }
    Bool(v) => AtomExpr::{ kind: Bool(v), ty: Bool }
    String(v) => AtomExpr::{ kind: String(v), ty: String }
    Ident(v) =>
      AtomExpr::{
        kind: Ident(v),
        ty: self.type_env
        .get(v)
        .unwrap_or_else(() => raise TypeCheckError("Unknown identifier")).kind,
      }
    Unit => AtomExpr::{ kind: Unit, ty: Unit }
    Paren(expr) => {
      let expr = self.check_expr(expr)
      AtomExpr::{ kind: Paren(expr), ty: expr.ty }
    }
    Tuple(exprs) => {
      let exprs = exprs.map(expr => self.check_expr(expr))
      AtomExpr::{ kind: Tuple(exprs), ty: Tuple(exprs.map(expr => expr.ty)) }
    }
    ArrayMake(size, init) => {
      let size = self.check_expr(size)
      let init = self.check_expr(init)
      guard size.ty is Int else {
        raise TypeCheckError("ArrayMake size must be an integer")
      }
      AtomExpr::{ kind: ArrayMake(size, init), ty: Array(init.ty) }
    }
    Array(exprs) =>
      if exprs.length() > 0 {
        let exprs = exprs.map(expr => self.check_expr(expr))
        let goal_ty = loop exprs[:] {
          [ex, .. rest] =>
            if !has_type_var(ex.ty) {
              break Some(ex.ty)
            } else {
              continue rest
            }
          [] => break None
        }
        let ty = match goal_ty {
          Some(y) =>
            loop exprs[:] {
              [ex, .. rest] => {
                let name = self.has_ident(ex)
                let check = match name {
                  Some(name) => {
                    let ty = self.type_env.get(name).unwrap()
                    self.confirm_type(ex.ty, y, name, ty.mutable)
                  }
                  None => self.is_type_compatible(ex.ty, y)
                }
                if check {
                  continue rest
                } else {
                  raise TypeCheckError("Array elements must be compatible")
                }
              }
              [] => break TypeKind::Array(y)
            }
          None => Array(exprs[0].ty)
        }
        AtomExpr::{ kind: Array(exprs), ty }
      } else {
        let a = self.tyvar()
        AtomExpr::{ kind: Array(Array::new()), ty: Array(a) }
      }
    StructConstruct(sc_expr) => {
      let (kind, ty) = self.check_struct_construct_expr(sc_expr)
      AtomExpr::{ kind: StructConstruct(kind), ty }
    }
  }
}
