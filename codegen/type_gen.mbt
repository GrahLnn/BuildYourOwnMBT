///|
pub fn Context::type_codegen_opaque(
  self : Context,
  knf_type : @knf.Type,
) -> &@llvm.Type {
  match knf_type {
    Int => (self.llvm_ctx.getInt32Ty() : &@llvm.Type)
    Bool => self.llvm_ctx.getInt1Ty()
    Unit => self.llvm_ctx.getVoidTy()
    Double => self.llvm_ctx.getDoubleTy()
    Array(_) => self.llvm_ctx.getPtrTy()
    String(_) => self.llvm_ctx.getPtrTy()
    Tuple(_) => self.llvm_ctx.getPtrTy()
    Struct(_) => self.llvm_ctx.getPtrTy()
    Function(_) => self.llvm_ctx.getPtrTy()
  }
}

///|
pub fn Context::type_codegen_concrete(
  self : Context,
  knf_type : @knf.Type,
) -> &@llvm.Type raise {
  match knf_type {
    Int => (self.llvm_ctx.getInt32Ty() : &@llvm.Type)
    Bool => self.llvm_ctx.getInt1Ty()
    Unit => self.llvm_ctx.getVoidTy()
    Double => self.llvm_ctx.getDoubleTy()
    Array(_) => self.llvm_ctx.getPtrTy()
    String(_) => self.llvm_ctx.getPtrTy()
    Tuple(elem_types) => {
      let llvm_elem_types = elem_types.map(elem_type => self.type_codegen_concrete(
        elem_type,
      ))
      self.llvm_ctx.getStructType(llvm_elem_types)
    }
    Struct(struct_name) => self.struct_types.get(struct_name).unwrap()
    Function(param_types, return_type) => {
      let llvm_param_types = param_types.map(param_type => self.type_codegen_concrete(
        param_type,
      ))
      let llvm_return_type = self.type_codegen_concrete(return_type)
      self.llvm_ctx.getFunctionType(llvm_return_type, llvm_param_types)
    }
  }
}

///|
pub fn Context::collect_func_values(
  self : Context,
  knf_funcs : Map[String, @knf.KnfFunction],
) -> Unit raise {
  let ptrty = self.llvm_ctx.getPtrTy()
  // 收集顶层函数
  for fname, func in knf_funcs {
    let { params, ret_ty, .. } = func
    let param_types : Array[&@llvm.Type] = Array::new()
    if fname != "main" {
      param_types.push(ptrty) // for closure environment
    }
    params.each(param => {
      let llvm_param_type = self.type_codegen_opaque(param.1)
      param_types.push(llvm_param_type)
    })
    let llvm_ret_type = self.type_codegen_opaque(ret_ty)
    let llvm_fty = self.llvm_ctx.getFunctionType(llvm_ret_type, param_types)
    let llvm_func = try! self.llvm_mod.addFunction(llvm_fty, fname)
    self.functions.set(fname, llvm_func)

    // 递归收集该函数中的所有闭包函数
    self.collect_closures_in_block(func.body, fname)
  }
}

///|
/// 递归收集函数体中的所有闭包函数
fn Context::collect_closures_in_block(
  self : Context,
  block : @knf.KnfBlock,
  parent_path : String,
) -> Unit raise {
  for stmt in block.stmts {
    self.collect_closures_in_stmt(stmt, parent_path)
  }
}

///|
/// 在语句中收集闭包函数
fn Context::collect_closures_in_stmt(
  self : Context,
  stmt : @knf.KnfStmt,
  parent_path : String,
) -> Unit raise {
  match stmt {
    ClosureDef(closure_def) => {
      // 生成混淆名称: parent_path$closure_name
      let original_name = closure_def.name.to_string()
      let mangled_name = "\{parent_path}$\{original_name}"

      // 声明闭包函数
      let ptrty = self.llvm_ctx.getPtrTy()
      let param_types : Array[&@llvm.Type] = Array::new()
      param_types.push(ptrty) // 闭包环境指针
      closure_def.params.each(param => {
        let llvm_param_type = self.type_codegen_opaque(param.1)
        param_types.push(llvm_param_type)
      })
      let llvm_ret_type = self.type_codegen_opaque(closure_def.ret_ty)
      let llvm_fty = self.llvm_ctx.getFunctionType(llvm_ret_type, param_types)
      let llvm_func = try! self.llvm_mod.addFunction(llvm_fty, mangled_name)

      // 同时保存原始名称和混淆名称的映射
      self.functions.set(original_name, llvm_func)
      self.functions.set(mangled_name, llvm_func)

      // 递归收集闭包函数体中的嵌套闭包
      self.collect_closures_in_block(closure_def.body, mangled_name)
    }
    Let(_, _, expr) | LetMut(_, _, expr) | ExprStmt(expr) | Return(expr) =>
      self.collect_closures_in_expr(expr, parent_path)
    Assign(_, expr) => self.collect_closures_in_expr(expr, parent_path)
    While(cond_block, body_block) => {
      self.collect_closures_in_block(cond_block, parent_path)
      self.collect_closures_in_block(body_block, parent_path)
    }
    ReturnUnit => ()
    _ => ()
  }
}

