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
fn Context::bind_arm_pattern_type(
  self : Self,
  pattern : ArmPattern,
  scr_ty : TypeKind,
) -> Unit raise TypeCheckError {
  match pattern.kind {
    Wildcard => ()
    Ident(name) => self.push_type(name, scr_ty, false)
    Tuple(patterns) =>
      match scr_ty {
        Tuple(ts) => {
          guard ts.length() == patterns.length() else {
            raise TypeCheckError("Pattern and type mismatch")
          }
          patterns.eachi((idx, pat) => self.bind_arm_pattern_type(pat, ts[idx]))
        }
        _ => raise TypeCheckError("Tuple pattern on non-tuple type")
      }
    Bool(_) => {
      guard self.is_type_compatible(scr_ty, Bool) else {
        raise TypeCheckError("Bool pattern on non-bool scrutinee")
      }
    }
    Int(_) => {
      guard self.is_type_compatible(scr_ty, Int) else {
        raise TypeCheckError("Int pattern on non-int scrutinee")
      }
    }
    Double(_) => {
      guard self.is_type_compatible(scr_ty, Double) else {
        raise TypeCheckError("Double pattern on non-double scrutinee")
      }
    }
    Enum(_, _, field_pats_opt) => {
      let field_pats = match field_pats_opt {
        Some(ps) => ps
        None => []
      }
      // 为每个字段创建独立的类型变量, 具体类型由后续统一过程决定
      field_pats.each(pat => self.bind_arm_pattern_type(pat, self.tyvar()))
    }
  }
}

///|
pub fn Context::check_match_expr(
  self : Self,
  match_expr : @parser.MatchExpr,
) -> MatchExpr raise TypeCheckError {
  let expr = self.check_expr(match_expr.expr)
  let scr_ty = expr.ty
  let arms = match_expr.arms.map(arm => {
    let pat = arm_pattern_into(arm.pattern)
    self.enter_scope()
    self.bind_arm_pattern_type(pat, scr_ty)
    let body = self.check_expr(arm.body)
    self.exit_scope()
    MatchArm::{ pattern: pat, body }
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
