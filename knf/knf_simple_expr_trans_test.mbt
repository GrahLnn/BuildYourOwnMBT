/// ================================================================================
/// # 🎯 简单表达式的 KNF 变换：引入 Let 语句
///
/// 在完成了应用表达式的转换之后，我们现在要处理**表达式 (Expression)** 的转换。
/// 这是 KNF 变换中一个重要的里程碑，因为我们将首次引入 **Let 语句** 的概念！
///
/// ## 🌟 什么是表达式？
///
/// **表达式**是程序中最基本的计算单元，它们包括：
///
/// - **应用表达式**：`x`、`f(y)`、`arr[0]`（我们已经处理过的）
/// - **一元表达式**：`-x`、`!flag`（取负、逻辑非）
/// - **二元表达式**：`a + b`、`x * y`、`p && q`（算术、逻辑运算）
/// - **块表达式**：`{ stmt1; stmt2; expr }`
/// - **条件表达式**：`if cond { expr1 } else { expr2 }`
///
/// 在 KNF 变换中，我们的目标是将这些表达式转换为**规范化的形式**，
/// 其中复杂的嵌套表达式被分解为简单的原子操作。
///
/// ## 🔍 KNF 的核心思想：Let 语句
///
/// **KNF 的核心思想**是将复杂的表达式分解为简单的原子操作。
/// 为了实现这一点，我们引入了 **Let 语句**：
///
/// ```moonbit
/// enum KnfStmt {
///   Let(Name, Type, KnfExpr)  // let tmp : Int = 42;
///   // ... 其他语句类型
/// }
/// ```
///
/// **Let 语句的作用**：
/// - 将复杂表达式的计算结果存储到临时变量中
/// - 确保每个操作都是"原子"的
/// - 为后续的优化和代码生成做准备
///
/// ## 🎯 你的任务：实现 `expr_to_knf` 函数
///
/// 在这个测试中，你需要实现 `Context::expr_to_knf` 函数。
/// 这个函数需要处理多种表达式类型，但我们将重点关注**简单情况**。
///
/// ### 💡 实现思路
///
/// #### 1. 应用表达式 (ApplyExpr)
/// ```
/// ApplyExpr(apply_expr) => self.apply_expr_to_knf(apply_expr)
/// ```
/// 直接委托给已经实现的 `apply_expr_to_knf` 函数。
///
/// #### 2. 一元表达式 (UnaryExpr)
///
/// **关键步骤**：
/// 1. 递归处理内部表达式
/// 2. 创建临时变量存储内部表达式的结果
/// 3. 生成 Let 语句
/// 4. 返回一元操作的结果
///
/// #### 3. 二元表达式 (BinaryExpr)
///
/// **关键步骤**：
/// 1. 递归处理左右操作数
/// 2. 合并所有语句
/// 3. 为复杂操作数创建临时变量（如果不是简单的标识符）
/// 4. 返回二元操作的结果
///
/// ## 🛠️ 辅助函数：`expr_to_knf_name`
///
/// 这个辅助函数用于将表达式转换为 `Name`：
/// ```moonbit
/// fn Context::expr_to_knf_name(
///   self : Context,
///   expr : KnfExpr,
///   ty : Type,
///   stmts : Array[KnfStmt],
/// ) -> Name
/// ```
///
/// **作用**：
/// - 如果表达式是简单的 `Ident(name)`，直接返回 `name`
/// - 否则创建临时变量，生成 Let 语句，返回临时变量名
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件包含了多种表达式的转换：
///
/// 1. **简单字面量**：`42` → `Int(42)`（无 Let 语句）
/// 2. **一元表达式**：`-33` → `Let(tmp, Int, Int(33)); Neg(tmp)`
/// 3. **一元表达式**：`!w` → `Let(tmp, Bool, Ident(w)); Not(tmp)`
/// 4. **简单二元表达式**：`x + y` → `Binary(Add, x, y)`（无 Let 语句）
/// 5. **复杂二元表达式**：`2.0 * 3.14` → `Let(tmp1, Double, Double(2.0)); Let(tmp2, Double, Double(3.14)); Binary(Mul, tmp1, tmp2)`
/// 6. **混合表达式**：`x + y * z` → `Let(tmp, Int, Binary(Mul, y, z)); Binary(Add, x, tmp)`
///
/// ## 💡 实现提示
///
/// 1. **递归处理**：使用递归处理嵌套表达式
/// 2. **临时变量**：使用 `add_temp` 创建临时变量
/// 3. **Let 语句**：使用 `KnfStmt::Let` 创建 Let 语句
/// 4. **语句合并**：使用 `append` 合并语句列表
/// 5. **优化**：对于简单的 `Ident`，不需要创建临时变量
///
/// ## 🔮 KNF 变换的威力
///
/// 通过引入 Let 语句，我们实现了：
///
/// - **表达式分解**：复杂表达式被分解为简单操作
/// - **副作用隔离**：每个操作的结果都被明确存储
/// - **优化友好**：为后续的优化提供了清晰的结构
/// - **代码生成**：为 LLVM 代码生成提供了标准化的形式
///
/// ## 提醒
///
/// Context结构体已经为你提供了add_new_name和add_temp方法，注意阅读一下哦。
///
/// ## 🎯 开始实现吧！
///
/// 这是 KNF 变换中一个重要的里程碑！通过引入 Let 语句，
/// 我们将复杂的表达式转换为简单、规范化的形式。
///
/// **准备好体验 KNF 变换的核心威力了吗？让我们开始实现！**
/// ================================================================================

///|
test "Simple Expr Knf Transformation Test" {
  // set x, y, z type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("y", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("z", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("w", { kind: Bool, mutable: false })
  let knf_ctx = Context::new()
  knf_ctx.globals.set("x", Int)
  let _ = knf_ctx.add_new_name("y", Int)
  let _ = knf_ctx.add_new_name("w", Int)
  knf_ctx.enter_scope()
  let _ = knf_ctx.add_new_name("z", Bool)

  // Code parse, typecheck, knf transform
  let code =
    #|42;
    #|-33;
    #|!w;
    #|x + y;
    #|2.0 * 3.14;
    #|x + y * z ;
  let tokens = @lexer.tokenize(code)
  // Parse and transform `42` 
  let (e, tok_view) = @parser.parse_expr(tokens)
  let e = typecheck_ctx.check_expr(e)
  let (_, e) = knf_ctx.expr_to_knf(e)
  assert_true(e is Int(42))
  // Parse and transform `-33`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s] && s is Let(n1, Int, Int(33)) && e is Neg(n2) && n1 == n2,
  )
  // Parse and transform `!w`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s] &&
    s is Let(n1, Bool, Ident(i)) &&
    i is { id: "w", .. } &&
    e is Not(n2) &&
    n1 == n2,
  )
  // Parse and transform `x + 10`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [] &&
    e is Binary(Add, n1, n2) &&
    n1 is { id: "x", .. } &&
    n2 is { id: "y", .. },
  )
  // Parse and transform `2.0 * 3.14`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Double, Double(2.0)) &&
    s2 is Let(n2, Double, Double(3.14)) &&
    e is Binary(Mul, n3, n4) &&
    n1 == n3 &&
    n2 == n4,
  )
  // Parse and transform `x + y * z`
  let (e, _) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s] &&
    s is Let(n1, Int, Binary(Mul, n2, n3)) &&
    e is Binary(Add, n4, n5) &&
    n1 is { id: "tmp", .. } &&
    n2 is { id: "y", .. } &&
    n3 is { id: "z", .. } &&
    n4 is { id: "x", .. } &&
    n5 == n1,
  )
}
