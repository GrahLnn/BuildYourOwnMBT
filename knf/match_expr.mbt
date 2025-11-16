///|
pub(all) struct KnfMatchArm {
  pattern : @typecheck.ArmPattern
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
  self : Context,
  arm : @typecheck.MatchArm,
  scr_ty : Type, // scrutinee 的 KNF 类型
  scr_expr : KnfExpr, // scrutinee 的 KNF 表达式
) -> KnfMatchArm raise KnfTransformError {
  let binders = Array::new()

  // 在这个 arm 的局部作用域内. 把模式中的名字注册到 Env
  self.enter_scope()
  self.bind_pattern_binders(arm.pattern, scr_ty, scr_expr, binders)
  let (body_stmts, body_expr) = self.expr_to_knf(arm.body)
  self.exit_scope()
  binders.append(body_stmts)
  KnfMatchArm::{ pattern: arm.pattern, binders, arm: body_expr }
}

///|
fn Context::bind_pattern_binders(
  self : Context,
  pat : @typecheck.ArmPattern,
  scr_ty : Type,
  scr_expr : KnfExpr,
  binders : Array[KnfStmt],
) -> Unit raise KnfTransformError {
  match pat.kind {
    // `_` 这种. 理论上可以完全不建 binder. 也可以给一个 dummy 变量.
    Wildcard =>
      // 可选. 当前结构里 KNF 没有用到 `_` 变量. 可以直接跳过不生成 binder
      ()

    // `x` 模式. 直接把 scr_expr 绑定到新名字上
    Ident(n) => {
      let name = self.add_new_name(n, scr_ty)
      binders.push(Let(name, scr_ty, scr_expr))
    }

    // `(p1, p2, ...)` 模式. 这里只做“包装”. 不拆 tuple. 真正的拆解留到 codegen.
    // 也就是说. 这里只要保证变量名都注册到 Env 就行.
    Tuple(sub_pats) =>
      // 当前不拆 tuple. 只给里边的 Ident 做 env 注册
      sub_pats.each(sp => self.bind_pattern_binders_shallow(sp, binders))

    // 常量模式. Bool/Int/Double. 不引入新变量. 也不在这里生成条件.
    Bool(_) | Int(_) | Double(_) =>
      // 完全留给 codegen 去根据 pattern 做比较
      ()

    // Enum 模式. 同样只负责变量名的 env 注册. 不做 tag 检查.
    Enum(_, _, field_pats_opt) =>
      match field_pats_opt {
        Some(field_pats) =>
          // 这里只负责把 RGB(r, g, b) 里 r g b 这些名字丢进 env
          field_pats.each(sp => self.bind_pattern_binders_shallow(sp, binders))
        None => ()
      }
  }
}

///|
fn Context::bind_pattern_binders_shallow(
  self : Context,
  pat : @typecheck.ArmPattern,
  binders : Array[KnfStmt],
) -> Unit raise KnfTransformError {
  match pat.kind {
    Wildcard => ()
    Ident(n) => {
      // 没有 scr_expr. 也就没真正的 RHS. 这里只注册名字进 Env. 方便后面 body 里的名字解析.
      // 这种做法意味着 body 里使用这些名字会 RE. 正常情况下应该有拆解逻辑.
      let tmp_ty = Type::Unit
      let name = self.add_new_name(n, tmp_ty)
      // 这里不生成 Let. 否则需要一个 KnfExpr 做 RHS
      let _ = name

    }
    Tuple(sub_pats) =>
      sub_pats.each(sp => self.bind_pattern_binders_shallow(sp, binders))
    Bool(_) | Int(_) | Double(_) | Enum(_, _, _) => ()
  }
}
