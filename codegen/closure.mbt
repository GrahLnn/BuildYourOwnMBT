///|
pub fn Context::declare_closure_function(
  self : Context,
  closure_def : @knf.KnfClosure,
) -> Unit raise {
  // 声明闭包函数（不生成函数体）
  let closure_name = closure_def.name.to_string()
  let ptrty = self.llvm_ctx.getPtrTy()
  let param_types : Array[&@llvm.Type] = Array::new()
  param_types.push(ptrty) // 闭包环境指针
  closure_def.params.each(param => {
    let llvm_param_type = self.type_codegen_opaque(param.1)
    param_types.push(llvm_param_type)
  })
  let llvm_ret_type = self.type_codegen_opaque(closure_def.ret_ty)
  let llvm_fty = self.llvm_ctx.getFunctionType(llvm_ret_type, param_types)
  let llvm_func = try! self.llvm_mod.addFunction(llvm_fty, closure_name)
  self.functions.set(closure_name, llvm_func)
}

///|
pub fn Context::generate_closure_function(
  self : Context,
  closure_def : @knf.KnfClosure,
  parent_path : String,
) -> Unit raise {
  // 生成闭包函数的函数体
  let closure_name = closure_def.name.to_string()
  let mangled_name = "\{parent_path}$\{closure_name}"
  let knf_func = @knf.KnfFunction::{
    name: mangled_name,
    ret_ty: closure_def.ret_ty,
    params: closure_def.params,
    body: closure_def.body,
  }
  let _ = self.top_function_codegen(knf_func)

}

///|
pub fn Context::closure_codegen(
  self : Context,
  closure_def : @knf.KnfClosure,
) -> Unit raise {
  // ClosureDef 语句在函数体中遇到时，需要创建一个闭包对象
  let closure_name = closure_def.name.to_string()
  // 使用混淆名称查找闭包函数
  let mangled_name = "\{self.current_func_path}$\{closure_name}"
  let llvm_func = self.functions.get(mangled_name).unwrap()

  // 创建闭包对象结构体: { ptr func_ptr, ptr env }
  // 闭包对象类型: { ptr, ptr }
  let closure_struct_ty = self.llvm_ctx.getStructType([
    self.llvm_ctx.getPtrTy(), // 函数指针
    self.llvm_ctx.getPtrTy(), // 环境指针
  ])
  
  // 分配闭包对象内存
  let layout = self.llvm_mod.getDataLayout().getTypeAllocSize(closure_struct_ty)
  let closure_ptr = self.builder.createCall(
    self.builtin_funcs.get("moonbit_malloc").unwrap(),
    [self.llvm_ctx.getConstInt32(layout)],
  )
  
  // 存储函数指针到闭包对象的第一个字段
  let func_ptr_field = self.builder.createGEP(closure_ptr, closure_struct_ty, [
    self.llvm_ctx.getConstInt32(0),
    self.llvm_ctx.getConstInt32(0),
  ])
  let _ = self.builder.createStore(llvm_func, func_ptr_field)
  
  // 存储环境指针到闭包对象的第二个字段 (暂时使用 null)
  let env_field = self.builder.createGEP(closure_ptr, closure_struct_ty, [
    self.llvm_ctx.getConstInt32(0),
    self.llvm_ctx.getConstInt32(1),
  ])
  let _ = self.builder.createStore(
    self.llvm_ctx.getConstPointerNull(self.llvm_ctx.getPtrTy()),
    env_field,
  )
  
  // 将闭包名称绑定到闭包对象指针
  self.name_values.set(closure_def.name, closure_ptr)
  let params_ty = closure_def.params.map(fn(p) { p.1 })
  self.name_types.set(
    closure_def.name,
    @knf.Function(params_ty, closure_def.ret_ty),
  )
}
