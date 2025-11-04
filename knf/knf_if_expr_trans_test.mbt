/// ================================================================================
/// # 🎯 If 表达式的 KNF 变换：条件控制流的处理
///
/// 在完成了块表达式的转换之后，我们现在要处理**If 表达式 (If Expression)** 的转换。
/// 这是 KNF 变换中的一个重要挑战，因为它涉及到**条件控制流 (Conditional Control Flow)** 的处理。
///
/// ## 🌟 什么是 If 表达式？
///
/// **If 表达式**是条件控制流的核心，它们的形式是：
///
/// ```
/// if (y > 0) {          // 简单 if-else
///   x = 10;
/// } else {
///   x = 20;
/// }
///
/// if (x < 5) {          // 只有 if，没有 else
///   print_int(x);
/// }
///
/// if x > 10 {           // if-else if-else 链
///   y
/// } else if x > 5 {
///   y + 1
/// } else {
///   y + 2
/// }
/// ```
///
/// **If 表达式的特点**：
/// - **条件分支**：根据条件选择不同的执行路径
/// - **嵌套结构**：支持 else if 的嵌套结构
/// - **可选 else**：else 块是可选的
/// - **表达式值**：整个 if 表达式有返回值
///
/// ## 🔍 If 表达式的结构差异
///
/// If 表达式在语法树和 KNF 中的结构存在重要差异：
///
/// ### 语法树中的结构
/// ```
/// IfExpr {
///   cond: Expr,
///   then_block: BlockExpr,
///   else_block: Either[IfExpr, BlockExpr]?  // 关键差异
/// }
/// ```
///
/// **关键特点**：
/// - `else_block` 是 `Either` 类型
/// - `Left(IfExpr)` 表示 else if
/// - `Right(BlockExpr)` 表示 else 块
/// - `None` 表示没有 else
///
/// ### KNF 中的结构
/// ```
/// If(cond, KnfBlock, KnfBlock)  // 统一结构
/// ```
///
/// **关键特点**：
/// - 两个 `KnfBlock`：then 块和 else 块
/// - else if 被嵌套到 else 块中
/// - 结构更加统一和简化
///
/// ## 🎯 你的任务：实现 `if_expr_to_knf` 函数
///
/// 在这个测试中，你需要实现 `Context::if_expr_to_knf` 函数。
///
/// ### 💡 实现思路
///
/// If 表达式的转换分为三个主要步骤：
///
/// 1. **处理条件**：使用 `expr_to_knf` 处理条件表达式
/// 2. **处理 then 块**：使用 `block_expr_to_knf` 处理 then 块
/// 3. **处理 else 块**：根据 else 块的类型进行不同处理
///
/// ### 🔧 关键实现细节
///
/// #### 条件处理
/// ```
/// let (cond_stmts, cond_knf_expr) = self.expr_to_knf(if_expr.cond)
/// stmts.append(cond_stmts)
/// ```
///
/// **关键点**：
/// - 使用 `expr_to_knf` 处理条件
/// - 合并条件可能产生的语句
/// - 条件表达式作为 if 的第一个参数
///
/// #### Then 块处理
/// ```
/// let then_knf_block = self.block_expr_to_knf(if_expr.then_block)
/// ```
///
/// **关键点**：
/// - 使用 `block_expr_to_knf` 处理 then 块
/// - then 块总是存在的
/// - 结果直接作为 if 的第二个参数
///
/// #### Else 块处理（核心挑战）
/// ```
/// match if_expr.else_block {
///   Some(Left(else_if_expr)) => {
///     // 处理 else if：递归调用 if_expr_to_knf
///     let (else_stmts, nested_if_knf) = self.if_expr_to_knf(else_if_expr)
///     stmts.append(else_stmts)
///     KnfBlock::{ stmts: [KnfStmt::ExprStmt(nested_if_knf)] }
///   }
///   Some(Right(else_block_expr)) => {
///     // 处理 else 块：使用 block_expr_to_knf
///     self.block_expr_to_knf(else_block_expr)
///   }
///   None => {
///     // 没有 else：创建空的 KnfBlock
///     KnfBlock::{ stmts: [] }
///   }
/// }
/// ```
///
/// **关键点**：
/// - **else if 处理**：递归调用 `if_expr_to_knf`，将结果包装为 `ExprStmt`
/// - **else 块处理**：使用 `block_expr_to_knf` 直接处理
/// - **无 else 处理**：创建空的 `KnfBlock`
/// - **嵌套结构**：else if 被嵌套到 else 块中
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件包含了三种 If 表达式的转换：
///
/// ### 测试用例 1：简单 if-else
/// ```
/// if (y > 0) {
///   x = 10;
/// } else {
///   x = 20;
/// }
/// ```
///
/// **转换结果**：
/// - 条件：`Binary(GT, y, tmp)`（其中 tmp 是 0 的临时变量）
/// - Then 块：`[Assign(x, Int(10))]`
/// - Else 块：`[Assign(x, Int(20))]`
///
/// ### 测试用例 2：只有 if，没有 else
/// ```
/// if (x < 5) {
///   print_int(x);
/// }
/// ```
///
/// **转换结果**：
/// - 条件：`Binary(LT, x, tmp)`（其中 tmp 是 5 的临时变量）
/// - Then 块：`[ExprStmt(Call(print_int, [x]))]`
/// - Else 块：`[]`（空块）
///
/// ### 测试用例 3：if-else if-else 链
/// ```
/// if x > 10 {
///   y
/// } else if x > 5 {
///   y + 1
/// } else {
///   y + 2
/// }
/// ```
///
/// **转换结果**：
/// - 外层条件：`Binary(GT, x, tmp1)`（其中 tmp1 是 10 的临时变量）
/// - Then 块：`[ExprStmt(Ident(y))]`
/// - Else 块：`[ExprStmt(If(nested_cond, nested_then, nested_else))]`
/// - 嵌套条件：`Binary(GT, x, tmp2)`（其中 tmp2 是 5 的临时变量）
///
/// **关键观察**：
/// - else if 被转换为嵌套的 If 表达式
/// - 嵌套的 If 被包装为 `ExprStmt`
/// - 保持了原始的嵌套结构
///
/// ## 💡 实现提示
///
/// 1. **条件处理**：使用 `expr_to_knf` 处理条件表达式
/// 2. **Then 块处理**：使用 `block_expr_to_knf` 处理 then 块
/// 3. **Else 块分发**：使用 `match` 处理 `Either` 类型
/// 4. **递归处理**：对 else if 使用递归调用
/// 5. **嵌套包装**：将嵌套的 if 包装为 `ExprStmt`
///
/// ## 🔮 设计思想
///
/// If 表达式的处理体现了以下设计思想：
///
/// - **统一结构**：将复杂的 else if 链转换为统一的 If 结构
/// - **递归处理**：使用递归处理嵌套的 else if
/// - **嵌套包装**：将嵌套结构包装为表达式语句
/// - **简化表示**：在 KNF 中简化条件控制流的表示
///
/// ## 🎯 开始实现吧！
///
/// 这是条件控制流处理的阶段！通过实现 `if_expr_to_knf` 函数，
/// 我们将完成条件分支的处理，为后续更复杂的控制流处理奠定基础。
///
/// **准备好处理条件控制流了吗？让我们开始实现！**
/// ================================================================================

