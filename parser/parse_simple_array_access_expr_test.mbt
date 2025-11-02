/// ================================================================================
/// # ApplyExpr 的扩展：数组索引
///
/// 我们已经为 `ApplyExpr` 实现了一个最基础的功能：包装一个 `AtomExpr`。
/// 现在，是时候为它添加真正的“应用”能力了，我们从**数组索引（Array Access）**开始。
///
/// ## 数组索引语法
///
/// 数组索引的语法非常直观：`array_variable[index_expression]`。
/// 这里的 `array_variable` 是一个 `ApplyExpr`（在最简单的情况下，是一个 `AtomExpr`），
/// 而 `index_expression` 是一个完整的 `Expr`。
///
/// ## 🎯 你的任务：在 `parse_apply_expr` 中处理 `[...]`
///
/// 我们的目标是扩展 `parser/apply_expr.mbt` 中的 `parse_apply_expr` 函数，
/// 使其能够在解析完一个 `AtomExpr` 后，继续检查并解析紧随其后的数组索引操作。
///
/// **实现思路：**
///
/// 1.  **解析基础：** 函数首先像之前一样，调用 `parse_atom_expr` 解析出一个基础的 `AtomExpr`，并将其包装成一个 `ApplyExpr`。
///
/// 2.  **向后看：** 解析完基础表达式后，不要立即返回！你需要检查**下一个** Token。
///
/// 3.  **匹配 `[`：**
///     *   如果下一个 Token 是 `[`，那么说明一个数组索引操作开始了。
///     *   跳过 `[`。
///     *   调用我们强大的 `parse_expr` 函数来解析括号内的索引表达式。
///     *   确保索引表达式后面紧跟着一个 `]`，并跳过它。
///     *   现在，你拥有了“被索引的数组”（就是你第一步解析出的那个 `ApplyExpr`）和“索引值”（你刚刚解析出的 `Expr`）。
///       用它们来创建一个新的、类型为 `ArrayAccess` 的 `ApplyExpr`。这个新的 `ApplyExpr` 会将旧的 `ApplyExpr` 包裹在内。
///
/// 4.  **不匹配：** 如果下一个 Token 不是 `[`，那么说明没有数组索引操作，直接返回第一步解析出的 `ApplyExpr` 即可。
///
/// ## 🤔 深入思考：链式调用 `arr[1][2]`
///
/// 这个挑战的测试用例包含 `matrix[3][4]` 这样的链式索引。
/// 如果你的实现是正确的，它应该能自然地处理这种情况。
///
/// 思考一下，为什么一个循环结构（`loop` 或 `while`）会是处理这种链式调用的优雅方式？
/// 当你解析完 `arr[1]` 后，你应该如何处理下一个 `[2]`？
/// 新生成的 `ApplyExpr` 和上一轮的 `ApplyExpr` 之间是什么关系？
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p parser -f parse_simple_array_access_expr_test.mbt
/// ```
///
/// **祝你顺利！你正在构建一个能够理解表达式组合的解析器！**
/// ================================================================================

///|
test "Simple Array Access Parsing Test" {
  let code =
    #|arr[42]
    #|matrix[3][4]
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(
    a.kind is ApplyExprKind::ArrayAccess(arr_access, index_expr) &&
    index_expr.kind is ApplyExpr(app_index) &&
    app_index.kind is AtomExpr(atom_index) &&
    atom_index.kind is Int(42) &&
    arr_access.kind is ApplyExprKind::AtomExpr(atom_arr) &&
    atom_arr.kind is AtomExprKind::Ident("arr"),
  )
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::ArrayAccess(arr_access2, index_expr2) &&
    index_expr2.kind is ApplyExpr(app_index2) &&
    app_index2.kind is AtomExpr(atom_index2) &&
    atom_index2.kind is Int(4) &&
    arr_access2.kind is ApplyExprKind::ArrayAccess(arr_access1, index_expr1) &&
    index_expr1.kind is ApplyExpr(app_index1) &&
    app_index1.kind is AtomExpr(atom_index1) &&
    atom_index1.kind is Int(3) &&
    arr_access1.kind is ApplyExprKind::AtomExpr(atom_arr) &&
    atom_arr.kind is AtomExprKind::Ident("matrix"),
  )
}
