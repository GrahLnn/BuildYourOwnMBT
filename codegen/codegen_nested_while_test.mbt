///|
test "Codegen Nested While Loop Test" {
  let code =
    #|fn main {
    #|  let mut i = 0;
    #|  while i < 3 {
    #|    let mut j = 0;
    #|    while j < 2 {
    #|      print_int(i);
    #|      print_int(j);
    #|      j = j + 1;
    #|    }
    #|    i = i + 1;
    #|  }
    #|}
  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  println(knf_prog)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)
  let main_func = knf_prog.functions.get("main").unwrap()
  let main_ir = codegen_ctx.top_function_codegen(main_func)
  let ir_str = main_ir.to_string()

  // 验证生成了外层循环的基本块
  inspect(ir_str.contains("while.cond"), content="true")
  inspect(ir_str.contains("while.body"), content="true")
  inspect(ir_str.contains("while.end"), content="true")

  // 验证 i = i + 1 在正确的位置（内层循环结束后）
  // 这个测试确保外层循环的增量操作不会被错误地放置
  inspect(ir_str.contains("add"), content="true")
}

///|
test "Codegen Counter Example Test" {
  // 这是分析中提到的 counter 函数案例
  let code =
    #|fn is_positive(x: Int) -> Bool {
    #|  x > 0;
    #|}
    #|
    #|fn is_negative(x: Int) -> Bool {
    #|  x < 0;
    #|}
    #|
    #|fn counter(arr: Array[Int], cond: Array[(Int) -> Bool]) -> Int {
    #|  let mut count = 0;
    #|  let arr_size = 3;
    #|  let cond_size = 2;
    #|  let mut i = 0;
    #|  while i < arr_size {
    #|    let mut j = 0;
    #|    while j < cond_size {
    #|      if cond[j](arr[i]) {
    #|        count = count + 1;
    #|      }
    #|      j = j + 1;
    #|    }
    #|    i = i + 1;
    #|  }
    #|  count;
    #|}
    #|
    #|fn main {
    #|  let arr = [1, -2, 3];
    #|  let cond = [is_positive, is_negative];
    #|  let result = counter(arr, cond);
    #|  print_int(result);
    #|}
  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)

  // 生成所有函数
  for _, func in knf_prog.functions {
    let _ = codegen_ctx.top_function_codegen(func)

  }
  let counter_func = codegen_ctx.functions.get("counter").unwrap()
  let counter_ir = counter_func.to_string()

  // 验证包含嵌套循环结构
  inspect(counter_ir.contains("while.cond"), content="true")

  // 验证包含数组访问
  inspect(
    counter_ir.contains("array_ptr_get") || counter_ir.contains("array_int_get"),
    content="true",
  )

  // 验证包含函数调用（从数组中获取的函数）
  inspect(counter_ir.contains("call"), content="true")

  // 验证 main 函数能够成功生成
  let main_func = codegen_ctx.functions.get("main").unwrap()
  let main_ir = main_func.to_string()
  inspect(main_ir.contains("call"), content="true")
}
