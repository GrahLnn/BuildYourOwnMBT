/// ================================================================================
/// # 类型检查表达式：ApplyExpr
///
/// 我们已经能够检查最基本的原子表达式了。现在，我们向上走一步，开始处理 `ApplyExpr`。
///
/// 在语法分析阶段，`ApplyExpr` 是一个复合概念，它以一个 `AtomExpr` 为基础，后面可以跟随一系列的函数调用 `()`、数组索引 `[]` 或字段访问 `.`。
///
/// 在类型检查阶段，我们也需要一个 `check_apply_expr` 函数来处理它。
///
/// ## 🎯 你的任务：实现 `check_apply_expr` 的基础情况
///
/// 你的任务是在 `typecheck/apply_expr.mbt` 文件中实现 `Context::check_apply_expr` 函数。
///
/// ### 💡 实现思路
///
/// 本次挑战的测试用例非常简单，只涉及 `ApplyExpr` 最基础的形式：即它仅仅是 `AtomExpr` 的一个包装。
///
/// 因此，你的 `check_apply_expr` 函数现在只需要处理 `parser::ApplyExprKind::AtomExpr` 这一种情况。
///
/// 1.  在 `check_apply_expr` 中，`match` 传入的 `apply_expr.kind`。
/// 2.  当它是 `AtomExpr(atom_expr)` 时，直接调用我们上一关实现的 `self.check_atom_expr(atom_expr)`。
/// 3.  `check_atom_expr` 会返回一个带类型的原子表达式。你需要用它来构建一个新的、带类型的 `typecheck::ApplyExpr`，并将其类型（`ty`）设置为刚刚返回的原子表达式的类型。
///
/// 我们将在后续挑战中逐步为 `check_apply_expr` 添加处理函数调用、数组访问等更复杂的能力。
///
/// ---
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p typecheck -f typecheck_simple_apply_expr_test.mbt
/// ```
///
/// 加油！我们正在稳步构建类型检查器的层次结构。
/// ================================================================================

///|
test "Simple Apply Expression Type Check" {
  let code =
    #|42 3.14 true "Hello" x y z
  let ctx = Context::new()
  ctx.type_env.set("x", { kind: TypeKind::Double, mutable: false })
  ctx.type_env.set("y", { kind: TypeKind::Bool, mutable: false })
  ctx.type_env.set("z", { kind: TypeKind::String, mutable: false })
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type of 42
  let (a, tok_view) = @parser.parse_apply_expr(tokens[:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Int)
  // Type of 3.14
  let (a, tok_view) = @parser.parse_apply_expr(tok_view)
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Double)
  // Type of true
  let (a, tok_view) = @parser.parse_apply_expr(tok_view)
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Bool)
  // Type of "Hello"
  let (a, tok_view) = @parser.parse_apply_expr(tok_view)
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is String)
  // Type of x
  let (a, tok_view) = @parser.parse_apply_expr(tok_view)
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Double)
  // Type of y
  let (a, tok_view) = @parser.parse_apply_expr(tok_view)
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Bool)
  // Type of z
  let (a, _) = @parser.parse_apply_expr(tok_view)
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is String)
}
