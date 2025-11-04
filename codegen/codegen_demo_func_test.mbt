/// ================================================================================
/// # LLVM Codegen
//
// 在我们深入代码生成之前，理解两个核心概念至关重要：SSA 和 LLVM。
//
// ## 静态单赋值（Static Single Assignment, SSA）
//
// SSA 是一种中间表示（IR）的特性，它要求每个变量都只被赋值一次。
// 如果在原始代码中一个变量被多次赋值，那么在 SSA 形式中，每次赋值都会创建一个新的、带版本号的变量。
//
// 例如，下面的代码：
//
// ```
// let mut x = 1;
// x = x + 1;
// ```
//
// 在 SSA 形式下会变成：
//
// ```
// x_1 = 1;
// x_2 = x_1 + 1;
// ```
//
// **为什么 SSA 如此重要？**
//
// 这种形式极大地简化了编译器的优化过程。例如：
// - **常量传播**：如果 `x_1` 是一个常量，编译器可以立即将所有使用 `x_1` 的地方替换为该常量。
// - **死码消除**：如果一个变量（如 `x_2`）从未被使用过，编译器可以安全地移除创建它的那行代码。
//
// 我们的 KNF（Kernel Normal Form）中间表示就是为生成 SSA 形式的代码做准备的。
//
// ## LLVM：现代编译器的基石
//
// LLVM 最初是“底层虚拟机”（Low Level Virtual Machine）的缩写，但现在它已经发展成为一个庞大的、
// 包含一系列模块化和可重用编译器及工具链技术的总称。它不仅仅是一个编译器，更是一个“编译器的编译器”。
//
// **LLVM 的核心是其强大且定义良好的中间表示（LLVM IR），而 LLVM IR 正是基于 SSA 的。**
//
// **工作流程：**
//
// 1.  **前端（Frontend）**：像我们正在构建的 MiniMoonBit 编译器，负责将源代码（`.mbt` 文件）解析、类型检查，并转换为中间表示（我们的 KNF）。
// 2.  **中间表示转换**：我们将 KNF 转换为 LLVM IR。
// 3.  **LLVM 优化器（Optimizer）**：LLVM 会对生成的 IR 进行大量的优化，使其更高效。
// 4.  **后端（Backend）/代码生成器（Code Generator）**：LLVM 将优化后的 IR 转换为特定硬件平台（如 x86, ARM）的机器码。
//
// 通过利用 LLVM，我们无需从零开始编写复杂的优化算法和针对不同硬件的代码生成器，
// 而是可以站在巨人的肩膀上，生成高质量、高性能的机器码。
//
// 在接下来的挑战中，你将亲手使用 MoonBit 的 LLVM API 来将 KNF 转换为 LLVM IR。
//
// 跟着下面的指引完成任务吧。
/// ================================================================================

