///|
pub(all) struct Expr {
  kind : ExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
} derive(Show)

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Show, Eq)

///|
pub fn binop_is_cmp(bin_op : BinaryOp) -> Bool {
  match bin_op {
    Eq => true
    NE => true
    LT => true
    GT => true
    LE => true
    GE => true
    _ => false
  }
}

///|
pub fn binop_is_bitwise(bin_op : BinaryOp) -> Bool {
  bin_op is (BitAnd | BitOr)
}

///|
pub fn binop_is_arithmetic(bin_op : BinaryOp) -> Bool {
  match bin_op {
    Add => true
    Sub => true
    Mul => true
    Div => true
    Mod => true
    _ => false
  }
}

///|
pub fn parser_binop_to_typecheck_binop(
  tok_bin_op : @parser.BinaryOp,
) -> BinaryOp {
  match tok_bin_op {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Mod => Mod
    ShiftLeft => ShiftLeft
    ShiftRight => ShiftRight
    Eq => Eq
    NE => NE
    LT => LT
    GT => GT
    LE => LE
    GE => GE
    And => And
    Or => Or
    BitAnd => BitAnd
    BitOr => BitOr
  }
}

///|
pub fn Context::has_ident(self : Self, expr : Expr) -> String? {
  match expr.kind {
    ApplyExpr(e) =>
      match e.kind {
        AtomExpr(e) =>
          match e.kind {
            Ident(name) => Some(name)
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
pub fn Context::check_expr(
  self : Self,
  expr : @parser.Expr,
) -> Expr raise TypeCheckError {
  match expr.kind {
    ApplyExpr(apply_expr) => {
      let expr = self.check_apply_expr(apply_expr)
      Expr::{ kind: ApplyExpr(expr), ty: expr.ty }
    }
    NotExpr(inner_expr) => {
      let expr = self.check_expr(inner_expr)
      guard expr.ty is Bool else {
        raise TypeCheckError(
          "! can only be paired with Boolean-type statements. ",
        )
      }
      Expr::{ kind: NotExpr(expr), ty: Bool }
    }
    NegExpr(inner_expr) => {
      let expr = self.check_expr(inner_expr)
      guard expr.ty is Int || expr.ty is Double else {
        raise TypeCheckError(
          "- can only be paired with integer and double-type statements. ",
        )
      }
      Expr::{ kind: NegExpr(expr), ty: expr.ty }
    }
    BinaryExpr(op, left, right) => {
      let lexpr = self.check_expr(left)
      let rexpr = self.check_expr(right)
      guard self.is_type_compatible(lexpr.ty, rexpr.ty) else {
        raise TypeCheckError("The types on both sides must be identical.")
      }
      match op {
        Add | Sub | Mul | Div | Mod => {
          guard lexpr.ty is Int || lexpr.ty is Double else {
            raise TypeCheckError(
              "Arithmetic operations are only allowed on integers and doubles.",
            )
          }
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: lexpr.ty,
          }
        }
        Eq | NE => {
          guard lexpr.ty is Int || lexpr.ty is Double || lexpr.ty is Bool else {
            raise TypeCheckError(
              "Comparison operations are only allowed on integers, doubles, and booleans.",
            )
          }
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Bool,
          }
        }
        LT | GT | LE | GE => {
          guard lexpr.ty is Int || lexpr.ty is Double else {
            raise TypeCheckError(
              "Comparison operations are only allowed on integers and doubles.",
            )
          }
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Bool,
          }
        }
        And | Or => {
          guard lexpr.ty is Bool && rexpr.ty is Bool else {
            raise TypeCheckError(
              "Logical operations are only allowed on boolean-type statements.",
            )
          }
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Bool,
          }
        }
        BitAnd | BitOr => {
          guard lexpr.ty is Int && rexpr.ty is Int else {
            raise TypeCheckError(
              "Bitwise operations are only allowed on integer-type statements.",
            )
          }
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Int,
          }
        }
        _ => raise TypeCheckError("check_expr not implemented")
      }
    }
    _ => raise TypeCheckError("check_expr not implemented")
  }
}
