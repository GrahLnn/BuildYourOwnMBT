///|
///
/// 把这段函数看作一条“造电路”的工艺流程，它实际上在焊接一个**函数的信号框架**。我们一步步拆成电子学语言来理解。

/// ---

/// ### 一. “取第一阶段已声明的 LLVM 函数”

/// ```moonbit
/// let fval = self.functions.get(fname).unwrap()
/// ```

/// 在电路思维里，这一步不是“去找符号”，而是**从模块的元件库里取出已经贴在电路板上的接口壳**。
/// 第一阶段你已经为所有函数焊好了一排“插头”——只写明了引脚数量和类型，没有连任何线。
/// 现在你拿出其中一个插头准备往里焊逻辑门。

/// *比喻*：像你在电路板上拿到一个写着 `void @foo(ptr i32 double)` 的空函数壳，它只有接口，没有内部连线。

/// ---

/// ### 二. “建立入口基本块并设定插入点”

/// ```moonbit
/// let entry_bb = fval.addBasicBlock(name="entry")
/// self.builder.setInsertPoint(entry_bb)
/// ```

/// 这里就是在那个函数模块的内部**放置一块硅片区域**，标上“entry”，准备在这块上布线。
/// `setInsertPoint` 让“焊枪头”落到这里，后续的所有门电路都在这片区域焊接。
/// LLVM 的 IRBuilder 就是自动焊接机器人：你指给它哪一块板，它就在那焊。

/// ---

/// ### 三. “形参绑定到本地映射”

/// ```moonbit
/// let llvm_arg = fval.getArg(arg_idx).unwrap()
/// ```

/// 每个参数其实是一根**输入引脚**。
/// 在机器电路的世界中，这些参数是**已经带信号的导线**。你只需要把它们在本函数电路的内部命个名字，好知道后续哪根线对应外部哪个信号。

/// 这里做的不是复制或计算，而是“引脚映射”：
/// `%0`、`%1`、`%2` 是输入插针的序号，你把它们接到内部信号命名表上（`name_values`）。

/// 对 `main` 函数的区别：
/// 它没有“环境指针”，即不需要额外的输入电源线。其他函数则自动多一根 `env` 线，表示闭包上下文。

/// ---

/// ### 四. “生成函数体：空体返回”

/// ```moonbit
/// self.builder.createRetVoid()
/// ```

/// 在电路比喻中，这就是在输出端接上一根固定电平——没有计算逻辑，直接回到调用者。
/// `ret void` 等价于“这个模块没有输出信号，只是完成一趟流转”。
/// 对于 LLVM 来说，它必须看到一个终结信号，否则整个电路不闭合，会被验证器判定为“有悬空路径”。

/// ---

/// ### 五. “返回函数值”

/// ```moonbit
/// fval
/// ```

/// 此时你返回的是一个“焊好 entry 块、能通过电流的完整模块”。
/// 外部模块可以自由地调用它，就像把一块芯片插入主板上。
/// 主板（module）保存它的引脚定义、内部布线、终结电平，下一次调用时只要把输入信号接上对应的引脚。

/// ---

/// ### 六. 整体图像：构建函数电路

/// 如果把整个函数看成一个芯片：

/// ```
///            +------------------------+
///  ptr env  -| %0                 ret |-> void
///  i32 x    -| %1                     |
///  double y -| %2                     |
///            |  entry:                |
///            |    ret void            |
///            +------------------------+
/// ```

/// 1. **引脚定义**：来自第一阶段的函数声明
/// 2. **逻辑层（entry 块）**：你现在焊的是第一层逻辑。后续要生成算术门、比较门、控制开关等。
/// 3. **终结引脚**：`ret` 相当于输出锁存器。没有它，信号就“漂浮”。
/// 4. **环境指针 env**：是供电或上下文总线，闭包通过它携带状态。

/// ---

/// ### 七. 思维转变总结

/// | KNF 思考           | LLVM / 电路思考          |
/// | -------------     | --------------          |
/// | 语义节点（if, let） | 功能单元（门电路、寄存器）  |
/// | 变量名             | 信号线名（SSA 值）        |
/// | 执行顺序           | 信号传播路径              |
/// | 表达式求值          | 电流经过逻辑门输出结果     |
/// | 环境或作用域        | 电源/上下文总线           |
/// | 返回语句           | 输出端驱动信号并终止模块电流 |

/// 到这里为止，你写的 `top_function_codegen` 其实就是“在 LLVM 这块电路板上，焊好一个最简单的空函数芯片”。
/// 后面当你加上运算、判断、循环，它就会真正开始“导电”。

///|
/// 注意区分main函数与其他函数的codegen。
// 顶层函数：先编前 n-1 条，再做尾位返回
pub fn Context::top_function_codegen(
  self : Self,
  func : @knf.KnfFunction,
) -> @llvm.Function raise {
  let fname = func.name
  let fval = self.functions
    .get(fname)
    .unwrap_or_else(() => raise CodegenError(
      "function not declared in first pass",
    ))
  let entry_bb = fval.addBasicBlock(name="entry")
  self.builder.setInsertPoint(entry_bb)
  self.name_values.clear()
  self.name_types.clear()
  
  // 设置当前函数路径
  self.current_func_path = fname
  {
    let mut arg_idx : Int = 0
    if fname != "main" {
      let _env = fval.getArg(0).unwrap()
      arg_idx = 1
    }
    for param in func.params {
      let llvm_arg = fval.getArg(arg_idx).unwrap()
      self.name_values.set(param.0, llvm_arg)
      self.name_types.set(param.0, param.1)
      arg_idx += 1
    }
  }
  if func.body.stmts.length() > 1 {
    func.body.stmts[:-1].each(stmt => self.stmt_codegen(stmt))
  }
  let last = func.body.stmts.last()
  guard last is Some(last) else {
    let _ = self.builder.createRetVoid()
    return fval
  }
  match last {
    ExprStmt(e) => {
      let vopt = self.expr_codegen(e)
      match (func.ret_ty, vopt) {
        (Unit, _) => {
          let _ = self.builder.createRetVoid()

        }
        (_, Some(v)) => {
          let _ = self.builder.createRet(v)

        }
        (_, None) => ()
      }
    }
    ReturnUnit => {
      let _ = self.builder.createRetVoid()

    }
    Return(_) => raise CodegenError("Return with value not implemented yet")
    _ => {
      self.stmt_codegen(last)
      match func.ret_ty {
        Unit => {
          let _ = self.builder.createRetVoid()

        }
        _ => {
          let d = self.default_value(func.ret_ty)
          let _ = self.builder.createRet(d)

        }
      }
    }
  }
  fval
}
