/// ================================================================================
/// # 表达式的层级：Expr
///
/// 我们已经成功地将 `AtomExpr` 包装进了 `ApplyExpr`。现在，是时候引入我们语法树中
/// 最核心、最通用的节点之一：**`Expr`**。
///
/// ## 什么是 Expr？
///
/// `Expr`（表达式）是 MiniMoonBit 中能够产生一个值的几乎所有代码构造的统称。
/// 它是我们语法规则的“瑞士军刀”，涵盖了从最简单的数字到最复杂的逻辑块的所有内容。
///
/// `Expr` 主要包括以下几种形式：
///
/// 1.  **一元操作：** `-x` (取反), `!b` (逻辑非)
/// 2.  **二元操作：** `a + b`, `x > y`
/// 3.  **If 表达式：** `if condition { ... } else { ... }`
/// 4.  **Block 表达式：** `{ let a = 1; a + 1 }`
/// 5.  **以及我们刚刚实现的 `ApplyExpr`：** 它作为所有复杂表达式的基础。
///
/// ## 🎯 你的任务：实现最简单的 Expr
///
/// 在这个挑战中，我们将采用“由简入繁”的策略。我们首先要让 `parse_expr` 函数
/// 能够处理最基础的情况：一个单独的 `ApplyExpr`。
///
/// 请修改 `parser/expr.mbt` 文件中的 `parse_expr` 函数。
///
/// **实现思路：**
///
/// 1.  在 `parse_expr` 函数内部，直接调用我们已经完成的 `parse_apply_expr`。
/// 2.  成功解析出 `ApplyExpr` 后，用它来构造一个 `Expr` 节点。
///    （提示：`Expr` 的定义中有一个 `ApplyExpr(ApplyExpr)` 的构造器）。
/// 3.  暂时不需要考虑任何二元操作、一元操作或其他复杂情况。我们只处理一个 `ApplyExpr` 就直接返回。
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p parser -f parse_simple_expr_test.mbt
/// ```
///
/// 这个测试将确保你的 `parse_expr` 能够正确地将一个 `ApplyExpr` 包装成 `Expr`。
///
/// **祝你顺利！我们正在逐步构建起能够理解复杂代码逻辑的解析器！**
/// ================================================================================

///|
test "Simple Expr Parsing Test" {
  let code =
    #|42 3.14 true false
    #|a
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = parse_expr(tokens[:])
  assert_true(
    e.kind is ApplyExpr(a) && a.kind is AtomExpr(atom) && atom.kind is Int(42),
  )
  let (e, tok_view) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Double(3.14),
  )
  let (e, tok_view) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Bool(true),
  )
  let (e, tok_view) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Bool(false),
  )
  let (e, _) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("a"),
  )
}
