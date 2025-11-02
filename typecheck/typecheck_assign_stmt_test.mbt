/// ================================================================================
/// # 类型检查语句：赋值语句
///
/// 我们已经能够通过 `let` 和 `let mut` 向环境中添加新的变量了。现在，我们要检查对这些变量的**赋值（Assignment）**操作。
///
/// 赋值语句是命令式编程的核心，它会改变一个已存在变量的值。类型检查器的职责是确保这种改变是**类型安全**且**合法**的。
///
/// ## 🎯 你的任务：实现 `check_assign_stmt`
///
/// 你的任务是在 `typecheck/assign_stmt.mbt` 文件中实现 `Context::check_assign_stmt` 函数。
///
/// ### 💡 实现思路
///
/// 1.  **检查左值（L-Value）：**
///     *   赋值语句的左侧不是任意表达式，而是一个“左值”——可以被赋值的目标，例如变量 `x`、数组元素 `arr[0]` 或结构体字段 `obj.field`。
///     *   你需要首先实现一个 `check_left_value` 辅助函数，它负责检查左值的类型。例如，对于 `x`，它需要到类型环境中查找 `x` 的类型。
///
/// 2.  **检查可变性（Mutability）：**
///     *   **这是赋值检查中最关键的一步！** 你不能给一个不可变的变量赋值。
///     *   当你从类型环境中查找到左侧变量的类型后，必须检查其 `mutable` 标志是否为 `true`。如果不是，就应该抛出类型错误。
///     *   思考一下：对于 `arr[0]` 这样的左值，它的可变性应该如何确定？（提示：它取决于 `arr` 本身是否可变，还是数组元素总是可变的？）在我们的 MiniMoonBit 中，我们做一个简化，认为只要数组本身是可访问的，其元素就是可变的。
///
/// 3.  **检查右值（R-Value）：**
///     *   调用 `self.check_expr` 检查 `=` 右侧表达式的类型。
///
/// 4.  **检查类型兼容性：**
///     *   确保右侧表达式的类型与左值的类型是兼容的。
///
/// 5.  **处理复合赋值（Compound Assignment）：**
///     *   对于 `+=`, `-=` 等操作，你还需要额外检查左右两侧的类型是否适用于该算术运算（例如，它们必须是 `Int` 或 `Double`）。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_assign_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "Assign Stmt Type Check" {
  let code =
    #|let mut x = 10;
    #|x = 5;
    #|let arr = [1, 2, 3];
    #|arr[0] = 10;
    #|x += true;  // Shoule fail
    #|let mut a = xxx;  // xxx's type is typevar
    #|a += 33;  // `a` and `xxx` should be inferred as Int
  let ctx = Context::new()
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type of let mut x = 10; x = 5; 
  let (s, tok_view) = @parser.parse_let_mut_stmt(tokens[:])
  let _ = ctx.check_let_mut_stmt(s)
  let (a, tok_view) = @parser.parse_assign_stmt(tok_view)
  let a = ctx.check_assign_stmt(a)
  assert_true(a.left_value.ty.kind is Int)
  assert_true(a.expr.ty is Int)
  // Type of `let arr = [1, 2, 3]; arr[0] = 10;`
  let (s, tok_view) = @parser.parse_let_stmt(tok_view)
  let _ = ctx.check_let_stmt(s)
  let (a, tok_view) = @parser.parse_assign_stmt(tok_view)
  let a = ctx.check_assign_stmt(a)
  assert_true(a.left_value.ty.kind is Int)
  assert_true(a.left_value.ty.mutable is true)
  assert_true(a.expr.ty is Int)
  // Type of `x += true;` should fail
  let (a, tok_view) = @parser.parse_assign_stmt(tok_view)
  let t = try? ctx.check_assign_stmt(a)
  assert_true(t is Err(_))
  // Type of `let mut a = xxx; a += 33;`
  ctx.type_vars.set(0, TypeVar(0))
  ctx.type_env.set("xxx", { kind: TypeVar(0), mutable: false })
  let (s, tok_view) = @parser.parse_let_mut_stmt(tok_view)
  let _ = ctx.check_let_mut_stmt(s)
  let (a, _) = @parser.parse_assign_stmt(tok_view)
  let _ = ctx.check_assign_stmt(a)
  assert_true(ctx.lookup_type("a") is Some({ kind: Int, .. }))
  assert_true(ctx.lookup_type("xxx") is Some({ kind: Int, .. }))
}
