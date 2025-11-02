/// ================================================================================
/// # 语法分析的终点：解析整个程序
///
/// 🎉 **祝贺你！你已经来到了语法分析阶段的最后一关！** 🎉
///
/// 我们已经分别构建了用于解析表达式、语句、类型和各种顶层声明的解析器。
/// 现在，是时候将它们全部整合起来，构建一个能够解析完整 MiniMoonBit 程序的最终 `parse` 函数了。
///
/// ## 什么是程序？
///
/// 在 MiniMoonBit 中，一个程序（`Program`）就是一系列顶层声明的集合。这些声明可以是：
/// *   顶层函数 (`TopFunction`)
/// *   顶层 `let` 绑定 (`TopLet`)
/// *   结构体定义 (`StructDef`)
///
/// ## 🎯 你的任务：实现最终的 `parse` 函数
///
/// 你的任务是在 `parser/parser.mbt` 中实现 `parse` 函数。
///
/// **请注意：** 这个最终的 `parse` 函数的签名与我们之前写的辅助函数有所不同。
/// 它接收的是一个完整的 `Array[Token]`，而不是 `ArrayView[Token]`。
///
/// **实现思路：**
///
/// 1.  **初始化：** 创建用于存储 `TopFunction`、`TopLet` 和 `StructDef` 的 `Map`。
///
/// 2.  **循环解析：**
///     *   启动一个循环，持续处理 Token 视图。
///     *   在循环的每一步，检查当前的 Token 是什么：
///         *   如果是 `fn` 关键字，调用 `parse_top_function`。
///         *   如果是 `let` 关键字，调用 `parse_top_let`。
///         *   如果是 `struct` 关键字，调用 `parse_struct_def`。
///     *   将解析得到的结果存入相应的 `Map` 中。
///     *   用剩余的 Token 继续下一次循环。
///
/// 3.  **终止条件：** 当你遇到 `EOF` Token 时，意味着所有源代码都已处理完毕，循环结束。
///
/// 4.  **组装 `Program`：** 最后，用填充好的 `Map` 创建并返回最终的 `Program` 对象。
///
/// ## 🚀 见证你的成果！
///
/// 完成这个任务后，你就拥有了一个功能完备的 MiniMoonBit 语法分析器！
/// 你可以找一个 `examples/` 目录下的 `.mbt` 文件，然后运行以下命令，亲眼看看你的解析器的工作成果：
///
/// ```bash
/// moon run main -- --file examples/nbody.mbt -stop-after=parse
/// ```
///
/// 这个命令会运行你的编译器，但在语法分析阶段结束后就停止，并打印出生成的 AST。
///
/// **再次祝贺你完成了语法分析这一重要的里程碑！接下来，我们将进入更激动人心的语义分析阶段！**
/// ================================================================================

///|
test "Parse Program Test" {
  let code =
    #|struct Circle {
    #|  radius: Double;
    #|}
    #|
    #|struct Rectangle {
    #|  a: Double;
    #|  b: Double;
    #|  c: Double;
    #|}
    #|
    #|let pi: Double = 3.14;
    #|
    #|fn area_circle(c: Circle) -> Double {
    #|  if c.radius < 0.0 {
    #|    return 0.0;
    #|  };
    #|  pi * c.radius * c.radius;
    #|}
    #|
    #|fn area_rectangle(r: Rectangle) -> Double {
    #|   let p = (r.a + r.b + r.c) / 2.0;
    #|   let x = p - r.a;
    #|   let y = p - r.b;
    #|   let z = p - r.c;
    #|   sqrt(p * x * y * z);
    #|}
    #|
    #|fn main {
    #|  let c = Circle::{ radius: 2.0 };
    #|  let r = Rectangle::{ a: 3.0, b: 4.0, c: 5.0 };
    #|  let ac = area_circle(c);
    #|  let ar = area_rectangle(r);
    #|  if ac > ar {
    #|    print_str("Circle area is larger");
    #|  } else {
    #|    print_str("Rectangle area is larger");
    #|  };
    #|}
  let tokens = @lexer.tokenize(code)
  let program = parse(tokens)
  assert_true(program.struct_defs.length() is 2)
  assert_true(program.top_lets.length() is 1)
  assert_true(program.top_functions.length() is 3)
  assert_true(program.struct_defs.get("Circle") is Some(_))
  assert_true(program.struct_defs.get("Rectangle") is Some(_))
  assert_true(program.top_lets.get("pi") is Some(_))
  assert_true(program.top_functions.get("area_circle") is Some(_))
  assert_true(program.top_functions.get("area_rectangle") is Some(_))
  assert_true(program.top_functions.get("main") is Some(_))
}
