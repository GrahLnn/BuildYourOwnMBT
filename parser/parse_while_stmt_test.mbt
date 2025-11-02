/// ================================================================================
/// # 循环的力量：解析 while 语句
///
/// 我们已经有了 `if-else` 作为分支结构，现在让我们来添加 MiniMoonBit 中唯一的循环结构：
/// **`while` 语句**。
///
/// `while` 语句允许我们根据一个条件重复地执行一个代码块。
///
/// ## `while` 语句的 EBNF 范式
///
/// `while` 语句的结构非常简单明了：
///
/// ```
/// while_stmt ::= "while" expr block_expr
/// ```
///
/// 它由 `while` 关键字、一个条件表达式和一个循环体代码块组成。
///
/// ## 🎯 你的任务：实现 `parse_while_stmt`
///
/// 你的任务是在 `parser/while_stmt.mbt` 中实现 `parse_while_stmt` 函数。
///
/// 这个解析任务非常直接：
/// 1.  匹配 `while` 关键字。
/// 2.  调用 `parse_expr` 解析条件表达式。
/// 3.  调用 `parse_block_expr` 解析循环体。
///
/// 相信这对你来说已经轻而易举了。加油！
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_while_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "Parse While Stmt Test" {
  let code =
    #|while a < b { a += 1; b -=2; }
    #|while a < b { println(a); a += b % 3; } 
  let tokens = @lexer.tokenize(code)
  let (while_stmt1, tok_view) = parse_while_stmt(tokens[:])
  assert_true(while_stmt1.body.stmts.length() is 2)
  let (while_stmt2, _) = parse_while_stmt(tok_view)
  assert_true(while_stmt2.body.stmts.length() is 2)
}