///|
/// 在表达式中收集闭包函数
fn Context::collect_closures_in_expr(
  self : Context,
  expr : @knf.KnfExpr,
  parent_path : String,
) -> Unit raise {
  match expr {
    If(_, then_block, else_block) => {
      self.collect_closures_in_block(then_block, parent_path)
      self.collect_closures_in_block(else_block, parent_path)
    }
    _ => () // 其他表达式类型不包含闭包定义
  }
}

///|
/// 收集所有闭包定义(包括嵌套的)
pub fn Context::collect_all_closures(
  self : Context,
  knf_funcs : Map[String, @knf.KnfFunction],
) -> Array[(@knf.KnfClosure, String)] {
  let closures : Array[(@knf.KnfClosure, String)] = Array::new()
  for fname, func in knf_funcs {
    self.collect_closures_from_block(func.body, fname, closures)
  }
  closures
}

///|
/// 从函数体中收集闭包定义
fn Context::collect_closures_from_block(
  self : Context,
  block : @knf.KnfBlock,
  parent_path : String,
  closures : Array[(@knf.KnfClosure, String)],
) -> Unit {
  for stmt in block.stmts {
    self.collect_closures_from_stmt(stmt, parent_path, closures)
  }
}

///|
/// 从语句中收集闭包定义
fn Context::collect_closures_from_stmt(
  self : Context,
  stmt : @knf.KnfStmt,
  parent_path : String,
  closures : Array[(@knf.KnfClosure, String)],
) -> Unit {
  match stmt {
    ClosureDef(closure_def) => {
      let closure_name = closure_def.name.to_string()
      let mangled_name = "\{parent_path}$\{closure_name}"
      closures.push((closure_def, parent_path))
      // 递归收集嵌套闭包
      self.collect_closures_from_block(closure_def.body, mangled_name, closures)
    }
    Let(_, _, expr) | LetMut(_, _, expr) | ExprStmt(expr) | Return(expr) =>
      self.collect_closures_from_expr(expr, parent_path, closures)
    Assign(_, expr) =>
      self.collect_closures_from_expr(expr, parent_path, closures)
    While(cond_block, body_block) => {
      self.collect_closures_from_block(cond_block, parent_path, closures)
      self.collect_closures_from_block(body_block, parent_path, closures)
    }
    ReturnUnit => ()
    _ => ()
  }
}

///|
/// 从表达式中收集闭包定义
fn Context::collect_closures_from_expr(
  self : Context,
  expr : @knf.KnfExpr,
  parent_path : String,
  closures : Array[(@knf.KnfClosure, String)],
) -> Unit {
  match expr {
    If(_, then_block, else_block) => {
      self.collect_closures_from_block(then_block, parent_path, closures)
      self.collect_closures_from_block(else_block, parent_path, closures)
    }
    _ => ()
  }
}

///|
pub fn Context::collect_struct_types(
  self : Context,
  knf_structs : Map[String, @knf.KnfStructDef],
) -> Unit raise {
  for sname, knf_struct in knf_structs {
    let field_types : Array[&@llvm.Type] = Array::new()
    for field in knf_struct.fields {
      let llvm_field_type = self.type_codegen_opaque(field.2)
      field_types.push(llvm_field_type)
    }
    let llvm_sty = self.llvm_ctx.getStructType(field_types, name=sname)
    self.struct_types.set(sname, llvm_sty)
    self.knf_struct_types.set(sname, knf_struct)
  }
}
