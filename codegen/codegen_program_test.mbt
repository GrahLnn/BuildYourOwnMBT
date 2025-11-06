/// ================================================================================
/// # 🎉 最终章：完成代码生成器 🎉
/// ================================================================================
///
/// 恭喜你，你已经来到了我们编译器构建之旅的最后一站！
///
/// 我们已经分别实现了处理各种表达式、语句、函数和闭包的代码生成逻辑。
/// 现在，是时候将所有这些部分组装起来，创建一个能够将整个 KNF 程序转换为完整 LLVM 模块的总指挥函数了。
///
/// ## 🎯 你的最终任务：实现 `codegen` 函数
///
/// 本次挑战的目标是完成 `codegen/codegen.mbt` 文件中的主 `codegen` 函数。
/// 这个函数接收一个完整的 KNF 程序（`KnfProgram`），并返回一个最终的 LLVM 模块（`@llvm.Module`）。
///
/// ## 💡 实现指南：两阶段生成的总调度
///
/// `codegen` 函数的逻辑就是我们之前讨论过的“两阶段生成”策略的完整实现：
///
/// 1.  **创建 `Context`**:
///     `let codegen_ctx = Context::new(...)`
///
/// 2.  **第一阶段（收集）**:
///     在 `Context` 中注册所有顶层声明，但不要生成函数体。
///     - `codegen_ctx.collect_struct_types(knf_prog.struct_defs)`
///     - `codegen_ctx.collect_func_values(knf_prog.functions)`
///
/// 3.  **第二阶段（生成）**:
///     遍历所有函数，调用 `top_function_codegen` 为它们生成完整的函数体 IR。
///
/// 4.  **返回模块**:
///     从 `Context` 中返回最终构建好的 `llvm_mod`。
///
/// ---
///
/// ## 🏆 解锁成就：编译器的完整实现 🏆
///
/// 当 `codegen_program_test.mbt` 的测试通过时，请务必给自己一些掌声！
///
/// 你已经从零开始，一步一个脚印地完成了现代编译器中所有最核心的阶段：
///
/// **词法分析 -> 语法分析 -> 类型检查 -> KNF 变换 -> LLVM 代码生成**
///
/// 你构建的 MiniMoonBit 编译器现在可以将一门你亲手定义的语言，转化为工业级的、可执行的底层代码。
/// 这是一项了不起的成就，它证明了你对编程语言和计算机系统底层原理的深刻理解。
///
/// **感谢你的坚持与努力，现在，去完成最后的挑战，让你的编译器完整地运转起来吧！**
/// // 伪代码表示IR逻辑
// int counter(ptr, ptr arr, int arr_size, ptr cond, int cond_size) {
//     int cnt = 0; // %5
//     int i = 0;   // %7
//     // 外层循环：遍历整数数组 arr
//     while (i < arr_size) { // while.cond.0
//         int j = 0; // %13
//         // 内层循环：遍历函数数组 cond
//         while (j < cond_size) { // while.cond.1
//             // %22 = cond[j]
//             // %24 = arr[i]
//             // %25 = cond[j](arr[i])
//             if (cond[j](arr[i])) { // br i1 %25
//                 // 如果满足条件
//                 cnt = cnt + 1; // 31: ...
//                 // ！！！！关键点！！！！
//                 // IR在这里直接跳转到了内层循环的末尾(br label %38)
//                 // 它会继续 j = j + 1 并判断下一个条件
//             } else {
//                 // 如果不满足条件，也跳转到内层循环末尾(br label %38)
//             }
//             j = j + 1; // 38: ...
//         }
//         // 内层循环结束后，才会增加 i
//         i = i + 1; // while.end.1: ...
//     }
//     return cnt; // while.end.0
// }

///|
test "Codegen Closure Test" {
  let code =
    #|fn counter(arr: Array[Int], arr_size: Int, cond: Array[(Int) -> Bool], cond_size: Int) -> Int {
    #|  let mut cnt = 0;
    #|  let mut i = 0;
    #|  while i < arr_size {
    #|    let mut j = 0;
    #|    while j < cond_size {
    #|      if cond[j](arr[i]) {
    #|        cnt = cnt + 1;
    #|      };
    #|      j = j + 1;
    #|    }
    #|    i = i + 1;
    #|  }
    #|  cnt
    #|}
    #|
    #|fn main {
    #|  fn f(x) { x > 0 }
    #|  fn g(x) { x < 400 }
    #|
    #|  let arr = [1, 4, 9, 1000, 2500, 3150, 4000, 748, 45, -275, -115, 33];
    #|  let cond = [f, g];
    #|
    #|  let arr_size = 12;
    #|  let cond_size = 2;
    #|
    #|  let result = counter(arr, arr_size, cond, cond_size);
    #|}
  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let llvm_mod = codegen(knf_prog)
  println(llvm_mod)
}
