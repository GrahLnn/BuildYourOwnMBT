///|
pub fn codegen(knf_prog : @knf.KnfProgram) -> @llvm.Module raise {
  let codegen_ctx = Context::new("main")
  codegen_ctx.collect_struct_types(knf_prog.struct_defs)
  codegen_ctx.collect_func_values(knf_prog.functions)
  
  // 收集所有闭包定义
  let all_closures = codegen_ctx.collect_all_closures(knf_prog.functions)
  
  // 生成顶层函数
  for _, func in knf_prog.functions {
    let _ = codegen_ctx.top_function_codegen(func)
  }
  
  // 生成所有闭包函数
  for closure_pair in all_closures {
    let (closure_def, parent_path) = closure_pair
    let _ = codegen_ctx.generate_closure_function(closure_def, parent_path)
  }
  
  codegen_ctx.llvm_mod
}
