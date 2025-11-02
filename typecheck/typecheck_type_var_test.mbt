/// ================================================================================
/// # 类型推断的魔法：类型变量与合一（Unification）
///
/// 欢迎来到我们编译器中最激动人心的部分之一：**类型推断（Type Inference）**。
/// 类型推断允许程序员省略部分或全部的类型注解，编译器会自动推导出这些变量的类型。
/// 它的核心魔法，就是**类型变量（Type Variables）**和**合一（Unification）**算法。
///
/// ## 🤔 为什么需要类型变量？
///
/// 想象一下这个场景：
///
/// ```moonbit
/// let a = [];
/// ```
///
/// 在这一行，`a` 的类型是 `Array[?]`。但我们完全不知道 `?` 应该是什么类型。
/// 为了解决这个问题，我们引入一个“占位符”类型，称之为**类型变量**。
/// 我们可以说 `a` 的类型是 `Array[TypeVar(0)]`，其中 `0` 是这个类型变量的唯一ID。
/// 我们将这个信息记录在 `Context` 的一张表里（例如 `type_vars: Map[Int, TypeKind]`）。
///
/// ## ⚙️ 类型变量如何工作：合一（Unification）
///
/// 类型变量的真正威力在于它们如何通过代码的上下文来获得具体的类型。这个过程称为“合一”。
///
/// **场景1：推断出具体类型**
///
/// 如果我们接下来看到 `a.push(1)`，类型检查器会分析 `push` 函数。它知道 `push` 的参数类型应该与数组的元素类型相同。
/// 因此，`Int` 类型必须与 `TypeVar(0)` 兼容。
/// 此时，我们就可以**合一** `TypeVar(0)` 和 `Int`，在我们的表中记录下：`TypeVar(0) = Int`。
/// `a` 的类型之谜就此解开，它是一个 `Array[Int]`。
///
/// **场景2：关联两个未知类型**
///
/// 假设我们有 `let b = []`，它的类型是 `Array[TypeVar(1)]`。
/// 如果代码中出现了 `a == b`，这意味着 `a` 和 `b` 的类型必须兼容。
/// 也就是说 `Array[TypeVar(0)]` 必须与 `Array[TypeVar(1)]` 兼容，这进一步要求 `TypeVar(0)` 必须与 `TypeVar(1)` 兼容。
///
/// 此时，我们将 `TypeVar(0)` 和 `TypeVar(1)` **合一**。我们可以在表中记录 `TypeVar(1) = TypeVar(0)`。
/// 这就像建立了一个“等价关系”。现在，任何关于 `TypeVar(0)` 的信息，都将自动传递给 `TypeVar(1)`。
///
/// **场景3：信息传递**
///
/// 延续场景2，如果我们稍后看到了 `a.push(1)`，我们推断出 `TypeVar(0) = Int`。
/// 因为我们已经知道 `TypeVar(1) = TypeVar(0)`，所以我们立刻也知道了 `TypeVar(1) = Int`。
/// `b` 的类型也随之确定为 `Array[Int]`。
///
/// ## 🎯 你的任务：实现 `is_type_compatible` 中的 `TypeVar` 逻辑
///
/// 你的任务就是将上述逻辑在 `typecheck/typedef.mbt` 的 `is_type_compatible` 函数中实现。
/// 你需要为 `match (a, b)` 添加处理 `TypeVar` 的分支：
///
/// *   **`TypeVar` vs. 具体类型（例如 `(TypeVar(id), Int)`）：**
///     将类型变量 `id` 与该具体类型进行合一。
/// *   **`TypeVar` vs. `TypeVar`（例如 `(TypeVar(id_a), TypeVar(id_b))`）：**
///     将两个类型变量进行合一。
///
/// 你可能需要一个辅助函数，例如 `set_var_type_to_typekind`，来更新你的类型变量表，并处理好“等价关系”的传递。
///
/// ---
///
/// **阶段性测试：**
///
/// 本次的测试用例会直接调用 `is_type_compatible` 来验证你的合一算法是否正确。
///
/// ```bash
/// moon test -p typecheck -f typecheck_type_var_test.mbt
/// ```
///
/// 加油！这是通往现代类型系统最关键、也最有趣的一步！
/// ================================================================================

///|
test "Type Var Test - 1" {
  let ctx = Context::new()
  ctx.type_vars.set(0, TypeVar(0))
  ctx.type_vars.set(1, TypeVar(1))
  ctx.type_vars.set(2, TypeVar(2))
  ctx.type_vars.set(3, TypeVar(3))
  // TVar(0) = Double
  let t1 = ctx.is_type_compatible(TypeVar(0), Double)
  assert_true(t1 is true)
  assert_true(ctx.type_vars.get(0).unwrap() is Double)
  // TVar(1) = TVar(0)
  let t2 = ctx.is_type_compatible(TypeVar(1), TypeVar(0))
  assert_true(t2 is true)
  assert_true(ctx.type_vars.get(1).unwrap() is Double)
  // TVar(2) = TVar(3)
  let t3 = ctx.is_type_compatible(TypeVar(2), TypeVar(3))
  assert_true(t3 is true)
  // TVAr(3) = Int, therefore TVar(2) = Int
  let t4 = ctx.is_type_compatible(TypeVar(3), Int)
  assert_true(t4 is true)
  assert_true(ctx.type_vars.get(2).unwrap() is Int)
  assert_true(ctx.type_vars.get(3).unwrap() is Int)
  let t5 = ctx.is_type_compatible(TypeVar(2), Double)
  assert_true(t5 is false)
}

///|
///
/// 0 == 1 == 2 == 3
/// 2 == (Double, Int)
///
/// 0, 1, 2, 3 should all resolve to (Double, Int)
test "Type Var Test - 2" {
  let ctx = Context::new()
  ctx.type_vars.set(0, TypeVar(0))
  ctx.type_vars.set(1, TypeVar(1))
  ctx.type_vars.set(2, TypeVar(2))
  ctx.type_vars.set(3, TypeVar(3))
  //
  let _ = ctx.is_type_compatible(TypeVar(0), TypeVar(1))
  let _ = ctx.is_type_compatible(TypeVar(1), TypeVar(2))
  let _ = ctx.is_type_compatible(TypeVar(2), TypeVar(3))
  let _ = ctx.is_type_compatible(TypeVar(3), TypeVar(0))
  let _ = ctx.is_type_compatible(TypeVar(2), Tuple([Double, Int]))
  let t0 = ctx.type_vars.get(0).unwrap()
  let t1 = ctx.type_vars.get(1).unwrap()
  let t2 = ctx.type_vars.get(2).unwrap()
  let t3 = ctx.type_vars.get(3).unwrap()
  assert_true(t0 is Tuple([Double, Int]))
  assert_true(t1 is Tuple([Double, Int]))
  assert_true(t2 is Tuple([Double, Int]))
  assert_true(t3 is Tuple([Double, Int]))
}
