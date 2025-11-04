/// ================================================================================
/// # 🔄 While 语句的 KNF 转换
///
/// ## 🎯 什么是 While 语句？
///
/// While 语句是编程语言中的循环控制结构，它允许程序重复执行一段代码，直到某个条件不再满足。
/// While 语句的基本结构是：
/// while (condition) {
///   // 循环体
/// }
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，While 语句的结构相对简单：
/// - `cond`: 条件表达式
/// - `body`: 循环体（BlockExpr）
///
/// 但在 KNF 中，While 语句的结构更加统一：
/// - `KnfStmt::While(cond_block, body_block)`
/// - 条件被包装在一个 `KnfBlock` 中
/// - 循环体也被包装在一个 `KnfBlock` 中
///
/// ## 🛠️ 实现思路
///
/// 实现 `while_stmt_to_knf` 函数需要三个主要步骤：
///
/// ### 1. 条件转换
/// - 使用 `expr_to_knf` 转换条件表达式
/// - 将条件语句包装为 `ExprStmt`
/// - 创建条件块 `KnfBlock`
///
/// ### 2. 循环体转换
/// - 使用 `block_expr_to_knf` 转换循环体
/// - 直接得到 `KnfBlock`
///
/// ### 3. 构造 While 语句
/// - 创建 `KnfStmt::While(cond_block, body_block)`
/// - 返回包含单个 While 语句的数组
///
/// ## 🔧 关键实现细节
///
/// ### 条件块处理
/// 条件表达式可能包含复杂的子表达式，需要先转换为 KNF：
/// while (i < 10) { ... }
/// 转换为：
/// let tmp = 10;
/// while (i < tmp) { ... }
///
/// ### 循环体处理
/// 循环体是一个 `BlockExpr`，直接使用 `block_expr_to_knf` 转换：
/// {
///   sum = sum + i;
///   i = i + 1;
/// }
/// 转换为：
/// {
///   sum = sum + i;
///   let tmp = 1;
///   i = i + tmp;
/// }
///
/// ### 统一结构
/// KNF 中的 While 语句结构统一为：
/// While(cond_block, body_block)
/// 其中：
/// - `cond_block`: 包含条件计算和条件表达式的语句块
/// - `body_block`: 包含循环体语句的语句块
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单循环
/// while (i < 10) {
///   sum = sum + i;
///   i = i + 1;
/// }
/// 转换过程：
/// 1. 条件 `i < 10` 转换为 `let tmp = 10; i < tmp`
/// 2. 循环体转换为包含赋值和增量操作的语句块
/// 3. 构造 `While(cond_block, body_block)`
///
/// ### 测试用例 2：带函数调用的循环
/// 
/// ```
/// while (x > 0) {
///   print_int(x);
///   x = x - 1;
/// }
/// ```
/// 转换过程：
/// 1. 条件 `x > 0` 转换为 `let tmp = 0; x > tmp`
/// 2. 循环体包含函数调用和递减操作
/// 3. 构造 `While(cond_block, body_block)`
///
/// ## 💡 设计思想
///
/// ### 统一结构
/// 将条件表达式包装在 `KnfBlock` 中，使得 While 语句的结构更加统一和一致。
///
/// ### 条件计算
/// 条件表达式中的复杂计算被提取为独立的语句，确保条件判断的原子性。
///
/// ### 循环体处理
/// 循环体作为 `BlockExpr` 直接转换，保持原有的语句结构。
///
/// ### 简化表示
/// 在 KNF 中简化循环控制流的表示，为后续的优化和代码生成做准备。
///
/// ## 🚀 实现挑战
///
/// ### 条件表达式复杂性
/// 条件表达式可能包含函数调用、复杂运算等，需要正确转换为 KNF 形式。
///
/// ### 循环体语句
/// 循环体中的语句需要正确转换，包括赋值、函数调用等。
///
/// ### 临时变量管理
/// 条件表达式中的临时变量需要正确管理，避免命名冲突。
///
/// ## 🎯 实现目标
///
/// 完成 `while_stmt.mbt` 中的 `while_stmt_to_knf` 函数，实现 While 语句的 KNF 转换。
/// 函数应该：
/// 1. 正确转换条件表达式为条件块
/// 2. 正确转换循环体为语句块
/// 3. 构造统一的 While 语句结构
/// 4. 处理复杂的条件表达式和循环体语句
///
/// 现在让我们开始实现 While 语句的转换吧！🚀
///
/// ================================================================================

