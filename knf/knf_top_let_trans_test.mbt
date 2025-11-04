/// ================================================================================
/// # 🌍 顶层 Let 语句的 KNF 转换
///
/// ## 🎯 什么是顶层 Let 语句？
///
/// 顶层 Let 语句是程序中最顶层的变量声明，它们定义全局变量和常量。
/// 顶层 Let 语句的基本结构是：
/// let variable_name: Type = expression;
///
/// 与函数内的 Let 语句不同，顶层 Let 语句：
/// - 左边不是模式（Pattern），而是简单的标识符
/// - 声明的是全局变量，需要在全局作用域中注册
/// - 转换完成后需要注册到 Context 的 globals 字段中
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，顶层 Let 语句的结构相对简单：
/// - `name`: 变量名（String）
/// - `ty`: 类型（Type）
/// - `expr`: 初始化表达式（Expr）
///
/// 但在 KNF 中，顶层 Let 语句的结构更加统一：
/// - `KnfTopLet`: 包含 name、ty、expr 的结构体
/// - 变量名被转换为 `Name` 结构
/// - 类型被转换为 KNF 类型
/// - 表达式被转换为 KNF 表达式
///
/// ## 🛠️ 实现思路
///
/// 实现 `top_let_to_knf` 函数需要四个主要步骤：
///
/// ### 1. 表达式转换
/// - 使用 `expr_to_knf` 转换初始化表达式
/// - 收集表达式转换过程中产生的语句
///
/// ### 2. 类型转换
/// - 使用 `typekind_to_knf` 转换类型
/// - 确保类型一致性
///
/// ### 3. 重复声明检查
/// - 检查 globals 中是否已存在同名变量
/// - 如果存在，抛出重复声明错误
///
/// ### 4. 全局注册
/// - 使用 `add_new_name` 创建新的 Name
/// - 将变量注册到 globals 字段中
/// - 返回 `KnfTopLet` 结构
///
/// ## 🔧 关键实现细节
///
/// ### 全局变量管理
/// 顶层 Let 语句声明的变量需要注册到全局作用域：
/// let x: Int = 42;
/// 转换为：
/// - 创建 Name { id: "x", slot: 0 }
/// - 注册到 globals["x"] = Int
/// - 返回 KnfTopLet { name, ty: Int, expr: Int(42) }
///
/// ### 重复声明检查
/// 在注册全局变量之前，需要检查是否已存在：
/// guard self.globals.get(top_let.name) is None else {
///   raise KnfTransformError("Duplicate global variable declaration: ...")
/// }
///
/// ### 表达式处理
/// 初始化表达式可能包含复杂的计算，需要先转换为 KNF：
/// let sum = a + b;
/// 转换为：
/// - 表达式 a + b 转换为 KNF
/// - 创建全局变量 sum
/// - 注册到 globals
///
/// ### 类型一致性
/// 确保声明的类型与表达式的类型一致：
/// - 如果提供了类型注解，需要验证类型兼容性
/// - 如果没有类型注解，使用表达式的推断类型
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单类型注解
/// let x: Int = 42;
/// 转换过程：
/// 1. 表达式 42 转换为 Int(42)
/// 2. 类型 Int 保持不变
/// 3. 创建 Name { id: "x", slot: 0 }
/// 4. 注册到 globals["x"] = Int
///
/// ### 测试用例 2：类型推断
/// let y = 3.14;
/// 转换过程：
/// 1. 表达式 3.14 转换为 Double(3.14)
/// 2. 推断类型为 Double
/// 3. 创建 Name { id: "y", slot: 0 }
/// 4. 注册到 globals["y"] = Double
///
/// ### 测试用例 3：字符串类型
/// let s: String = "hello";
/// 转换过程：
/// 1. 表达式 "hello" 转换为 String("hello")
/// 2. 类型 String 保持不变
/// 3. 创建 Name { id: "s", slot: 0 }
/// 4. 注册到 globals["s"] = String
///
/// ### 测试用例 4：复杂表达式
/// let sum = a + b;
/// 转换过程：
/// 1. 表达式 a + b 转换为 Binary(Add, a_name, b_name)
/// 2. 推断类型为 Int
/// 3. 创建 Name { id: "sum", slot: 0 }
/// 4. 注册到 globals["sum"] = Int
///
/// ## 💡 设计思想
///
/// ### 全局作用域管理
/// 顶层 Let 语句声明的变量属于全局作用域，需要统一管理。
///
/// ### 重复声明防护
/// 通过检查 globals 字段，防止重复声明全局变量。
///
/// ### 类型安全
/// 确保声明的类型与表达式的类型一致，保证类型安全。
///
/// ### 统一结构
/// 将顶层 Let 语句转换为统一的 KnfTopLet 结构，便于后续处理。
///
/// ## 🚀 实现挑战
///
/// ### 全局变量管理
/// 需要正确管理全局变量的注册和查找，避免命名冲突。
///
/// ### 类型一致性检查
/// 需要确保声明的类型与表达式的类型一致。
///
/// ### 重复声明处理
/// 需要检查并防止重复声明全局变量。
///
/// ### 表达式复杂性
/// 初始化表达式可能包含复杂的计算，需要正确转换为 KNF。
///
/// ## 🎯 实现目标
///
/// 完成 `top_let.mbt` 中的 `top_let_to_knf` 函数，实现顶层 Let 语句的 KNF 转换。
/// 函数应该：
/// 1. 正确转换初始化表达式为 KNF
/// 2. 正确转换类型为 KNF 类型
/// 3. 检查重复声明并防止冲突
/// 4. 将变量注册到全局作用域
/// 5. 返回统一的 KnfTopLet 结构
///
/// 现在让我们开始实现顶层 Let 语句的转换吧！🚀
///
/// ================================================================================

