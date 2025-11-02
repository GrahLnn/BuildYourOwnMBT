/// ================================================================================
/// # 类型检查语句和代码块
///
/// 我们已经可以独立地检查各种语句了。现在，我们需要一个“总指挥”来调度它们，并处理语句的集合——代码块（Block）。
///
/// ## 🎯 你的第一个任务：实现 `check_stmt`
///
/// 你的第一个任务是在 `typecheck/stmt.mbt` 文件中实现 `Context::check_stmt` 函数。
/// 这个函数将作为一个分发器（Dispatcher）。
///
/// ### 💡 `check_stmt` 实现思路
///
/// `match` 传入的 `stmt.kind`，然后调用我们已经实现的相应的检查函数：
/// *   `LetStmt(...)` -> `check_let_stmt(...)`
/// *   `LetMutStmt(...)` -> `check_let_mut_stmt(...)`
/// *   `AssignStmt(...)` -> `check_assign_stmt(...)`
/// *   `ExprStmt(expr)` -> `check_expr(expr)`
/// *   ...等等
///
/// ### ⭐ 特别关注：`ReturnStmt`
///
/// 在处理 `ReturnStmt` 时，我们需要回答一个关键问题：如何知道 `return` 语句的类型是否正确？
///
/// > 我们必须将 `return` 后面表达式的类型与**当前函数签名中声明的返回类型**进行比较。
///
/// 这个“当前函数的返回类型”信息就存放在 `Context` 中。我们约定使用 `current_func_ret_ty: Option[TypeKind]` 字段来记录它。
///
/// *   当检查 `ReturnStmt(Some(expr))` 时，你需要检查 `expr` 的类型是否与 `self.current_func_ret_ty` 兼容。
/// *   当检查 `ReturnStmt(None)` 时（即 `return;`），你需要检查 `self.current_func_ret_ty` 是否为 `Unit`。
/// *   如果 `self.current_func_ret_ty` 是 `None`，说明 `return` 语句出现在了函数之外，应该抛出错误。
///
/// ## 🎯 你的第二个任务：实现 `check_block_expr`
///
/// 完成了 `check_stmt` 后，你需要在 `typecheck/block_expr.mbt` 中实现 `check_block_expr`。
///
/// ### 💡 `check_block_expr` 实现思路
///
/// 1.  **处理作用域（Scoping）：**
///     *   代码块 `{...}` 会创建一个新的作用域。在块内定义的变量不应该“泄露”到外部。
///     *   在开始检查块内语句**之前**，调用 `self.enter_scope()` 来创建一个新的变量环境。
///     *   在所有语句检查完成**之后**，必须调用 `self.exit_scope()` 来销毁这个环境，恢复到上一层。
///
/// 2.  **遍历语句：**
///     *   遍历块内的每一条语句，调用你刚刚完成的 `self.check_stmt` 来检查它。
///
/// 3.  **确定块的类型：**
///     *   代码块本身也是一个表达式，它有自己的类型。
///     *   规则是：块的类型就是**最后一条表达式语句的类型**。
///     *   如果代码块为空，或者最后一条语句以分号结尾（即不是表达式语句），那么整个块的类型就是 `Unit`。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_block_expr_test.mbt
/// ```
/// ================================================================================

///|
test "Block Expr TypeCheck Test" {
  let code =
    #|let arr = [];
    #|
    #|{
    #|  let (x, y) = (1, 2);
    #|  let mut z = x + y;
    #|  z += 10;
    #|  arr.push(z);
    #|}
    #|
    #|{
    #|  let (x, y) = (1.0, 2.0);
    #|  let z = x * y;
    #|  let arr = [1.0, z, 5.0];
    #|  arr[2] = arr[1];
    #|  arr[2]
    #|}
    #|
    #|{ arr[0] = 1.0; } // should cause type error
  let ctx = Context::new()
  // Parse
  let tokens = @lexer.tokenize(code)
  let (let_stmt, tok_view) = @parser.parse_let_stmt(tokens[:])
  let _ = ctx.check_let_stmt(let_stmt)
  // TypeCheck first block expr
  let (block_expr1, tok_view) = @parser.parse_block_expr(tok_view)
  let checked_block1 = ctx.check_block_expr(block_expr1)
  assert_true(checked_block1.stmts.length() is 4)
  assert_true(checked_block1.ty is Unit)
  // TypeCheck second block expr
  let (block_expr2, tok_view) = @parser.parse_block_expr(tok_view)
  let checked_block2 = ctx.check_block_expr(block_expr2)
  assert_true(checked_block2.stmts.length() is 5)
  assert_true(checked_block2.ty is Double)
  // TypeCheck third block expr (should raise type error)
  assert_true(ctx.lookup_type("arr") is Some({ kind: Array(Int), .. }))
  let (block_expr3, _) = @parser.parse_block_expr(tok_view)
  let checked_block3 = try? ctx.check_block_expr(block_expr3)
  assert_true(checked_block3 is Err(_))
}
