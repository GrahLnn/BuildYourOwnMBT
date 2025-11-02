///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show)

///|
pub fn Context::check_apply_expr(
  self : Self,
  apply_expr : @parser.ApplyExpr,
) -> ApplyExpr raise TypeCheckError {
  match apply_expr.kind {
    AtomExpr(atom_expr) => {
      let atom_expr = self.check_atom_expr(atom_expr)
      ApplyExpr::{ kind: AtomExpr(atom_expr), ty: atom_expr.ty }
    }
    ArrayAccess(expr, index) => {
      let expr = self.check_apply_expr(expr)
      let index = self.check_expr(index)
      guard expr.ty is Array(ty) && index.ty is Int else {
        raise TypeCheckError("Array access not allowed on type \{expr.ty}")
      }
      ApplyExpr::{ kind: ArrayAccess(expr, index), ty }
    }
    FieldAccess(expr, field_name) => {
      let expr = self.check_apply_expr(expr)
      match expr.ty {
        Struct(name) => {
          let fields = match self.struct_defs.get(name) {
            Some(structure) => structure.fields
            None => raise TypeCheckError("\{name} is not a struct")
          }
          let ty = fields
            .filter(field => field.name == field_name)
            .map(field => field.ty)
          guard ty.length() == 1 else {
            raise TypeCheckError(
              "Field \{field_name} not found in struct \{name}",
            )
          }
          ApplyExpr::{ kind: FieldAccess(expr, field_name), ty: ty[0].kind }
        }
        Array(_) =>
          match field_name {
            "push" =>
              match expr.ty {
                Array(t) =>
                  ApplyExpr::{
                    kind: FieldAccess(expr, "push"),
                    ty: Function([t], Unit),
                  }
                _ =>
                  raise TypeCheckError(
                    "Field access not allowed on type \{expr.ty}",
                  )
              }
            "length" =>
              ApplyExpr::{
                kind: FieldAccess(expr, "length"),
                ty: Function([], Int),
              }
            _ =>
              raise TypeCheckError(
                "Field access not allowed on type \{expr.ty}",
              )
          }
        _ => raise TypeCheckError("Field access not allowed on type \{expr.ty}")
      }
    }
    Call(expr, arg_exprs) => {
      let expr = self.check_apply_expr(expr)
      guard expr.ty is Function(argt, ret) else {
        raise TypeCheckError("Call not allowed on type \{expr.ty}")
      }
      let args = Array::new()
      for i, e in arg_exprs {
        let exp = self.check_expr(e)
        guard self.is_type_compatible(argt[i], exp.ty) else {
          raise TypeCheckError(
            "Argument \{e} has type \{exp.ty}, expected \{argt[i]}",
          )
        }
        args.push(exp)
      }
      let ty = self.deref_type(ret)
      match expr.kind {
        FieldAccess(e, _) =>
          match e.kind {
            AtomExpr(e) =>
              match e.kind {
                Ident(name) => {
                  let ty = match self.lookup_type(name) {
                    Some(ty) => ty
                    None => raise TypeCheckError("Type not found: \{name}")
                  }
                  if has_type_var(ty.kind) {
                    let ty_kind = self.analysis_type(ty.kind)
                    let ty = Type::{ kind: ty_kind, mutable: ty.mutable }
                    self.type_env.set(name, ty)
                  }
                }
                _ =>
                  raise TypeCheckError(
                    "Field access not allowed on type \{expr.ty}",
                  )
              }
            _ =>
              raise TypeCheckError(
                "Field access not allowed on type \{expr.ty}",
              )
          }
        _ => ()
      }
      ApplyExpr::{ kind: Call(expr, args), ty }
    }
  }
}

///|
fn Context::substitute_apply_expr(
  self : Context,
  expr : ApplyExpr,
) -> ApplyExpr raise TypeCheckError {
  match expr.kind {
    AtomExpr(atom_expr) =>
      ApplyExpr::{
        kind: AtomExpr(self.substitute_atom_expr(atom_expr)),
        ty: self.analysis_type(atom_expr.ty),
      }
    ArrayAccess(expr, index) => {
      let expr = self.substitute_apply_expr(expr)
      let index = self.substitute_expr(index)
      ApplyExpr::{
        kind: ArrayAccess(expr, index),
        ty: self.analysis_type(expr.ty),
      }
    }
    FieldAccess(expr, field_name) => {
      let expr = self.substitute_apply_expr(expr)
      match expr.ty {
        Struct(_) =>
          ApplyExpr::{ kind: FieldAccess(expr, field_name), ty: expr.ty }
        Array(_) =>
          match field_name {
            "push" =>
              match expr.ty {
                Array(t) =>
                  ApplyExpr::{
                    kind: FieldAccess(expr, "push"),
                    ty: Function([self.analysis_type(t)], Unit),
                  }
                _ => expr
              }
            _ => expr
          }
        _ => expr
      }
    }
    Call(expr, arg_exprs) => {
      let expr = self.substitute_apply_expr(expr)
      let args = Array::new()
      for e in arg_exprs {
        let exp = self.substitute_expr(e)
        args.push(exp)
      }
      ApplyExpr::{ kind: Call(expr, args), ty: expr.ty }
    }
  }
}
