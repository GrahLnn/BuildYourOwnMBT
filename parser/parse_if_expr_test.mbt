/// ================================================================================
/// # 控制流：解析 if-else 表达式
///
/// 我们已经可以解析线性的语句流了。现在，让我们来为语言引入第一个真正的**控制流**结构：
/// **if-else 表达式**。
///
/// 在 MiniMoonBit 中，`if-else` 和代码块一样，也是一个表达式，它可以有返回值。
///
/// ## if-else 的 EBNF 范式
///
/// ```
/// if_expr ::= "if" expr block_expr ("else" (if_expr | block_expr))?
/// ```
///
/// 这段范式揭示了一个 `if-else` 结构最有趣的部分：
/// 1.  以 `if` 关键字开头，后跟一个条件 `expr` 和一个 `then` 分支的 `block_expr`。
/// 2.  `else` 部分是可选的。
/// 3.  如果存在 `else`，它后面可以跟着另一个 `if_expr`（这就构成了 `else if` 链），或者一个最终的 `block_expr`。
///
/// ## 🎯 你的任务：实现 `parse_if_expr`
///
/// 你的任务是在 `parser/if_expr.mbt` 中实现 `parse_if_expr` 函数。
///
/// **实现思路：**
///
/// 1.  解析 `if`、条件表达式和 `then` 代码块。这部分非常直接。
/// 2.  检查 `then` 块后面是否有 `else` 关键字。
/// 3.  如果有 `else`，你需要再次向后看一个 Token：
///     *   如果 `else` 后面跟着 `if`，那么这是一个 `else if`，你应该**递归地调用 `parse_if_expr`** 来解析这个链式结构。
///     *   如果 `else` 后面跟着 `{`，那么这是一个最终的 `else` 分支，你应该调用 `parse_block_expr` 来解析它。
///
/// ### 💡 数据结构提示：`Either`
///
/// `else` 分支既可能是 `if_expr`，也可能是 `block_expr`。如何在一个字段里表示这两种可能性呢？
///
/// MoonBit 标准库中的 `Either[A, B]` 类型是为此场景量身定做的。
/// 它可以存放两种类型的值之一：`Left(A)` 或 `Right(B)`。
///
/// 在 `if_expr.mbt` 中，`else_block` 字段的类型 `Either[IfExpr, BlockExpr]?` 就运用了这个思想，
/// 你可以利用它来优雅地存储 `else` 分支的两种可能性。
///
/// 相信这个挑战对你来说已经不难了。加油！
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_if_expr_test.mbt
/// ```
/// ================================================================================

///|
test "Parse If Expr Test" {
  let code =
    #|if a < b { return a; }
    #|if a < b { return a; } else { return b; }
    #|if a > b { a; } else if a == b { 0; } else { b; }
  let tokens = @lexer.tokenize(code)
  let (if_expr1, tok_view) = parse_if_expr(tokens[:])
  assert_true(if_expr1.then_block.stmts.length() is 1)
  assert_true(if_expr1.else_block is None)
  let (if_expr2, tok_view) = parse_if_expr(tok_view)
  assert_true(if_expr2.then_block.stmts.length() is 1)
  assert_true(if_expr2.else_block is Some(else_block) && else_block is Right(_))
  let (if_expr3, _) = parse_if_expr(tok_view)
  assert_true(if_expr3.then_block.stmts.length() is 1)
  assert_true(
    if_expr3.else_block is Some(else_block) &&
    else_block is Left(else_if) &&
    else_if.then_block.stmts.length() is 1 &&
    else_if.else_block is Some(else_block2) &&
    else_block2 is Right(_),
  )
}
