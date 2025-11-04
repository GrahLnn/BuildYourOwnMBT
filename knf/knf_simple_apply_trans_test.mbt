/// ================================================================================
/// # 🎯 简单应用表达式的 KNF 变换：从原子到应用
///
/// 在完成了原子表达式的转换之后，我们现在要处理**应用表达式 (Apply Expression)**。
/// 应用表达式是比原子表达式更复杂一层的表达式，它们包含了函数调用、数组访问、字段访问等操作。
///
/// ## 🌟 什么是应用表达式？
///
/// **应用表达式**是能够被"应用"或"调用"的表达式，它们包括：
///
/// - **原子表达式**：`42`、`x`、`"hello"`（作为应用表达式的基础）
/// - **数组访问**：`arr[0]`、`matrix[i][j]`
/// - **字段访问**：`point.x`、`person.name`
/// - **函数调用**：`f(x)`、`add(a, b)`、`obj.method(args)`
///
/// 在编译器的语法分析中，应用表达式具有**左结合性**和**高优先级**，
/// 这意味着像 `f(x)[0].field` 这样的表达式会被正确解析为 `((f(x))[0]).field`。
///
/// ## 🔍 ApplyExpr 的结构层次
///
/// 应用表达式采用了一种**递归的结构设计**：
///
/// ```moonbit
/// enum ApplyExprKind {
///   AtomExpr(AtomExpr)                    // 基础：原子表达式
///   ArrayAccess(ApplyExpr, Expr)         // 数组访问：arr[index]
///   FieldAccess(ApplyExpr, String)       // 字段访问：obj.field
///   Call(ApplyExpr, Array[Expr])         // 函数调用：func(args...)
/// }
/// ```
///
/// **关键观察**：除了 `AtomExpr` 之外，其他所有类型都包含一个 `ApplyExpr` 作为"基础"，
/// 这形成了一个递归的结构，使得复杂的表达式可以层层嵌套。
///
/// ## 🎯 你的任务：实现 `apply_expr_to_knf` 函数
///
/// 在这个测试中，你需要实现 `Context::apply_expr_to_knf` 函数。
/// 好消息是，对于**简单的应用表达式**（只包含原子表达式），实现非常简单！
///
/// ### 💡 实现思路
///
/// 由于这个测试只涉及简单的应用表达式，你需要处理的模式匹配非常简单：
///
/// ```moonbit
/// match apply_expr.kind {
///   AtomExpr(atom_expr) => self.atom_expr_to_knf(atom_expr)
///   // 其他复杂情况暂时不需要处理
/// }
/// ```
///
/// **就这么简单！** 当应用表达式是一个原子表达式时，直接调用 `atom_expr_to_knf` 即可。
///
/// ### 🔄 递归设计的优势
///
/// 这种递归设计的好处是：
/// - **简单情况**：原子表达式直接处理
/// - **复杂情况**：通过递归调用处理嵌套结构
/// - **扩展性**：可以轻松添加新的应用表达式类型
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件专门测试**简单的应用表达式**，即只包含原子表达式的应用表达式：
///
/// 1. **字面量**：`42`、`3.14`、`true`、`"hello"`
/// 2. **标识符**：`x`、`y`、`z`
///
/// 所有这些表达式在 `ApplyExpr` 中都被包装为 `AtomExpr(atom_expr)`，
/// 所以转换过程就是简单地调用 `atom_expr_to_knf`。
///
/// ## 🛠️ 上下文管理
///
/// 由于我们只是简单地委托给 `atom_expr_to_knf`，上下文管理完全由该函数处理：
///
/// - **变量查找**：通过 `lookup_name` 查找变量
/// - **作用域管理**：处理局部、父作用域和全局变量
/// - **错误处理**：处理未定义变量等错误
///
/// ## 💡 实现提示
///
/// 1. **模式匹配**：使用 `match` 语句处理 `ApplyExprKind`
/// 2. **简单委托**：对于 `AtomExpr` 情况，直接调用 `atom_expr_to_knf`
/// 3. **错误处理**：暂时不需要处理其他复杂情况
/// 4. **返回值**：保持与 `atom_expr_to_knf` 相同的返回类型
///
/// ## 🔮 未来扩展
///
/// 虽然这个测试只处理简单情况，但 `apply_expr_to_knf` 函数的设计已经为处理复杂情况做好了准备：
///
/// - **数组访问**：`arr[index]` → `ArrayAccess(array_name, index_name)`
/// - **字段访问**：`obj.field` → `FieldAccess(obj_name, field_name)`
/// - **函数调用**：`func(args)` → `Call(func_name, arg_names)`
///
/// 这些复杂情况会在后续的测试中逐步实现。
///
/// ## 🎯 开始实现吧！
///
/// 这个函数可能是你到目前为止实现的最简单的 KNF 转换函数！
/// 只需要识别出 `AtomExpr` 模式，然后委托给已经实现的 `atom_expr_to_knf` 函数即可。
///
/// **准备好体验这种"简单委托"的优雅设计了吗？让我们开始实现！**
/// ================================================================================

///|
test "Simple Apply Expr Knf Transformation Test" {
  // set x, y, z type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("y", { kind: Double, mutable: false })
  typecheck_ctx.type_env.set("z", { kind: Bool, mutable: false })
  let knf_ctx = Context::new()
  knf_ctx.globals.set("x", Int)
  let _ = knf_ctx.add_new_name("y", Double)
  knf_ctx.enter_scope()
  let _ = knf_ctx.add_new_name("z", Bool)

  // Code parse, typecheck, knf transform
  let code =
    #|42 3.14 true "hello"
    #|x y z
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = @parser.parse_apply_expr(tokens)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Int(42))
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Double(3.14))
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Bool(true))
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is String("hello"))
  // find Global Ident `x`
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Ident({ id: "x", slot: 0 }))
  // find Parent Ident `y`
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Ident({ id: "y", slot: 0 }))
  // find Local Ident `z`
  let (e, _) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Ident({ id: "z", slot: 0 }))
}
