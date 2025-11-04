/// ================================================================================
/// # 🎯 可变 Let 语句的 KNF 变换：引入可变性
///
/// 在完成了表达式的转换之后，我们现在要开始处理**语句 (Statement)** 的转换。
/// 这是 KNF 变换的一个重要转折点，因为我们将从表达式处理转向语句处理。
///
/// ## 🌟 什么是 Let Mut 语句？
///
/// **Let Mut 语句**是声明可变变量的语句，它们的形式是：
///
/// ```
/// let mut x: Int = 10;        // 带类型注解的可变变量
/// let mut a = 42.0;          // 类型推断的可变变量
/// let mut y: Double = a + b; // 复杂初始化表达式的可变变量
/// ```
///
/// **Let Mut 语句的特点**：
/// - **可变性**：声明的变量可以在后续代码中被修改
/// - **初始化**：必须在声明时提供初始值
/// - **类型注解**：可以显式指定类型，也可以让编译器推断
/// - **作用域**：变量在声明的作用域内有效
///
/// ## 🔍 KNF 中的 Let Mut 语句
///
/// 在 KNF 中，Let Mut 语句被转换为 `KnfStmt::LetMut`：
///
/// ```
/// enum KnfStmt {
///   LetMut(Name, Type, KnfExpr)  // let mut name : Type = expr;
///   // ... 其他语句类型
/// }
/// ```
///
/// **转换过程**：
/// 1. 处理初始化表达式
/// 2. 创建变量名
/// 3. 转换类型信息
/// 4. 生成 KNF Let Mut 语句
///
/// ## 🎯 你的任务：实现 `let_mut_stmt_to_knf` 函数
///
/// 在这个测试中，你需要实现 `Context::let_mut_stmt_to_knf` 函数。
///
/// ### 💡 实现思路
///
/// 对于 Let Mut 语句的转换，核心步骤是：
///
/// 1. **处理初始化表达式**：使用 `expr_to_knf` 递归处理初始化表达式
/// 2. **合并语句**：将初始化表达式的语句合并到结果中
/// 3. **类型转换**：使用 `typekind_to_knf` 转换类型信息
/// 4. **创建变量名**：使用 `add_new_name` 创建变量名
/// 5. **生成语句**：创建 `KnfStmt::LetMut` 语句
///
/// **关键观察**：
/// - Let Mut 语句的转换相对简单，主要是委托给表达式转换
/// - 需要正确处理初始化表达式可能产生的语句
/// - 变量名通过 `add_new_name` 创建，确保作用域管理正确
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件包含了多种 Let Mut 语句的转换：
///
/// 1. **简单字面量**：`let mut x: Int = 10;` → `LetMut(x, Int, Int(10))`
/// 2. **类型推断**：`let mut a = 42.0;` → `LetMut(a, Double, Double(42.0))`
/// 3. **复杂表达式**：`let mut y: Double = a + b;` → `LetMut(y, Double, Binary(Add, a, b))`
///
/// **关键验证点**：
/// - 变量名是否正确创建
/// - 类型信息是否正确转换
/// - 初始化表达式是否正确处理
/// - 语句结构是否正确
///
/// ## 💡 实现提示
///
/// 1. **表达式处理**：使用 `expr_to_knf` 处理初始化表达式
/// 2. **语句合并**：使用 `append` 合并初始化表达式的语句
/// 3. **类型转换**：使用 `typekind_to_knf` 转换类型
/// 4. **变量创建**：使用 `add_new_name` 创建变量名
/// 5. **语句生成**：使用 `KnfStmt::LetMut` 创建语句
///
/// ## 🔮 与 Let 语句的区别
///
/// Let Mut 语句与普通的 Let 语句的主要区别：
///
/// - **可变性**：Let Mut 声明的变量可以被修改，Let 声明的变量不可变
/// - **KNF 表示**：Let Mut 使用 `LetMut`，Let 使用 `Let`
/// - **后续处理**：Let Mut 变量可以用于赋值语句，Let 变量不能
///
/// ## 🎯 开始实现吧！
///
/// 这是语句转换的第一个阶段！通过实现 Let Mut 语句的转换，
/// 我们将为后续更复杂的语句处理奠定基础。
///
/// **准备好开始语句转换之旅了吗？让我们开始实现！**
/// ================================================================================

///|
test "Let Mut Knf Transformation Test" {
  // Prelucde Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()
  // Test Parts
  let code =
    #|let mut x: Int = 10;
    #|let mut a = 42.0;
    #|let mut b = 33.0;
    #|let mut y: Double = a + b;
  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)
  // Parse and transform `let mut x: Int = 10;`
  let (stmt, tok_view) = @parser.parse_let_mut_stmt(tokens)
  let stmt = typecheck_ctx.check_let_mut_stmt(stmt)
  let knf_stmts = knf_ctx.let_mut_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is LetMut(name1, Int, init_expr) &&
    name1 is { id: "x", .. } &&
    init_expr is Int(10),
  )
  // Parse and transform `let mut a = 42.0;`
  let (stmt1, tok_view) = @parser.parse_let_mut_stmt(tok_view)
  let stmt1 = typecheck_ctx.check_let_mut_stmt(stmt1)
  let knf_stmts1 = knf_ctx.let_mut_stmt_to_knf(stmt1)
  assert_true(
    knf_stmts1 is [s1] &&
    s1 is LetMut(name_a, Double, init_expr1) &&
    name_a is { id: "a", .. } &&
    init_expr1 is Double(42.0),
  )
  // Parse and transform `let mut b = 33.0;`
  let (stmt_b, tok_view) = @parser.parse_let_mut_stmt(tok_view)
  let stmt_b = typecheck_ctx.check_let_mut_stmt(stmt_b)
  let knf_stmts_b = knf_ctx.let_mut_stmt_to_knf(stmt_b)
  assert_true(
    knf_stmts_b is [s_b] &&
    s_b is LetMut(name_b, Double, init_expr_b) &&
    name_b is { id: "b", .. } &&
    init_expr_b is Double(33.0),
  )
  // Parse and transform `let mut y: Double = a + b;`
  let (stmt2, _) = @parser.parse_let_mut_stmt(tok_view)
  let stmt2 = typecheck_ctx.check_let_mut_stmt(stmt2)
  let knf_stmts2 = knf_ctx.let_mut_stmt_to_knf(stmt2)
  assert_true(
    knf_stmts2 is [s2] &&
    s2 is LetMut(name2, Double, init_expr2) &&
    name2 is { id: "y", .. } &&
    init_expr2 is Binary(Add, left, right) &&
    left is { id: "a", .. } &&
    right is { id: "b", .. },
  )
}
