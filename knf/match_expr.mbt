///|
pub(all) struct KnfMatchArm {
  pattern : @typecheck.ArmPattern
  binders : Array[KnfStmt]
  arm : KnfExpr
}

///|
pub fn KnfMatchArm::to_string(self : Self, ident : Int) -> String {
  let sb = StringBuilder::new()
  // 先打印 pattern
  sb.write_string(self.pattern.kind.to_string())
  sb.write_string(" => {")
  sb.write_string("\n")
  // 再打印 binders
  sb.write_string(
    self.binders.map(stmt => stmt.to_string(ident=ident + 2)).join("\n"),
  )
  sb.write_string("\n")
  // 最后打印 arm 表达式
  sb.write_string(self.arm.to_string())
  sb.write_string("\n}")
  sb.to_string()
}

///|
pub fn Context::match_expr_to_knf(
  self : Context,
  match_expr : @typecheck.MatchExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  // scrutinee 的 KNF 类型来自 match_expr.expr.ty，而不是整个 match 的返回类型
  let scr_ty = self.typekind_to_knf(match_expr.expr.ty)
  let (stmts, expr) = self.expr_to_knf(match_expr.expr)
  let arms = Array::new()
  match_expr.arms.each(arm => arms.push(
    self.match_arm_to_knf(arm, scr_ty, expr),
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
    // `_` 模式. 不引入名字, 也不需要绑定 scr_expr.
    Wildcard => ()

    // `x` 模式. 把 scr_expr 作为真实 RHS 绑定到新名字上.
    Ident(n) => {
      let name = self.add_new_name(n, scr_ty)
      binders.push(Let(name, scr_ty, scr_expr))
    }

    // `(p1, p2, ...)` 模式. 在 KNF 里显式做 tuple 投影, 为子模式递归生成绑定.
    Tuple(sub_pats) => {
      guard scr_ty is Tuple(elem_tys) else {
        raise KnfTransformError("Tuple pattern on non-tuple type: \{scr_ty}")
      }
      // 先把 scr_expr 绑定到一个临时名字, 避免重复使用复杂表达式.
      let tmp = self.add_temp(scr_ty)
      binders.push(Let(tmp, scr_ty, scr_expr))
      sub_pats.eachi((i, sp) => {
        let elem_ty = elem_tys[i]
        let elem_expr = TupleAccess(tmp, i)
        self.bind_pattern_binders(sp, elem_ty, elem_expr, binders)
      })
    }

    // 常量模式. Bool/Int/Double 只参与后续 codegen 的比较, 这里不引入任何绑定.
    Bool(_) | Int(_) | Double(_) => ()

    // Enum 模式. 为 enum 整体和 payload 字段生成投影绑定.
    Enum(enum_name_opt, variant_name, field_pats_opt) =>
      match field_pats_opt {
        None => {
          // 零字段变体: 仍然为整个 enum 绑定一个 tmp, 方便后续 codegen 获取类型信息.
          let tmp = self.add_temp(scr_ty)
          binders.push(Let(tmp, scr_ty, scr_expr))
        }
        Some(field_pats) => {
          let (field_tys, variant_index) = self.lookup_enum_variant_field_types(
            scr_ty, enum_name_opt, variant_name,
          )

          // 先绑定整个 enum 值到一个 tmp 名字
          let tmp = self.add_temp(scr_ty)
          binders.push(Let(tmp, scr_ty, scr_expr))

          // 为每个字段生成 EnumPayload 投影, 再递归绑定子模式
          field_pats.eachi((i, sp) => {
            let field_ty = field_tys[i]
            let field_expr = EnumPayload(tmp, variant_index, i)
            self.bind_pattern_binders(sp, field_ty, field_expr, binders)
          })
        }
      }
  }
}
