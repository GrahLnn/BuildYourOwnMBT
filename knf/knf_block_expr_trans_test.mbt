/// ================================================================================
/// # 🎯 块表达式的 KNF 变换：语句序列的处理
///
/// 在完成了语句的统一分发之后，我们现在要处理**块表达式 (Block Expression)** 的转换。
/// 这是 KNF 变换中的一个重要组件，因为它处理语句序列和代码块的结构。
///
/// ## 🌟 什么是块表达式？
///
/// **块表达式**是由花括号包围的语句序列，它们的形式是：
///
/// ```
/// {
///   let x: Int = 10;
///   let mut y: Double = 3.14;
///   z = 42;
///   print_int(z);
///   return z;
/// }
/// ```
///
/// **块表达式的特点**：
/// - **语句序列**：包含多个语句，按顺序执行
/// - **作用域**：创建新的作用域，变量在其中有效
/// - **返回值**：最后一个语句的值作为块表达式的值
/// - **副作用**：语句可能产生副作用（赋值、函数调用等）
///
/// ## 🔍 块表达式的处理策略
///
/// 块表达式的转换相对简单，主要采用**循环遍历**的策略：
///
/// ### 核心思想：顺序处理
///
/// 对于块表达式中的每个语句：
/// 1. **顺序处理**：按照语句在代码中的顺序依次处理
/// 2. **语句转换**：使用 `stmt_to_knf` 将每个语句转换为 KNF 形式
/// 3. **结果合并**：将所有语句的 KNF 结果合并到一个语句列表中
/// 4. **块构造**：用合并后的语句列表构造 `KnfBlock`
///
/// ### 处理流程
///
/// ```
/// {
///   stmt1;  // -> knf_stmts1
///   stmt2;  // -> knf_stmts2
///   stmt3;  // -> knf_stmts3
/// }
/// ```
///
/// **转换过程**：
/// 1. 处理 `stmt1`，得到 `knf_stmts1`
/// 2. 处理 `stmt2`，得到 `knf_stmts2`
/// 3. 处理 `stmt3`，得到 `knf_stmts3`
/// 4. 合并所有语句：`[knf_stmts1, knf_stmts2, knf_stmts3]`
/// 5. 构造 `KnfBlock`
///
/// ## 🎯 你的任务：实现 `block_expr_to_knf` 函数
///
/// 在这个测试中，你需要实现 `Context::block_expr_to_knf` 函数。
///
/// ### 💡 实现思路
///
/// 块表达式的转换采用**循环遍历**的策略：
///
/// 1. **初始化**：创建空的语句列表
/// 2. **循环处理**：遍历块表达式中的每个语句
/// 3. **语句转换**：对每个语句调用 `stmt_to_knf`
/// 4. **结果合并**：将转换结果合并到语句列表中
/// 5. **块构造**：用合并后的语句列表构造 `KnfBlock`
///
/// ### 🔧 关键实现细节
///
/// #### 循环遍历的实现
/// ```
/// for stmt in expr.stmts {
///   let knf_stmts = self.stmt_to_knf(stmt)
///   stmts.append(knf_stmts)
/// }
/// ```
///
/// **关键点**：
/// - 使用 `for` 循环遍历语句列表
/// - 对每个语句调用 `stmt_to_knf`
/// - 使用 `append` 合并语句列表
/// - 保持语句的原始顺序
///
/// #### KnfBlock 的构造
/// ```
/// KnfBlock::{ stmts }
/// ```
///
/// **关键点**：
/// - `KnfBlock` 只包含语句列表
/// - 不需要额外的类型信息
/// - 语句的顺序很重要
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件包含了一个复杂的块表达式转换：
///
/// ### 测试块表达式：
/// ```
/// {
///   let x: Int = 10;        // LetStmt
///   let mut y: Double = 3.14;  // LetMutStmt
///   let mut z: Int = 0;    // LetMutStmt
///   z = 42;                // AssignStmt
///   print_int(z);          // ExprStmt
///   return z;              // ReturnStmt
/// }
/// ```
///
/// ### 转换结果分析：
///
/// **语句 1**：`let x: Int = 10;`
/// - 转换结果：`Let(x, Int, Int(10))`
/// - 特点：简单的 Let 语句
///
/// **语句 2**：`let mut y: Double = 3.14;`
/// - 转换结果：`LetMut(y, Double, Double(3.14))`
/// - 特点：Let Mut 语句
///
/// **语句 3**：`let mut z: Int = 0;`
/// - 转换结果：`LetMut(z, Int, Int(0))`
/// - 特点：Let Mut 语句
///
/// **语句 4**：`z = 42;`
/// - 转换结果：`Assign(z, Int(42))`
/// - 特点：简单的赋值语句
///
/// **语句 5**：`print_int(z);`
/// - 转换结果：`ExprStmt(Call(print_int, [z]))`
/// - 特点：表达式语句，函数调用
///
/// **语句 6**：`return z;`
/// - 转换结果：`Return(Ident(z))`
/// - 特点：返回语句
///
/// ## 💡 实现提示
///
/// 1. **循环遍历**：使用 `for` 循环遍历语句列表
/// 2. **语句转换**：对每个语句调用 `stmt_to_knf`
/// 3. **结果合并**：使用 `append` 合并语句列表
/// 4. **顺序保持**：确保语句按原始顺序处理
/// 5. **块构造**：用合并后的语句列表构造 `KnfBlock`
///
/// ## 🔮 设计思想
///
/// 块表达式的处理体现了以下设计思想：
///
/// - **顺序性**：语句按顺序执行，保持原始顺序
/// - **组合性**：将多个语句组合成一个块
/// - **委托性**：将具体语句的处理委托给 `stmt_to_knf`
/// - **简单性**：处理逻辑相对简单，主要是循环和合并
///
/// ## 🎯 开始实现吧！
///
/// 这是块表达式处理的阶段！通过实现 `block_expr_to_knf` 函数，
/// 我们将完成语句序列的处理，为后续更复杂的控制流处理奠定基础。
///
/// **准备好处理语句序列了吗？让我们开始实现！**
/// ================================================================================

