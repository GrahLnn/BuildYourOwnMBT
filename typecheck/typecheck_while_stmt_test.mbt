/// ================================================================================
/// # 类型检查控制流：while 循环
///
/// `while` 是我们语言中唯一的循环结构。与 `if-else` 不同，`while` 循环本身不产生值，因此它的类型检查要简单得多。
///
/// ## 🎯 你的任务：实现 `check_while_stmt`
///
/// 你的任务是在 `typecheck/while_stmt.mbt` 文件中实现 `Context::check_while_stmt` 函数。
///
/// ### 💡 实现思路
///
/// 1.  **检查条件：**
///     *   `while` 后面的条件表达式必须是 `Bool` 类型。你需要调用 `check_expr` 检查该条件。
///
/// 2.  **检查循环体：**
///     *   调用 `check_block_expr` 来检查循环体的代码块。
///     *   由于 `while` 循环不产生值，循环体块的类型可以被忽略。
///
/// 3.  **`while` 语句的类型：**
///     *   `while` 语句本身的类型永远是 `Unit`。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_while_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "While Stmt TypeCheck Test" {
  let code =
    #|let mut i = 0;
    #|while i < 10 {
    #|  i += 1;
    #|}
  let ctx = Context::new()
  // Parse
  let tokens = @lexer.tokenize(code)
  let (let_stmt, tok_view) = @parser.parse_let_mut_stmt(tokens[:])
  let _ = ctx.check_let_mut_stmt(let_stmt)
  let (while_stmt, _) = @parser.parse_while_stmt(tok_view)
  let _ = ctx.check_while_stmt(while_stmt)

}
