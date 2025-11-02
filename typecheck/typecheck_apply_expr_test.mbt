/// ================================================================================
/// # 类型检查 Apply 表达式：最终章
///
/// 我们已经为 `check_apply_expr` 实现了基础的 `AtomExpr` 包装。
/// 现在，是时候完成 `check_apply_expr` 的所有剩余分支，使其能够处理所有复杂的 `ApplyExpr` 类型了。
///
/// ## 🎯 你的任务：完成 `check_apply_expr` 的所有分支
///
/// 你的任务是回到 `typecheck/apply_expr.mbt` 文件，完成 `Context::check_apply_expr` 函数中剩余的 `match` 分支。
///
/// ### 💡 实现思路
///
/// `check_apply_expr` 的核心是一个循环或递归结构，它首先检查一个基础表达式（`AtomExpr`），然后不断检查后面是否跟随 `()`、`[]` 或 `.`，并持续将表达式“包装”成更复杂的 `ApplyExpr`。
///
/// 你需要为 `check_apply_expr` 中的以下 `ApplyExprKind` 分支编写类型检查逻辑：
///
/// 1.  **`ArrayAccess(array_expr, index_expr)` (数组索引 `array[index]`)**
///     *   递归调用 `check_apply_expr` 检查 `array_expr`，并调用 `check_expr` 检查 `index_expr`。
///     *   **类型规则**：
///         *   `array_expr` 的类型必须是 `Array[T]`。
///         *   `index_expr` 的类型必须是 `Int`。
///     *   **返回类型**：整个表达式的类型是数组的元素类型 `T`。
///
/// 2.  **`FieldAccess(object_expr, field_name)` (字段访问 `object.field`)**
///     *   递归调用 `check_apply_expr` 检查 `object_expr`。
///     *   **类型规则**：
///         *   如果 `object_expr` 的类型是 `Struct(struct_name)`：你需要从 `Context` 的 `struct_defs` 中查找该结构体的定义，并找到 `field_name` 对应的字段类型。
///         *   **特殊情况：数组的内置方法**。在 MiniMoonBit 中，我们通过 `FieldAccess` 语法来访问数组的内置方法，例如 `arr.push(value)` 和 `arr.length()`。你需要识别 `object_expr` 的类型是否为 `Array[T]`，然后根据 `field_name`（`"push"` 或 `"length"`）返回对应的函数类型。
///     *   **返回类型**：整个表达式的类型就是该字段或方法的类型。
///
/// 3.  **`Call(callee_expr, arg_exprs)` (函数调用 `func(arg1, arg2, ...)`)**
///     *   递归调用 `check_apply_expr` 检查 `callee_expr`（被调用的函数）。
///     *   **类型规则**：
///         *   `callee_expr` 的类型必须是 `Function` 类型，例如 `Function([ArgT1, ArgT2], RetT)`。
///         *   遍历 `arg_exprs`，对每个参数表达式递归调用 `check_expr`。
///         *   **关键一步**：检查每个传入参数的类型是否与函数签名中对应参数的类型 `ArgT` **兼容**。这里需要大量使用 `is_type_compatible`，它会驱动我们之前实现的类型变量合一（Unification）逻辑。
///         *   参数的数量也必须匹配。
///     *   **返回类型**：整个表达式的类型是函数签名的返回类型 `RetT`。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_apply_expr_test.mbt
/// ```
/// ================================================================================

///|
test "Apply Expression Type Check" {
  let code =
    #|arr[3] ; fact(5) ; print("Hello, World!")
    #|mat[3][4] ; sum(arr); max(x, y);
    #|arr.push(10); mat.length();
  let ctx = Context::new()
  ctx.type_env.set("arr", { kind: Array(Int), mutable: false })
  ctx.type_env.set("mat", { kind: Array(Array(Int)), mutable: false })
  ctx.type_env.set("fact", { kind: Function([Int], Int), mutable: false })
  ctx.type_env.set("print", { kind: Function([String], Unit), mutable: false })
  ctx.type_env.set("sum", { kind: Function([Array(Int)], Int), mutable: false })
  // Note: max is local function without type annotations
  // like: fn max(a, b) { ... }
  ctx.type_env.set("max", {
    kind: Function([TypeVar(0), TypeVar(1)], TypeVar(2)),
    mutable: false,
  })
  ctx.type_env.set("x", { kind: Double, mutable: true })
  ctx.type_env.set("y", { kind: Double, mutable: true })
  ctx.type_vars.set(0, TypeVar(0))
  ctx.type_vars.set(1, TypeVar(0))
  ctx.type_vars.set(2, TypeVar(0))
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type of arr[3]
  let (a, tok_view) = @parser.parse_apply_expr(tokens[:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Int)
  // Type of fact(5)
  let (a, tok_view) = @parser.parse_apply_expr(tok_view[1:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Int)
  // Type of print("Hello, World!")
  let (a, tok_view) = @parser.parse_apply_expr(tok_view[1:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Unit)
  // Type of mat[3][4]
  let (a, tok_view) = @parser.parse_apply_expr(tok_view[1:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Int)
  // Type of sum(arr)
  let (a, tok_view) = @parser.parse_apply_expr(tok_view[1:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Int)
  // Type of max(x, y)
  let (a, tok_view) = @parser.parse_apply_expr(tok_view[1:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Double)
  // Type of arr.push(10)
  let (a, tok_view) = @parser.parse_apply_expr(tok_view[1:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Unit)
  // Type of mat.length()
  let (a, _) = @parser.parse_apply_expr(tok_view[1:])
  let a = ctx.check_apply_expr(a)
  assert_true(a.ty is Int)
}