///|
test "Top Let Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Test 1: Simple top-level let with type annotation: let x: Int = 42;
  let code =
    #|let x: Int = 42;
    #|let y = 3.14;
    #|let s: String = "hello";
    #|let a = 1;
    #|let b = 2;
    #|let sum = a + b;
  let tokens1 = @lexer.tokenize(code)
  // Test 1: Check the structure
  let (top_let1, tok_view) = @parser.parse_top_let(tokens1)
  let checked_top_let1 = typecheck_ctx.check_top_let(top_let1)
  let knf_top_let1 = knf_ctx.top_let_to_knf(checked_top_let1)
  assert_true(
    knf_top_let1.name is { id: "x", slot: 0 } &&
    knf_top_let1.ty is Int &&
    knf_top_let1.expr is Int(42),
  )

  // Test 2: Check the structure
  let (top_let2, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let2 = typecheck_ctx.check_top_let(top_let2)
  let knf_top_let2 = knf_ctx.top_let_to_knf(checked_top_let2)
  assert_true(
    knf_top_let2.name is { id: "y", slot: 0 } &&
    knf_top_let2.ty is Double &&
    knf_top_let2.expr is Double(3.14),
  )

  // Test 3: Top-level let with string: let s: String = "hello";
  let (top_let3, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let3 = typecheck_ctx.check_top_let(top_let3)
  let knf_top_let3 = knf_ctx.top_let_to_knf(checked_top_let3)

  // Test 3: Check the structure
  assert_true(
    knf_top_let3.name is { id: "s", slot: 0 } &&
    knf_top_let3.ty is String &&
    knf_top_let3.expr is String("hello"),
  )

  // Test 4: Top-level let with computation: let sum = 10 + 20;
  let (top_let, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let4 = typecheck_ctx.check_top_let(top_let)
  let _ = knf_ctx.top_let_to_knf(checked_top_let4)
  let (top_let, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let4 = typecheck_ctx.check_top_let(top_let)
  let _ = knf_ctx.top_let_to_knf(checked_top_let4)
  let (top_let4, _) = @parser.parse_top_let(tok_view)
  let checked_top_let4 = typecheck_ctx.check_top_let(top_let4)
  let knf_top_let4 = knf_ctx.top_let_to_knf(checked_top_let4)
  assert_true(
    knf_top_let4.name is { id: "sum", slot: 0 } &&
    knf_top_let4.ty is Int &&
    knf_top_let4.expr is Binary(Add, l, r) &&
    l is { id: "a", .. } &&
    r is { id: "b", .. },
  )
}
