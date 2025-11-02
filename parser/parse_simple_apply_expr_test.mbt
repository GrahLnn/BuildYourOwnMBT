/// ================================================================================
/// # 表达式的组合：ApplyExpr
///
/// 恭喜你，我们已经可以解析最基础的原子表达式（AtomExpr）了。
/// 现在，让我们进入一个更广阔的世界：**ApplyExpr**。
///
/// ## 什么是 ApplyExpr？
///
/// 在我们的 MiniMoonBit 语言中，`ApplyExpr` 是一个复合概念，它代表了可以被“应用”或“访问”的表达式。
/// 它包括了以下几种情况：
///
/// 1.  **函数调用：** `my_function(arg1, arg2)`
/// 2.  **数组索引：** `my_array[index]`
/// 3.  **结构体字段访问：** `my_struct.field`
/// 4.  **以及最基础的原子表达式（AtomExpr）：** `42`, `my_variable` 等
///
/// 可以看到，`ApplyExpr` 的核心是一个基础表达式（AtomExpr），后面可以跟上一系列的调用、索引或字段访问。
///
/// ## 🎯 你的任务：实现最简单的 ApplyExpr
///
/// 在这一步，我们先不处理复杂的函数调用和字段访问。
/// 我们的目标是实现 `ApplyExpr` 的最简形式：**一个只包含 `AtomExpr` 的 `ApplyExpr`**。
///
/// 请修改 `parser/apply_expr.mbt` 文件中的 `parse_apply_expr` 函数。
///
/// **实现思路：**
///
/// 1.  在 `parse_apply_expr` 函数内部，首先调用我们已经完成的 `parse_atom_expr` 来解析一个原子表达式。
/// 2.  成功解析出 `AtomExpr` 后，直接用它来构造一个 `ApplyExpr` 节点。
///    （提示：`ApplyExpr` 的定义中有一个 `AtomExpr(AtomExpr)` 的构造器）。
/// 3.  暂时不需要处理 `(`, `[` 或 `.` 等 Token，我们会在后续的挑战中逐步完善它。
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p parser -f parse_simple_apply_expr_test.mbt
/// ```
///
/// 这个测试将验证你的 `parse_apply_expr` 是否能正确地将一个原子表达式包装成 `ApplyExpr`。
///
/// **祝你顺利！这是我们向更复杂的表达式解析迈出的重要一步！**
/// ================================================================================

///|
test "Parse Simple Apply Expr Test" {
  let code =
    #|42 3.14 true false
    #|foo bar
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Int(42))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Double(3.14))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Bool(true))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Bool(false))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Ident("foo"))
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Ident("bar"))
}
