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
    IfExpr(if_expr) => {
      let expr = self.check_if_expr(if_expr)
      Expr::{ kind: IfExpr(expr), ty: expr.ty }
    }
    BlockExpr(block_expr) => {
      let expr = self.check_block_expr(block_expr)
      Expr::{ kind: BlockExpr(expr), ty: expr.ty }
    }
    NotExpr(inner_expr) => {
      let expr = self.check_expr(inner_expr)
      guard expr.ty is Bool else {
        raise TypeCheckError(
          "! can only be paired with Boolean-type statements. Found \{expr.ty}",
        )
      }
      Expr::{ kind: NotExpr(expr), ty: Bool }
    }
    NegExpr(inner_expr) => {
      let expr = self.check_expr(inner_expr)
      guard expr.ty is Int || expr.ty is Double else {
        raise TypeCheckError(
          "- can only be paired with integer and double-type statements. Found \{expr.ty}",
        )
      }
      Expr::{ kind: NegExpr(expr), ty: expr.ty }
    }
    BinaryExpr(op, left, right) => {
      let lexpr = self.check_expr(left)
      let rexpr = self.check_expr(right)
      guard self.is_type_compatible(lexpr.ty, rexpr.ty) else {
        raise TypeCheckError(
          "The types on both sides must be identical. Found \{lexpr.ty} and \{rexpr.ty}",
        )
      }
      match op {
        Add | Sub | Mul | Div | Mod =>
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: lexpr.ty,
          }
        Eq | NE =>
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Bool,
          }
        LT | GT | LE | GE =>
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Bool,
          }
        And | Or =>
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Bool,
          }
        BitAnd | BitOr =>
          Expr::{
            kind: BinaryExpr(parser_binop_to_typecheck_binop(op), lexpr, rexpr),
            ty: Int,
          }
        _ => raise TypeCheckError("check BinaryOp \{op} not implemented")
      }
    }
  }
}

///|
fn Context::substitute_expr(
  self : Context,
  expr : Expr,
) -> Expr raise TypeCheckError {
  match expr.kind {
    ApplyExpr(apply_expr) => {
      let expr = self.substitute_apply_expr(apply_expr)
      Expr::{ kind: ApplyExpr(expr), ty: self.analysis_type(expr.ty) }
    }
    IfExpr(if_expr) => {
      let expr = self.substitute_if_expr(if_expr)
      Expr::{ kind: IfExpr(expr), ty: self.analysis_type(expr.ty) }
    }
    BlockExpr(block_expr) => {
      let expr = self.substitute_block_expr(block_expr)
      Expr::{ kind: BlockExpr(expr), ty: self.analysis_type(expr.ty) }
    }
    NotExpr(inner_expr) => {
      let expr = self.substitute_expr(inner_expr)
      Expr::{ kind: NotExpr(expr), ty: Bool }
    }
    NegExpr(inner_expr) => {
      let expr = self.substitute_expr(inner_expr)
      Expr::{ kind: NegExpr(expr), ty: self.analysis_type(expr.ty) }
    }
    BinaryExpr(op, left, right) => {
      let lexpr = self.substitute_expr(left)
      let rexpr = self.substitute_expr(right)
      match op {
        Add | Sub | Mul | Div | Mod =>
          Expr::{ kind: BinaryExpr(op, lexpr, rexpr), ty: lexpr.ty }
        Eq | NE => Expr::{ kind: BinaryExpr(op, lexpr, rexpr), ty: Bool }
        LT | GT | LE | GE =>
          Expr::{ kind: BinaryExpr(op, lexpr, rexpr), ty: Bool }
        And | Or => Expr::{ kind: BinaryExpr(op, lexpr, rexpr), ty: Bool }
        BitAnd | BitOr => Expr::{ kind: BinaryExpr(op, lexpr, rexpr), ty: Int }
        _ => expr
      }
    }
  }
}