///|
test "If Expr Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup type environment for testing
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("y", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })

  // Setup knf context
  let _ = knf_ctx.add_new_name("x", Int)
  let _ = knf_ctx.add_new_name("y", Int)
  knf_ctx.globals.set("print_int", Function([Int], Unit))

  // Test 1: Simple if-else expression: if (y > 0) { x = 10; } else { x = 20; }
  let code1 =
    #|if (y > 0) {
    #|  x = 10;
    #|} else {
    #|  x = 20;
    #|}
  let tokens1 = @lexer.tokenize(code1)
  let (if_expr1, _) = @parser.parse_if_expr(tokens1)
  let checked_if_expr1 = typecheck_ctx.check_if_expr(if_expr1)
  let (stmts1, knf_if_expr1) = knf_ctx.if_expr_to_knf(checked_if_expr1)

  // Test 1: Check that condition generates a statement for the literal 0
  assert_true(stmts1.length() is 1)
  assert_true(
    stmts1[0] is Let(tmp_name, Int, Int(0)) && tmp_name is { id: "tmp", .. },
  )

  // Test 1: Check the if expression structure
  assert_true(
    knf_if_expr1 is If(cond, then_block, else_block) &&
    cond is Binary(GT, y_name, tmp_cond) &&
    y_name is { id: "y", .. } &&
    tmp_cond is { id: "tmp", .. } &&
    then_block.stmts.length() is 1 &&
    then_block.stmts[0] is Assign(x_name1, Int(10)) &&
    x_name1 is { id: "x", .. } &&
    else_block.stmts.length() is 1 &&
    else_block.stmts[0] is Assign(x_name2, Int(20)) &&
    x_name2 is { id: "x", .. },
  )

  // Test 2: If without else: if (x < 5) { print_int(x); }
  let code2 =
    #|if (x < 5) {
    #|  print_int(x);
    #|}
  let tokens2 = @lexer.tokenize(code2)
  let (if_expr2, _) = @parser.parse_if_expr(tokens2)
  let checked_if_expr2 = typecheck_ctx.check_if_expr(if_expr2)
  let (stmts2, knf_if_expr2) = knf_ctx.if_expr_to_knf(checked_if_expr2)

  // Test 2: Check that condition generates a statement for the literal 5
  assert_true(stmts2.length() is 1)
  assert_true(
    stmts2[0] is Let(tmp_name2, Int, Int(5)) &&
    tmp_name2 is { id: "tmp", slot: 1 },
  )

  // Test 2: Check the if expression structure (no else block)
  assert_true(
    knf_if_expr2 is If(cond2, then_block2, else_block2) &&
    cond2 is Binary(LT, x_name3, tmp_cond2) &&
    x_name3 is { id: "x", .. } &&
    tmp_cond2 is { id: "tmp", slot: 1 } &&
    then_block2.stmts.length() is 1 &&
    then_block2.stmts[0] is ExprStmt(Call(print_func, [x_arg])) &&
    print_func is { id: "print_int", .. } &&
    x_arg is { id: "x", .. } &&
    else_block2.stmts.is_empty(),
  )

  // Test 3: If-else if-else chain
  let code3 =
    #|if x > 10 {
    #|  y
    #|} else if x > 5 {
    #|  y + 1
    #|} else {
    #|  y + 2
    #|}
  let tokens3 = @lexer.tokenize(code3)
  let (if_expr3, _) = @parser.parse_if_expr(tokens3)
  let checked_if_expr3 = typecheck_ctx.check_if_expr(if_expr3)
  let (stmts3, knf_if_expr3) = knf_ctx.if_expr_to_knf(checked_if_expr3)

  // Test 3: Check that condition generates a statement for the literal 10
  assert_true(stmts3.length() is 2)
  assert_true(
    stmts3 is [s1, s2] &&
    s1 is Let(_, Int, Int(10)) &&
    s2 is Let(_, Int, Int(5)),
  )
  assert_true(
    knf_if_expr3 is If(cond3, then_block3, else_block3) &&
    cond3 is Binary(GT, _, _) &&
    then_block3.stmts is [_] &&
    else_block3.stmts is [ExprStmt(e1)] &&
    e1 is If(nested_cond, _, _) &&
    nested_cond is Binary(GT, _, _),
  )
}
