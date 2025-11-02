/// ================================================================================
/// # 类型检查的核心：Expr
///
/// 我们已经可以处理 `AtomExpr` 和 `ApplyExpr` 了。现在，我们来到了类型检查的核心枢纽：`check_expr` 函数。
///
/// `Expr` 是一个递归的枚举类型，它可以代表各种复杂的表达式，如一元运算、二元运算等。
/// `check_expr` 的职责就是深入到这些表达式的内部，验证它们的类型规则，并最终确定整个表达式的类型。
///
/// ## 🎯 你的任务：实现 `check_expr`
///
/// 你的任务是在 `typecheck/expr.mbt` 文件中实现 `Context::check_expr` 函数。
/// 本次挑战的测试覆盖了多种表达式，你需要一次性处理它们！
///
/// ### 💡 实现思路
///
/// 你需要在 `check_expr` 中 `match` 传入的 `expr.kind`，并为不同的情况编写类型检查逻辑：
///
/// 1.  **`ApplyExpr(apply_expr)`:**
///     *   这是最简单的情况。直接调用我们刚完成的 `self.check_apply_expr(apply_expr)`。
///     *   返回的 `ApplyExpr` 已经带有了类型，用它来构造一个 `typecheck::Expr` 并返回。
///
/// 2.  **`NotExpr(inner_expr)` (逻辑非 `!`)**
///     *   首先，递归调用 `self.check_expr(inner_expr)` 来检查内部表达式。
///     *   **类型规则：** `!` 操作符只能用于 `Bool` 类型。你需要检查 `inner_expr` 的类型是否为 `Bool`。如果不是，就抛出类型错误。
///     *   **返回类型：** `NotExpr` 本身的类型永远是 `Bool`。
///
/// 3.  **`NegExpr(inner_expr)` (取反 `-`)**
///     *   同样，递归调用 `self.check_expr(inner_expr)`。
///     *   **类型规则：** `-` 操作符在我们的语言中只能用于 `Int` 或 `Double`。你需要检查 `inner_expr` 的类型。
///     *   **返回类型：** `NegExpr` 的类型与它内部表达式的类型相同。
///
/// 4.  **`BinaryExpr(op, left, right)` (二元运算)**
///     *   这是最复杂的部分。首先，递归调用 `check_expr` 检查左右两个子表达式 `left` 和 `right`。
///     *   **通用规则：** 对于所有二元运算，左右两个操作数的类型必须兼容（在我们的简单实现中，意味着类型必须完全相同）。你可以使用 `self.is_type_compatible(...)` 辅助函数来判断。
///     *   **根据操作符 `op` 判断返回类型：**
///         *   **算术运算 (`+`, `-`, `*`, `/`, `%`)：** 操作数必须是 `Int` 或 `Double`。返回类型与操作数类型相同。
///         *   **比较运算 (`>`, `<`, `==`, `!=`, `>=`, `<=`)：** 操作数可以是 `Int` 或 `Double`。返回类型永远是 `Bool`。
///         *   **逻辑运算 (`&&`, `||`)：** 操作数必须是 `Bool`。返回类型也是 `Bool`。（注：本次测试未覆盖，但可以提前思考）
///
/// ---
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p typecheck -f typecheck_simple_expr_test.mbt
/// ```
///
/// 加油！这是类型检查器中工作量最大、也最核心的部分。
/// ================================================================================

///|
test "Simple Expression Type Check" {
  let code =
    #|42 ; 3.14 ; true ; "Hello";
    #|!true ; !false ; !x ;
    #|-42 ; -3.14 ; -y ;
    #|1 + 3; 4 - 5 ; 6 * 7; 8.0 / 2.0; 9 % 4;
    #|1 > 2; 42.0 >= y; x == true ;
  let ctx = Context::new()
  ctx.type_env.set("x", { kind: TypeKind::Bool, mutable: false })
  ctx.type_env.set("y", { kind: TypeKind::Double, mutable: false })
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type of 42
  let (a, tok_view) = @parser.parse_expr(tokens[:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Int)
  // Type of 3.14
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Double)
  // Type of true
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Bool)
  // Type of "Hello"
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is String)
  // Type of !true
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Bool)
  // Type of !false
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Bool)
  // Type of !x
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Bool)
  // Type of -42
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Int)
  // Type of -3.14
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Double)
  // Type of -y
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Double)
  // Type of 1 + 3
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Int)
  // Type of 4 - 5
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Int)
  // Type of 6 * 7
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Int)
  // Type of 8.0 / 2.0
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Double)
  // Type of 9 % 4
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Int)
  //// Type of 1 > 2
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Bool)
  //// Type of 42 == y
  let (a, tok_view) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Bool)
  //// Type of x == true
  let (a, _) = @parser.parse_expr(tok_view[1:])
  let a = ctx.check_expr(a)
  assert_true(a.ty is Bool)
}
