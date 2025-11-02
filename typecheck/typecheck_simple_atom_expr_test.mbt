/// ================================================================================
/// # 类型检查表达式：从原子表达式开始
///
/// 恭喜你，我们已经完成了对顶层声明的类型检查！
/// 现在，我们将深入编译器的核心腹地：**表达式的类型检查**。
///
/// 我们的最终目标是实现一个 `check_expr` 函数，它能够确定任何复杂表达式的类型。
/// 但正如我们在语法分析阶段所做的那样，我们将采用“自底向上”的策略，从最简单的部分开始。
///
/// ## 🎯 你的任务：实现 `check_atom_expr`
///
/// **原子表达式（AtomExpr）**是所有复杂表达式的基石。
/// 你的第一个任务是在 `typecheck/atom_expr.mbt` 文件中实现 `Context::check_atom_expr` 函数。
///
/// 这个函数接收一个来自 parser 的 `AtomExpr`，并返回一个**带有类型信息**的新 `AtomExpr`。
///
/// ### 💡 实现思路
///
/// 你需要在 `check_atom_expr` 中使用 `match` 语句来处理不同种类的原子表达式：
///
/// 1.  **字面量（Literals）：**
///     *   对于 `Int(v)`，其类型显然是 `TypeKind::Int`。
///     *   对于 `Double(v)`，其类型是 `TypeKind::Double`。
///     *   对于 `Bool(v)`，其类型是 `TypeKind::Bool`。
///     *   对于 `String(s)`，其类型是 `TypeKind::String`。
///
/// 2.  **标识符（Identifiers）：**
///     *   对于 `Ident(name)`，情况变得有趣起来。这代表一个变量。
///     *   它的类型是什么？我们必须在**类型环境（Type Environment）**中查找它！
///     *   `Context` 结构体中包含一个 `type_env` 字段，它是一个 `Map`，存储了当前作用域内所有已知变量的类型。
///     *   你需要从 `self.type_env` 中查找 `name` 对应的类型。如果找不到，就应该抛出一个 `TypeCheckError` 错误。
///
/// **请注意：**
/// 本次挑战的测试用例只包含上述几种情况。你暂时**不需要**处理 `Paren`、`Tuple`、`Array` 等更复杂的原子表达式，我们将在后续的挑战中逐步完善它们。
///
/// ---
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p typecheck -f typecheck_simple_atom_expr_test.mbt
/// ```
///
/// 加油！这是我们构建类型推断引擎的第一步！
/// ================================================================================

///|
test "Simple Atom Expression Type Check" {
  let code =
    #|42 3.14 true "Hello" x y z
  let ctx = Context::new()
  ctx.type_env.set("x", { kind: TypeKind::Double, mutable: false })
  ctx.type_env.set("y", { kind: TypeKind::Bool, mutable: false })
  ctx.type_env.set("z", { kind: TypeKind::String, mutable: false })
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type of 42
  let (a, tok_view) = @parser.parse_atom_expr(tokens[:])
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is Int)
  // Type of 3.14
  let (a, tok_view) = @parser.parse_atom_expr(tok_view)
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is Double)
  // Type of true
  let (a, tok_view) = @parser.parse_atom_expr(tok_view)
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is Bool)
  // Type of "Hello"
  let (a, tok_view) = @parser.parse_atom_expr(tok_view)
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is String)
  // Type of x
  let (a, tok_view) = @parser.parse_atom_expr(tok_view)
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is Double)
  // Type of y
  let (a, tok_view) = @parser.parse_atom_expr(tok_view)
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is Bool)
  // Type of z
  let (a, _) = @parser.parse_atom_expr(tok_view)
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is String)
}
