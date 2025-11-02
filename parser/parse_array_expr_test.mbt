/// ================================================================================
/// # 方括号的集结：解析数组字面量
///
/// 我们已经成功处理了圆括号 `()` 的多种情况。现在，让我们来挑战另一种常见的括号：
/// 方括号 `[]`，它在 MiniMoonBit 中用于定义**数组字面量（Array Literals）**。
///
/// ## 数组字面量
///
/// 数组字面量允许我们直接在代码中定义一个包含多个元素的数组，例如：
/// `[1, 2, 3]` 或 `["hello", "world"]`。
///
/// 它的结构与我们之前解析的元组（Tuple）非常相似：由一对括号包裹，内部是逗号分隔的表达式列表。
///
/// ## 🎯 你的任务：在 `parse_atom_expr` 中处理 `[]`
///
/// 我们的目标是在 `atom_expr.mbt` 中，通过一个新的辅助函数 `parse_array_expr`
/// 来实现对数组字面量的解析。`parse_atom_expr` 将在遇到 `[` 时调用这个新函数。
///
/// **实现思路：**
///
/// 好消息是，这部分逻辑与我们之前实现的 `parse_paren_expr` 高度相似！
///
/// 1.  **入口：** 当 `parse_atom_expr` 遇到 `[` 时，它应该将解析工作委托给 `parse_array_expr`。
///
/// 2.  **`parse_array_expr` 的逻辑：**
///     *   首先，跳过开头的 `[`。
///     *   进入一个循环，用 `parse_expr` 解析由逗号分隔的表达式列表。
///     *   循环直到遇到结尾的 `]`。
///     *   将所有解析出的 `Expr` 收集到一个 `Array` 中。
///     *   使用这个 `Array[Expr]` 来构造一个 `AtomExprKind::Array` 节点。
///
/// ## 🤔 深入思考：逗号的艺术
///
/// 既然数组和元组的解析如此相似，那么关于逗号的边界情况也值得我们再次思考。
/// 对于一个健壮且用户友好的语言来说，以下情况是否应该被接受？
///
/// *   **尾随逗号：** `[1, 2, 3,]`
/// *   **开头逗号：** `[, 1, 2, 3]`
/// *   **连续逗号：** `[1, , 2, 3]`
/// *   **多个尾随逗号：** `[1, 2, 3, ,]`
///
/// 你的 `parse_paren_expr` 的实现可能已经处理了其中一部分情况。
/// 在实现 `parse_array_expr` 时，你可以考虑是否需要一个更通用的、可以被两者复用的列表解析函数，
/// 以确保语言在不同语法结构中行为的一致性。
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p parser -f parse_array_expr_test.mbt
/// ```
///
/// **祝你顺利！通过代码复用，我们可以让编译器变得更加优雅和健壮。**
/// ================================================================================

///|
test "Array Expr Parsing Test" {
  let code =
    #|[42, 3.14, true]
    #|[foo, bar, baz]
    #|[ 1 + 3]
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_atom_expr(tokens[:])
  assert_true(
    a.kind is AtomExprKind::Array(exprs) &&
    exprs is [e1, e2, e3] &&
    e1.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(42) &&
    e2.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Double(3.14) &&
    e3.kind is ApplyExpr(app3) &&
    app3.kind is AtomExpr(atom3) &&
    atom3.kind is Bool(true),
  )
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is AtomExprKind::Array(exprs) &&
    exprs is [e1, e2, e3] &&
    e1.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Ident("foo") &&
    e2.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Ident("bar") &&
    e3.kind is ApplyExpr(app3) &&
    app3.kind is AtomExpr(atom3) &&
    atom3.kind is Ident("baz"),
  )
  let (a, _) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is AtomExprKind::Array(exprs) &&
    exprs is [e1] &&
    e1.kind is BinaryExpr(Add, left, right) &&
    left.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    right.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(3),
  )
}