///|
///
/// demo_add创建了一个简单的LLVM函数来添加两个整数。
/// 如果我们写C代码，就像这样：
///
/// ```c
/// int add(int a, int b) {
///   return a + b;
/// }
/// ```
///
/// 你的任务是实现demo_add下面的demo_fma代码，逻辑为：
///
/// ```c
/// double fma(double a, double b, double c) {
///   return a * b + c;
/// }
/// ```
///
/// 提示：
///
/// - 使用 `getDoubleTy` 来获取 double 类型。
/// - 使用 `createFMul` 来创建浮点乘法指令。
/// - 使用 `createFAdd` 来创建浮点加法指令。
fn demo_add() -> @llvm.Function raise {
  // Context是LLVM的核心对象，管理着所有的LLVM数据结构。
  // 例如类型、模块和指令生成器等。
  let ctx = @llvm.Context::new();

  // 使用context来创建一个模块。模块是LLVM中代码的容器。
  let mod = ctx.addModule("demo")

  // 指令生成器用于在基本块中生成LLVM指令。
  // 记得在生成指令前设置插入点。
  // 使用`setInsertPoint`方法设置插入点。`
  let builder = ctx.createBuilder();

  // 创建函数类型和函数。使用`getInt32Ty`获取32位整数类型。
  let i32ty = ctx.getInt32Ty();

  // 使用`getFunctionType`创建函数类型，传入返回类型和参数类型列表。
  // 在原始的llvm C接口中，函数类型还需要一个布尔值参数表示是否是可变参数函数。
  // 在MoonBit中，这个参数被标记成label参数，允许省略。
  // 在我们的教程中，所有函数都不是可变参数函数，所以可以省略这个参数。
  let fn_type = ctx.getFunctionType(i32ty, [i32ty, i32ty]);

  // 创建函数对象，注意函数在模块中创建。
  // 因此需要调用的是模块的方法`addFunction`。
  let fval = mod.addFunction(fn_type, "add");

  // 创建基本块对象，注意基本块在函数中创建。
  // 因此需要调用的是函数的方法`addBasicBlock`。
  let entry_bb = fval.addBasicBlock(name="entry");

  // 接下来在基本块中生成指令。需要使用builder来构建指令，在构建指令前需要设置插入点。
  builder.setInsertPoint(entry_bb);

  // 获得参数，我们已经知道函数有两个参数，因此直接使用getArg(index).unwrap()来获取参数。
  // getArg之后unwrap，得到的类型是一个`&Value`，它是一个trait Object。在llvm里，我们会有
  // 很多种不同的Value，例如指令，常量，函数参数等，它们都实现了Value这个trait。
  let arg0 = fval.getArg(0).unwrap();
  let arg1 = fval.getArg(1).unwrap();

  // 创建加法指令，使用createAdd方法。所有的指令创建方法都在builder对象上。
  // 它接收两个`&Value`参数，有一个label argument用于给指令命名。
  // 你可以省略label argument.
  //
  // 注意，createAdd方法接收的两个参数必须是整数类型。且类型需要一致，如果不一致，会出现运行时
  // 错误。
  //
  // 如果是浮点数加法，需要使用createFAdd方法，其他类似。
  let sum = builder.createAdd(arg0, arg1, name="sum");

  // 创建返回指令，使用createRet方法，注意createRet方法会返回一个指令对象，
  // 但我们这里不需要使用它，因此使用let _来忽略它。
  let _ = builder.createRet(sum);

  // 返回函数对象。
  // 如果你调用这个函数生成LLVM IR代码，可以看到生成的代码如下：
  //
  // ```llvm
  // ; ModuleID = 'demo'
  //
  // define i32 @add(i32 %0, i32 %1) {
  // entry:
  //  %sum = add i32 %0, %1
  //  ret i32 %sum
  // }
  // ```
  fval
}

///|
fn demo_fma() -> @llvm.Function raise {
  let ctx = @llvm.Context::new();
  let mod = ctx.addModule("demo_fma")
  let builder = ctx.createBuilder();

  let double_ty = ctx.getDoubleTy();
  let fn_type = ctx.getFunctionType(double_ty, [double_ty, double_ty, double_ty]);
  let fval = mod.addFunction(fn_type, "fma");
  let entry_bb = fval.addBasicBlock(name="entry");
  builder.setInsertPoint(entry_bb);

  let arg0 = fval.getArg(0).unwrap();
  let arg1 = fval.getArg(1).unwrap();
  let arg2 = fval.getArg(2).unwrap();

  let mul = builder.createFMul(arg0, arg1, name="mul");
  let result = builder.createFAdd(mul, arg2, name="result");

  let _ = builder.createRet(result);

  fval
}


///|
test "LLVM Codegen Demo Test" {
  let add = demo_add();
  inspect(
    add, 
    content = (
      #|define i32 @add(i32 %0, i32 %1) {
      #|entry:
      #|  %sum = add i32 %0, %1
      #|  ret i32 %sum
      #|}
      #|
    )
  )
  let fadd = demo_fma();
  inspect(
    fadd, 
    content = (
      #|define double @fma(double %0, double %1, double %2) {
      #|entry:
      #|  %mul = fmul double %0, %1
      #|  %result = fadd double %mul, %2
      #|  ret double %result
      #|}
      #|
    )
  )
}

