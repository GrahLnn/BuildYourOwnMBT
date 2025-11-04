/// ================================================================================
/// # 🏗️ 结构体定义的 KNF 转换
///
/// ## 🎯 什么是结构体定义？
///
/// 结构体定义是编程语言中定义复合数据类型的方式，它允许我们将多个相关的数据组合在一起。
/// 结构体定义的基本结构是：
/// struct StructName {
///   field1: Type1;
///   field2: Type2;
///   mut field3: Type3;
/// }
///
/// 结构体定义的特点：
/// - 定义了一个新的数据类型
/// - 包含多个字段，每个字段有名称和类型
/// - 字段可以是可变的（mut）或不可变的
/// - 结构体定义本身不产生运行时代码，只是类型定义
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，结构体定义的结构相对简单：
/// - `name`: 结构体名称（String）
/// - `fields`: 字段列表（Array[StructField]）
///
/// 在 KNF 中，结构体定义的结构更加统一：
/// - `KnfStructDef`: 包含 name 和 fields 的结构体
/// - `fields`: 字段列表，每个字段包含（字段名，是否可变，字段类型）
///
/// ## 🛠️ 实现思路
///
/// 实现 `struct_def_to_knf` 函数需要两个主要步骤：
///
/// ### 1. 字段转换
/// - 遍历结构体的所有字段
/// - 对每个字段，提取字段名、可变性和类型
/// - 使用 `typekind_to_knf` 转换字段类型
/// - 将字段信息存储为（字段名，是否可变，字段类型）的元组
///
/// ### 2. 构造结构体定义
/// - 创建 `KnfStructDef` 结构
/// - 设置结构体名称和转换后的字段列表
/// - 返回转换后的结构体定义
///
/// ## 🔧 关键实现细节
///
/// ### 字段信息提取
/// 从 `StructField` 中提取字段信息：
/// - `name`: 字段名称
/// - `ty.kind`: 字段类型
/// - `ty.mutable`: 字段是否可变
///
/// ### 类型转换
/// 使用 `typekind_to_knf` 将字段类型转换为 KNF 类型：
/// - Int -> Int
/// - String -> String
/// - Double -> Double
/// - 其他类型按需转换
///
/// ### 字段存储
/// 将字段信息存储为元组格式：
/// (字段名: String, 是否可变: Bool, 字段类型: Type)
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单结构体
/// struct Point {
///   x: Int;
///   y: Int;
/// }
/// 转换过程：
/// 1. 结构体名称：Point
/// 2. 字段列表：[(x, false, Int), (y, false, Int)]
/// 3. 返回 KnfStructDef { name: "Point", fields: [...] }
///
/// ### 测试用例 2：包含可变字段的结构体
/// struct Person {
///   name: String;
///   age: Int;
///   mut score: Double;
/// }
/// 转换过程：
/// 1. 结构体名称：Person
/// 2. 字段列表：[(name, false, String), (age, false, Int), (score, true, Double)]
/// 3. 返回 KnfStructDef { name: "Person", fields: [...] }
///
/// ### 测试用例 3：空结构体
/// struct Empty {}
/// 转换过程：
/// 1. 结构体名称：Empty
/// 2. 字段列表：[]
/// 3. 返回 KnfStructDef { name: "Empty", fields: [] }
///
/// ## 💡 设计思想
///
/// ### 类型定义
/// 结构体定义是类型定义，不产生运行时代码，只是定义数据结构。
///
/// ### 字段信息保留
/// 保留字段的完整信息，包括名称、可变性和类型。
///
/// ### 类型统一
/// 将字段类型转换为统一的 KNF 类型表示。
///
/// ### 结构简化
/// 在 KNF 中简化结构体定义的表示，便于后续处理。
///
/// ## 🚀 实现挑战
///
/// ### 字段遍历
/// 需要正确遍历结构体的所有字段。
///
/// ### 类型转换
/// 需要正确转换字段类型为 KNF 类型。
///
/// ### 信息提取
/// 需要正确提取字段的名称、可变性和类型信息。
///
/// ## 🎯 实现目标
///
/// 完成 `struct_def.mbt` 中的 `struct_def_to_knf` 函数，实现结构体定义的 KNF 转换。
/// 函数应该：
/// 1. 正确遍历结构体的所有字段
/// 2. 正确提取字段的名称、可变性和类型信息
/// 3. 正确转换字段类型为 KNF 类型
/// 4. 返回统一的 KnfStructDef 结构
///
/// 现在让我们开始实现结构体定义的转换吧！🚀
///
/// ================================================================================

///|
test "Struct Def Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Put all code together
  let code =
    #|struct Point {
    #|  x: Int;
    #|  y: Int;
    #|}
    #|struct Person {
    #|  name: String;
    #|  age: Int;
    #|  mut score: Double;
    #|}
    #|struct Empty {}
  let tokens = @lexer.tokenize(code)

  // Test 1: Simple struct with two immutable fields
  let (struct_def1, tok_view) = @parser.parse_struct_def(tokens)
  let checked_struct_def1 = typecheck_ctx.check_struct_def(struct_def1)
  let knf_struct_def1 = knf_ctx.struct_def_to_knf(checked_struct_def1)
  assert_true(knf_struct_def1.name == "Point")
  assert_true(knf_struct_def1.fields.length() is 2)
  assert_true(
    knf_struct_def1.fields[0] is (field_name1, is_mut1, field_type1) &&
    field_name1 == "x" &&
    is_mut1 == false &&
    field_type1 is Int,
  )
  assert_true(
    knf_struct_def1.fields[1] is (field_name2, is_mut2, field_type2) &&
    field_name2 == "y" &&
    is_mut2 == false &&
    field_type2 is Int,
  )

  // Test 2: Struct with mutable field
  let (struct_def2, tok_view) = @parser.parse_struct_def(tok_view)
  let checked_struct_def2 = typecheck_ctx.check_struct_def(struct_def2)
  let knf_struct_def2 = knf_ctx.struct_def_to_knf(checked_struct_def2)
  assert_true(knf_struct_def2.name == "Person")
  assert_true(knf_struct_def2.fields.length() is 3)
  assert_true(
    knf_struct_def2.fields[0] is (field_name3, is_mut3, field_type3) &&
    field_name3 == "name" &&
    is_mut3 == false &&
    field_type3 is String,
  )
  assert_true(
    knf_struct_def2.fields[1] is (field_name4, is_mut4, field_type4) &&
    field_name4 == "age" &&
    is_mut4 == false &&
    field_type4 is Int,
  )
  assert_true(
    knf_struct_def2.fields[2] is (field_name5, is_mut5, field_type5) &&
    field_name5 == "score" &&
    is_mut5 == true &&
    field_type5 is Double,
  )

  // Test 3: Empty struct
  let (struct_def3, _) = @parser.parse_struct_def(tok_view)
  let checked_struct_def3 = typecheck_ctx.check_struct_def(struct_def3)
  let knf_struct_def3 = knf_ctx.struct_def_to_knf(checked_struct_def3)
  assert_true(knf_struct_def3.name == "Empty")
  assert_true(knf_struct_def3.fields.is_empty())
}
