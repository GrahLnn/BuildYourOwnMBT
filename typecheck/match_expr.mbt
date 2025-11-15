///|
pub(all) struct MatchExpr {
  expr : Expr
  arms : Array[MatchArm]
  ty : TypeKind
} derive(Show)

///|
pub(all) struct MatchArm {
  pattern : ArmPattern
  body : Expr
} derive(Show)

///|
pub(all) struct ArmPattern {
  kind : ArmPatternKind
} derive(Show, Eq)

///|
pub(all) enum ArmPatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[ArmPattern])
  Bool(Bool)
  Enum(String?, String, Array[ArmPattern]?)
  Int(Int)
  Double(Double)
} derive(Show, Eq)

///|
fn ap(kind : ArmPatternKind) -> ArmPattern {
  ArmPattern::{ kind, }
}

///|
fn arm_pattern_into(pattern : @parser.ArmPattern) -> ArmPattern {
  match pattern.kind {
    Wildcard => ap(Wildcard)
    Ident(name) => ap(Ident(name))
    Tuple(patterns) => ap(Tuple(patterns.map(arm_pattern_into)))
    Bool(v) => ap(Bool(v))
    Enum(a, b, c) => {
      let c = match c {
        Some(v) => Some(v.map(arm_pattern_into))
        None => None
      }
      ap(Enum(a, b, c))
    }
    Int(v) => ap(Int(v))
    Double(v) => ap(Double(v))
  }
}

///|
pub fn Context::check_match_expr(
  self : Self,
  match_expr : @parser.MatchExpr,
) -> MatchExpr raise TypeCheckError {
  let expr = self.check_expr(match_expr.expr)
  let arms = match_expr.arms.map(arm => MatchArm::{
    pattern: arm_pattern_into(arm.pattern),
    body: self.check_expr(arm.body),
  })
  let arms_ty = arms.map(arm => arm.body.ty)
  arms_ty.each(ty => {
    guard self.is_type_compatible(ty, arms_ty[0]) else {
      raise TypeCheckError("All arms must have the same type")
    }
  })
  let ty = arms_ty[0]
  MatchExpr::{ expr, arms, ty }
}

///|
pub fn Context::substitute_match_expr(
  self : Self,
  match_expr : MatchExpr,
) -> MatchExpr raise TypeCheckError {
  MatchExpr::{
    expr: self.substitute_expr(match_expr.expr),
    arms: match_expr.arms.map(arm => MatchArm::{
      pattern: arm.pattern,
      body: self.substitute_expr(arm.body),
    }),
    ty: match_expr.ty,
  }
}
