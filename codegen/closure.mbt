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
  
  // 获取闭包函数
  let fval = self.functions.get(mangled_name).unwrap()
  let entry_bb = fval.addBasicBlock(name="entry")
  self.builder.setInsertPoint(entry_bb)
  self.name_values.clear()
  self.name_types.clear()
  self.current_func_path = mangled_name
  
  // 第一个参数是环境指针
  let env_arg = fval.getArg(0).unwrap()
  
  // 如果有捕获的变量,从环境指针中提取
  if !closure_def.captured_vars.is_empty() {
    let captured_types : Array[&@llvm.Type] = []
    let captured_names : Array[@knf.Name] = []
    
    for name, ty in closure_def.captured_vars {
      captured_types.push(self.type_codegen_opaque(ty))
      captured_names.push(name)
    }
    
    let env_struct_ty = self.llvm_ctx.getStructType(captured_types)
    
    // 从环境结构体中提取每个捕获的变量
    captured_names.eachi((idx, name) => {
      let ty = closure_def.captured_vars.get(name).unwrap()
      let field_ptr = self.builder.createGEP(env_arg, env_struct_ty, [
        self.llvm_ctx.getConstInt32(0),
        self.llvm_ctx.getConstInt32(idx),
      ])
      let value = self.builder.createLoad(
        self.type_codegen_opaque(ty),
        field_ptr,
      )
      self.name_values.set(name, value)
      self.name_types.set(name, ty)
    })
  }
  
  // 绑定函数参数(从第二个参数开始)
  let mut arg_idx = 1
  for param in closure_def.params {
    let llvm_arg = fval.getArg(arg_idx).unwrap()
    self.name_values.set(param.0, llvm_arg)
    self.name_types.set(param.0, param.1)
    arg_idx += 1
  }
  
  // 生成函数体
  if closure_def.body.stmts.length() > 1 {
    closure_def.body.stmts[:-1].each(stmt => self.stmt_codegen(stmt))
  }
  let last = closure_def.body.stmts.last()
  guard last is Some(last) else {
    let _ = self.builder.createRetVoid()
    return
  }
  match last {
    ExprStmt(e) => {
      let vopt = self.expr_codegen(e)
      match (closure_def.ret_ty, vopt) {
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
      match closure_def.ret_ty {
        Unit => {
          let _ = self.builder.createRetVoid()
        }
        _ => {
          let d = self.default_value(closure_def.ret_ty)
          let _ = self.builder.createRet(d)
        }
      }
    }
  }
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

  // 创建环境结构体(如果有捕获的变量)
  let env_ptr : &@llvm.Value = if closure_def.captured_vars.is_empty() {
    // 没有捕获变量,使用 null
    (self.llvm_ctx.getConstPointerNull(self.llvm_ctx.getPtrTy()) : &@llvm.Value)
  } else {
    // 有捕获变量,创建环境结构体
    let captured_types : Array[&@llvm.Type] = []
    let captured_values : Array[&@llvm.Value] = []
    
    for name, ty in closure_def.captured_vars {
      captured_types.push(self.type_codegen_opaque(ty))
      let value = self.name_values.get(name).unwrap()
      // 如果是 AllocaInst,需要 load
      let actual_value = if value.asValueEnum() is AllocaInst(ptr) {
        self.builder.createLoad(self.type_codegen_opaque(ty), ptr)
      } else {
        value
      }
      captured_values.push(actual_value)
    }
    
    // 创建环境结构体类型
    let env_struct_ty = self.llvm_ctx.getStructType(captured_types)
    let env_layout = self.llvm_mod.getDataLayout().getTypeAllocSize(
      env_struct_ty,
    )
    let env : &@llvm.Value = self.builder.createCall(
      self.builtin_funcs.get("moonbit_malloc").unwrap(),
      [self.llvm_ctx.getConstInt32(env_layout)],
    )
    
    // 存储捕获的变量到环境结构体
    captured_values.eachi((idx, val) => {
      let field_ptr = self.builder.createGEP(env, env_struct_ty, [
        self.llvm_ctx.getConstInt32(0),
        self.llvm_ctx.getConstInt32(idx),
      ])
      let _ = self.builder.createStore(val, field_ptr)
    })
    
    env
  }

  // 创建闭包对象结构体: { ptr func_ptr, ptr env }
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
  
  // 存储环境指针到闭包对象的第二个字段
  let env_field = self.builder.createGEP(closure_ptr, closure_struct_ty, [
    self.llvm_ctx.getConstInt32(0),
    self.llvm_ctx.getConstInt32(1),
  ])
  let _ = self.builder.createStore(env_ptr, env_field)
  
  // 将闭包名称绑定到闭包对象指针
  self.name_values.set(closure_def.name, closure_ptr)
  let params_ty = closure_def.params.map(fn(p) { p.1 })
  self.name_types.set(
    closure_def.name,
    @knf.Function(params_ty, closure_def.ret_ty),
  )
}
