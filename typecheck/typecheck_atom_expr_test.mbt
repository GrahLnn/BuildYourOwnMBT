/// ================================================================================
/// # 类型检查原子表达式：完整篇
///
/// 我们已经实现了 `check_atom_expr` 的基础部分，能够处理字面量和标识符。
/// 现在，是时候完成 `check_atom_expr` 的所有剩余分支，使其能够处理所有类型的原子表达式了。
///
/// ## 🎯 你的任务：完成 `check_atom_expr`
///
/// 你的任务是回到 `typecheck/atom_expr.mbt` 文件，完成 `Context::check_atom_expr` 函数中剩余的 `match` 分支。
///
/// ### 💡 实现思路
///
/// 你需要为 `check_atom_expr` 中的以下 `AtomExprKind` 分支编写类型检查逻辑：
///
/// 1.  **`Paren(expr)` (括号表达式 `(expr)`)**
///     *   递归调用 `self.check_expr(expr)` 检查内部表达式。
///     *   `Paren` 表达式的类型就是其内部表达式的类型。
///
/// 2.  **`Tuple(exprs)` (元组表达式 `(expr1, expr2, ...)`)**
///     *   遍历 `exprs` 数组，对每个子表达式递归调用 `self.check_expr`。
///     *   将所有子表达式的类型收集起来，构成一个 `TypeKind::Tuple` 类型。
///     *   **提示：** 你可以实现一个辅助函数 `check_tuple_expr` 来处理这个逻辑。
///
/// 3.  **`Array(exprs)` (数组字面量 `[expr1, expr2, ...]`)**
///     *   遍历 `exprs` 数组，对每个子表达式递归调用 `self.check_expr`。
///     *   **类型规则：** 数组的所有元素必须具有兼容的类型。你需要使用 `self.is_type_compatible` 来确保这一点。
///     *   **空数组 `[]` 的特殊处理：** 如果数组为空，它的元素类型是未知的。此时，你应该创建一个 `TypeVar` 作为其元素类型的占位符，例如 `Array(TypeVar(N))`。
///     *   **提示：** 你可以实现一个辅助函数 `check_array_expr` 来处理这个逻辑。
///
/// 4.  **`ArrayMake(size_expr, init_expr)` (`Array::make(size, init)`)**
///     *   调用 `self.check_expr` 检查 `size_expr`，其类型必须是 `Int`。
///     *   调用 `self.check_expr` 检查 `init_expr`。
///     *   整个 `ArrayMake` 表达式的类型是 `Array(init_expr.ty)`。
///     *   **提示：** 你可以实现一个辅助函数 `check_array_make_expr` 来处理这个逻辑。
///
/// 5.  **`StructConstruct(sc_expr)` (`StructName::{ field: value, ... }`)**
///     *   调用 `self.check_struct_construct_expr(sc_expr)` 来检查结构体构造表达式。
///     *   **提示：** 这个函数我们已经在之前的挑战中实现过了。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_atom_expr_test.mbt
/// ```
/// ================================================================================

///|
test "Atom Expression Type Check" {
  let code =
    #|[1, 2+3, 3+4+5, 6*7+8] (1+3, !y, "Hello") Array::make(5, 0) []
  let ctx = Context::new()
  ctx.type_env.set("x", { kind: Double, mutable: false })
  ctx.type_env.set("y", { kind: Bool, mutable: false })
  ctx.type_env.set("z", { kind: String, mutable: false })
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type of [1, 2+3, 3+4+5, 6*7+8]
  let (a, tok_view) = @parser.parse_atom_expr(tokens[:])
  let a = ctx.check_atom_expr(a)
  assert_true(a.ty is Array(Int))
  // Type of (1+3, !y, "Hello")
  let (b, tok_view) = @parser.parse_atom_expr(tok_view)
  let b = ctx.check_atom_expr(b)
  assert_true(b.ty is Tuple([Int, Bool, String]))
  // Type of Array::make(5, 0)
  let (c, tok_view) = @parser.parse_atom_expr(tok_view)
  let c = ctx.check_atom_expr(c)
  assert_true(c.ty is Array(Int))
  // Type of []
  let (d, _) = @parser.parse_atom_expr(tok_view)
  let d = ctx.check_atom_expr(d)
  assert_true(d.ty is Array(TypeVar(_)))
}