///|
test "While Stmt Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup type environment for testing
  typecheck_ctx.type_env.set("i", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("sum", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })

  // Setup knf context
  let _ = knf_ctx.add_new_name("i", Int)
  let _ = knf_ctx.add_new_name("sum", Int)
  let _ = knf_ctx.add_new_name("x", Int)
  knf_ctx.globals.set("print_int", Function([Int], Unit))

  // Test 1: Simple while loop: while (i < 10) { sum = sum + i; i = i + 1; }
  let code1 =
    #|while (i < 10) {
    #|  sum = sum + i;
    #|  i = i + 1;
    #|}
  let tokens1 = @lexer.tokenize(code1)
  let (while_stmt1, _) = @parser.parse_while_stmt(tokens1)
  let checked_while_stmt1 = typecheck_ctx.check_while_stmt(while_stmt1)
  let knf_while_stmts1 = knf_ctx.while_stmt_to_knf(checked_while_stmt1)

  // Test 1: Check that we get a While statement
  assert_true(knf_while_stmts1.length() is 1)
  assert_true(knf_while_stmts1[0] is While(_, _))
  guard knf_while_stmts1[0] is While(cond_block, body_block)

  // Test 1: Check condition block (should have let for 10 and the condition expression)
  // Condition block should have: let tmp = 10; and i < tmp;
  assert_true(cond_block.stmts.length() is 2)
  assert_true(
    cond_block.stmts[0] is Let(tmp_name, Int, Int(10)) &&
    tmp_name is { id: "tmp", slot: 0 },
  )
  assert_true(
    cond_block.stmts[1] is ExprStmt(Binary(LT, i_name, tmp_cond)) &&
    i_name is { id: "i", .. } &&
    tmp_cond is { id: "tmp", slot: 0 },
  )

  // Body block should have:
  // 1. sum = sum + i; (no expansion needed, operands are identifiers)
  // 2. let tmp$1 : Int = 1; (extract literal)
  // 3. i = i + tmp$1; (assignment)
  assert_true(body_block.stmts.length() is 3)
  assert_true(
    body_block.stmts[0] is Assign(sum_name, Binary(Add, sum_name2, i_name2)) &&
    sum_name is { id: "sum", .. } &&
    sum_name2 is { id: "sum", .. } &&
    i_name2 is { id: "i", .. },
  )
  assert_true(
    body_block.stmts[1] is Let(tmp_lit, Int, Int(1)) &&
    tmp_lit is { id: "tmp", slot: 1 },
  )
  assert_true(
    body_block.stmts[2] is Assign(i_name3, Binary(Add, i_name4, tmp_add)) &&
    i_name3 is { id: "i", .. } &&
    i_name4 is { id: "i", .. } &&
    tmp_add is { id: "tmp", slot: 1 },
  )

  // Test 2: While with function call: while (x > 0) { print_int(x); x = x - 1; }
  let code2 =
    #|while (x > 0) {
    #|  print_int(x);
    #|  x = x - 1;
    #|}
  let tokens2 = @lexer.tokenize(code2)
  let (while_stmt2, _) = @parser.parse_while_stmt(tokens2)
  let checked_while_stmt2 = typecheck_ctx.check_while_stmt(while_stmt2)
  let knf_while_stmts2 = knf_ctx.while_stmt_to_knf(checked_while_stmt2)
  assert_true(knf_while_stmts2.length() is 1)
  guard knf_while_stmts2[0] is While(cond_block, body_block)

  // Test 2: Check structure
  // Condition block: let tmp = 0; x > tmp;
  assert_true(cond_block.stmts.length() is 2)
  assert_true(
    cond_block.stmts[0] is Let(_, Int, Int(0)) &&
    cond_block.stmts[1] is ExprStmt(Binary(GT, _, _)),
  )

  // Body block: print_int(x); x = x - 1;
  // Similar to test 1: print_int(x); let tmp = 1; x = x - tmp;
  assert_true(body_block.stmts.length() is 3)
  assert_true(body_block.stmts[0] is ExprStmt(Call(_, _)))
  assert_true(body_block.stmts[1] is Let(_, Int, Int(1)))
  assert_true(body_block.stmts[2] is Assign(_, Binary(Sub, _, _)))
}
