///|
pub(all) struct KnfMatchArm {
  binders : Array[KnfStmt]
  arm : KnfExpr
}

///|
pub fn KnfMatchArm::to_string(self : Self, ident : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string("\n")
  sb.write_string(
    self.binders.map(stmt => stmt.to_string(ident=ident + 2)).join(";"),
  )
  sb.write_string("\n")
  sb.write_string(self.arm.to_string())
  sb.to_string()
}

///|
pub fn Context::match_expr_to_knf(
  self : Context,
  match_expr : @typecheck.MatchExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  let expr_ty = self.typekind_to_knf(match_expr.ty)
  let (stmts, expr) = self.expr_to_knf(match_expr.expr)
  let arms = Array::new()
  match_expr.arms.each(arm => arms.push(
    self.match_arm_to_knf(arm, expr_ty, expr),
  ))
  (stmts, Match(expr, arms))
}

///|
pub fn Context::match_arm_to_knf(
  self : Self,
  arm : @typecheck.MatchArm,
  ty : Type,
  expr : KnfExpr,
) -> KnfMatchArm raise KnfTransformError {
  let binders = Array::new()
  match arm.pattern.kind {
    Wildcard => {
      let name = Name::wildcard()
      binders.push(Let(name, ty, expr))
    }
    Ident(n) => {
      let name = self.add_new_name(n, ty)
      binders.push(Let(name, ty, expr))
    }
    // Tuple(patterns) => {
    //   patterns.each(pattern => {
    //     match pattern.kind {
    //       Wildcard => {
    //         let name = Name::wildcard()
    //         binders.push(Let(name, ty, expr))
    //       }
    //       Ident(n) => {
    //         let name = self.add_new_name(n, ty)
    //         binders.push(Let(name, ty, expr))
    //       }
    //     }
    //   })
    // }
    Bool(v) => {
      let name = self.add_temp(Bool)
      binders.push(Let(name, Bool, Bool(v)))
    }
    Int(n) => {
      let name = self.add_temp(Int)
      binders.push(Let(name, Int, Int(n)))
    }
    Double(n) => {
      let name = self.add_temp(Double)
      binders.push(Let(name, Double, Double(n)))
    }
    _ => raise KnfTransformError("match not impl for \{arm.pattern.kind}")
  }
  let (stmts, arm) = self.expr_to_knf(arm.body)
  binders.append(stmts)
  KnfMatchArm::{ binders, arm }
}
