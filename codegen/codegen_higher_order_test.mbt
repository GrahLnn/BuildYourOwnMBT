///|
test "Codegen Higher Order Function Call Test" {
  let code =
    #|fn is_positive(x: Int) -> Bool {
    #|  x > 0;
    #|}
    #|
    #|fn apply(f: (Int) -> Bool, x: Int) -> Bool {
    #|  f(x);
    #|}
    #|
    #|fn main {
    #|  let result = apply(is_positive, 5);
    #|}
  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let llvm_mod = codegen(knf_prog)
  println(llvm_mod)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)

  // 生成所有函数
  for _, func in knf_prog.functions {
    let _ = codegen_ctx.top_function_codegen(func)

  }

  // 验证 apply 函数正确处理了函数指针参数
  let apply_func = codegen_ctx.functions.get("apply").unwrap()
  let apply_ir = apply_func.to_string()

  // apply 函数应该能够调用传入的函数指针
  // 关键是要有 call 指令，且第一个参数是函数指针 %f
  inspect(apply_ir.contains("call"), content="true")
}

///|
test "Codegen Array of Functions Test" {
  let code =
    #|fn is_positive(x: Int) -> Bool {
    #|  x > 0;
    #|}
    #|
    #|fn is_negative(x: Int) -> Bool {
    #|  x < 0;
    #|}
    #|
    #|fn main {
    #|  let cond = [(fn(x: Int) -> Bool { x > 0; }), (fn(x: Int) -> Bool { x < 0; })];
    #|  let arr = [1, -2, 3];
    #|  let f = cond[0];
    #|  let result = f(arr[0]);
    #|  print_bool(result);
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

  // 验证 main 函数能够从数组中获取函数并调用
  let main_func = codegen_ctx.functions.get("main").unwrap()
  let main_ir = main_func.to_string()

  // 应该包含从数组获取函数指针的调用
  inspect(main_ir.contains("array_ptr_get"), content="true")

  // 应该包含函数调用
  inspect(main_ir.contains("call"), content="true")
}