///|
test "Block Expr Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup type environment for testing
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })

  // For return statement
  typecheck_ctx.current_func_ret_ty = Some(Int)

  // Setup knf context
  knf_ctx.globals.set("print_int", Function([Int], Unit))

  // Test Parts
  let code =
    #|{
    #|  let x: Int = 10;
    #|  let mut y: Double = 3.14;
    #|  let mut z : Int = 0;
    #|  z = 42;
    #|  print_int(z);
    #|  return z;
    #|}

  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)
  let (stmt, _) = @parser.parse_block_expr(tokens)
  let checked_block = typecheck_ctx.check_block_expr(stmt)
  let knf_block = knf_ctx.block_expr_to_knf(checked_block)
  assert_true(knf_block.stmts.length() is 6)

  // Test 1: Parse and transform `let x: Int = 10;`
  assert_true(
    knf_block.stmts[0] is Let(name1, Int, init_expr) &&
    name1 is { id: "x", .. } &&
    init_expr is Int(10),
  )

  // Test 2: Parse and transform `let mut y: Double = 3.14;`
  assert_true(
    knf_block.stmts[1] is LetMut(name2, Double, init_expr2) &&
    name2 is { id: "y", .. } &&
    init_expr2 is Double(3.14),
  )

  // Test 3: Parse and transform `let mut z : Int = 0;`
  assert_true(
    knf_block.stmts[2] is LetMut(name3, Int, init_expr3) &&
    name3 is { id: "z", .. } &&
    init_expr3 is Int(0),
  )

  // Test 4: Parse and transform `z = 42;`
  assert_true(
    knf_block.stmts[3] is Assign(name3, expr3) &&
    name3 is { id: "z", .. } &&
    expr3 is Int(42),
  )

  // Test 4: Parse and transform `print_int(z);` (ExprStmt)
  assert_true(
    knf_block.stmts[4] is ExprStmt(call_expr) &&
    call_expr is Call(func, args) &&
    func is { id: "print_int", .. } &&
    args is [arg] &&
    arg is { id: "z", .. },
  )

  // Test 5: Parse and transform `return z;` (ReturnStmt)
  assert_true(
    knf_block.stmts[5] is Return(return_expr) &&
    return_expr is Ident({ id: "z", .. }),
  )
}
