///|
pub(all) struct LeftValue {
  kind : LeftValueKind
  ty : Type
} derive(Show)

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show)

///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
pub fn AssignOp::from_parser_assign_op(op : @parser.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn Context::check_assign_stmt(
  self : Context,
  assign_stmt : @parser.AssignStmt,
) -> AssignStmt raise TypeCheckError {
  let left_value = self.check_left_value(assign_stmt.left_value)
  let op = AssignOp::from_parser_assign_op(assign_stmt.op)
  let expr = self.check_expr(assign_stmt.expr)
  match left_value.kind {
    Ident(name) =>
      if !self.confirm_type(
          left_value.ty.kind,
          expr.ty,
          name,
          left_value.ty.mutable,
        ) {
        raise TypeCheckError(
          "Type mismatch in assignment \{name} \{left_value.ty.kind} != \{expr.ty}",
        )
      }
    _ =>
      if !self.is_type_compatible(left_value.ty.kind, expr.ty) {
        raise TypeCheckError(
          "Type mismatch in assignment \{left_value.ty.kind} != \{expr.ty}",
        )
      }
  }
  match op {
    Assign => ()
    PlusAssign | MinusAssign | MultAssign | DivAssign | ModAssign =>
      if !self.is_type_compatible(expr.ty, Int) &&
        !self.is_type_compatible(expr.ty, Double) {
        raise TypeCheckError(
          "Only numbers can be assigned to variables, found \{expr.ty}",
        )
      }
  }
  AssignStmt::{ left_value, op, expr }
}

///|
fn Context::substitute_assign_stmt(
  self : Context,
  assign_stmt : AssignStmt,
) -> AssignStmt raise TypeCheckError {
  let left_value = self.substitute_left_value(assign_stmt.left_value)
  let op = assign_stmt.op
  let expr = self.substitute_expr(assign_stmt.expr)
  AssignStmt::{ left_value, op, expr }
}

///|
pub fn Context::check_left_value(
  self : Context,
  left_value : @parser.LeftValue,
) -> LeftValue raise TypeCheckError {
  match left_value.kind {
    Ident(name) => {
      let ty = self.lookup_type(name).unwrap()
      match ty.kind {
        Array(_) => ()
        _ =>
          if !ty.mutable {
            raise TypeCheckError("Cannot assign to immutable variable")
          }
      }
      LeftValue::{ kind: Ident(name), ty }
    }
    ArrayAccess(left_value, expr) => {
      let left_value = self.check_left_value(left_value)
      let expr = self.check_expr(expr)
      let kind = match left_value.ty.kind {
        Array(ty) => ty
        _ =>
          raise TypeCheckError("Cannot access array element of non-array type")
      }
      LeftValue::{
        kind: ArrayAccess(left_value, expr),
        ty: Type::{ kind, mutable: true },
      }
    }
    FieldAccess(left_value, name) => {
      let left_value = self.check_left_value(left_value)
      let ty = left_value.ty
      LeftValue::{ kind: FieldAccess(left_value, name), ty }
    }
  }
}

///|
fn Context::substitute_left_value(
  self : Context,
  left_value : LeftValue,
) -> LeftValue raise TypeCheckError {
  match left_value.kind {
    Ident(name) => {
      let ty = self.lookup_type(name).unwrap()
      LeftValue::{ kind: Ident(name), ty }
    }
    ArrayAccess(left_value, expr) => {
      let left_value = self.substitute_left_value(left_value)
      let expr = self.substitute_expr(expr)
      LeftValue::{ kind: ArrayAccess(left_value, expr), ty: left_value.ty }
    }
    FieldAccess(left_value, name) => {
      let left_value = self.substitute_left_value(left_value)
      LeftValue::{ kind: FieldAccess(left_value, name), ty: left_value.ty }
    }
  }
}
