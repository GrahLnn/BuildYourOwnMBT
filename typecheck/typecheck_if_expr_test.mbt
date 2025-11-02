/// ================================================================================
/// # 类型检查控制流：if-else 表达式
///
/// `if-else` 是我们语言中第一个真正的控制流结构。在 MiniMoonBit 中，`if-else` 自身也是一个表达式，它可以产生一个值。
/// 类型检查器必须保证它的逻辑是健全的。
///
/// ## 🎯 你的任务：实现 `check_if_expr`
///
/// 你的任务是在 `typecheck/if_expr.mbt` 文件中实现 `Context::check_if_expr` 函数。
///
/// ### 💡 实现思路
///
/// 检查 `if-else` 表达式需要遵循几条核心规则：
///
/// 1.  **检查条件：**
///     *   `if` 后面的条件表达式必须是一个 `Bool` 类型。你需要首先调用 `check_expr` 检查条件，并验证其类型。
///
/// 2.  **检查 `then` 分支：**
///     *   调用 `check_block_expr` 来检查 `then` 代码块，并记录下它的类型 `T_then`。
///
/// 3.  **检查 `else` 分支：**
///     *   **如果存在 `else` 分支**（无论是 `else if` 还是 `else`）：
///         *   你需要递归地检查 `else` 分支（调用 `check_if_expr` 或 `check_block_expr`），并获得其类型 `T_else`。
///         *   **核心规则：** `then` 分支的类型 `T_then` 必须与 `else` 分支的类型 `T_else` 兼容。你需要调用 `self.is_type_compatible(T_then, T_else)`。
///         *   **表达式类型：** 整个 `if-else` 表达式的类型就是 `T_then`（在合一后可能被更新的 `T_then`）。
///
///     *   **如果不存在 `else` 分支**：
///         *   这意味着 `if` 表达式在条件为 `false` 时不产生任何值。
///         *   **核心规则：** 在这种情况下，整个 `if` 表达式的类型被定为 `Unit`。
///         *   这也反过来对 `then` 分支施加了一个约束：它的类型 `T_then` 必须与 `Unit` 兼容。一个返回 `Int` 的 `then` 分支不能在没有 `else` 的情况下独立存在。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_if_expr_test.mbt
/// ```
/// ================================================================================

///|
test "If Expr TypeCheck Test" {
  let code =
    #|let arr = [];
    #|
    #|if a > b {
    #|  arr.push(1);
    #|} else {
    #|  arr.push(2);
    #|}
    #|
    #|if a < b {
    #|  arr.push(a);
    #|  a
    #|}else if a == b {
    #|  arr.push(1);
    #|  a - b
    #|} else {
    #|  arr.push(b);
    #|  b
    #|}
    #|
  let ctx = Context::new()
  ctx.type_vars.set(0, TypeVar(0))
  ctx.type_vars.set(1, TypeVar(1))
  ctx.type_env.set("a", { kind: TypeVar(0), mutable: false })
  ctx.type_env.set("b", { kind: TypeVar(1), mutable: false })
  // Parse
  let tokens = @lexer.tokenize(code)
  let (let_stmt, tok_view) = @parser.parse_let_stmt(tokens[:])
  let _ = ctx.check_let_stmt(let_stmt)
  // TypeCheck first if expr
  let (if_expr1, tok_view) = @parser.parse_if_expr(tok_view)
  let checked_if1 = ctx.check_if_expr(if_expr1)
  assert_true(checked_if1.ty is Unit)
  assert_true(ctx.lookup_type("arr") is Some({ kind: Array(Int), .. }))
  // TypeCheck second if expr
  let (if_expr2, _) = @parser.parse_if_expr(tok_view)
  let checked_if2 = ctx.check_if_expr(if_expr2)
  assert_true(checked_if2.ty is Int)
  assert_true(ctx.lookup_type("a") is Some({ kind: Int, .. }))
  assert_true(ctx.lookup_type("b") is Some({ kind: Int, .. }))
}
