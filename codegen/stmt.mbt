///|
pub fn Context::stmt_codegen(self : Self, stmt : @knf.KnfStmt) -> Unit raise {
  match stmt {
    Let(name, ty, expr) => self.let_stmt_codegen(name, ty, expr)
    LetMut(name, ty, expr) => self.let_mut_stmt_codegen(name, ty, expr)
    Assign(name, expr) => self.assign_stmt_codegen(name, expr)
    ArrayPut(name, idx, expr) => self.array_put_codegen(name, idx, expr)
    StructFieldSet(name, field, value_name) =>
      self.struct_field_set_codegen(name, field, value_name)
    While(cond_block, body_block) => self.while_codegen(cond_block, body_block)
    ExprStmt(e) => {
      let _ = self.expr_codegen(e)

    }
    Return(expr) => {
      let value = self.expr_codegen(expr).unwrap()
      let _ = self.builder.createRet(value)

    }
    ReturnUnit => {
      let _ = self.builder.createRetVoid()

    }
    ClosureDef(closure_def) => self.closure_codegen(closure_def)
  }
}

///|
pub fn Context::let_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self.expr_codegen(expr).unwrap()
  self.name_values.set(name, value)
  self.name_types.set(name, ty)
}

///|
pub fn Context::let_mut_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let ptr = self.builder.createAlloca(self.type_codegen_opaque(ty))
  let _ = self.builder.createStore(self.expr_codegen(expr).unwrap(), ptr)
  self.name_values.set(name, ptr)
  self.name_types.set(name, ty)
}

///|
pub fn Context::assign_stmt_codegen(
  self : Self,
  name : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self.expr_codegen(expr).unwrap()
  let ptr = self.name_values
    .get(name)
    .unwrap_or_else(() => raise CodegenError("Assign to undefined variable"))
  let _ = self.builder.createStore(value, ptr)

}

///|
pub fn Context::array_put_codegen(
  self : Self,
  name : @knf.Name,
  idx : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let array = self.name_values.get(name).unwrap()
  let index = self.name_values.get(idx).unwrap()
  let value = self.expr_codegen(expr).unwrap()
  let arr_ty = self.name_types.get(name).unwrap()
  self.put_array(arr_ty, array, index, value)
}

///|

///|
pub fn Context::struct_field_set_codegen(
  self : Self,
  name : @knf.Name,
  field : String,
  value_name : @knf.Name,
) -> Unit raise {
  let struct_ptr = self.name_values
    .get(name)
    .unwrap_or_else(() => raise CodegenError(
      "Struct variable `\{name}` not found for field set",
    ))
  let new_value = self.name_values
    .get(value_name)
    .unwrap_or_else(() => raise CodegenError(
      "Value variable `\{value_name}` not found for field set",
    ))

  // We need both the KNF definition (to find the field index) and the LLVM type (for the GEP instruction).
  // We can get the type name (e.g., "Point") from the KNF type of the struct variable.
  let struct_type = self.name_types.get(name).unwrap()
  guard struct_type is Struct(struct_type_name)
  let knf_struct_def = self.knf_struct_types.get(struct_type_name).unwrap()
  let llvm_struct_type = self.struct_types.get(struct_type_name).unwrap()
  let field_index_opt = {
    let mut result = None
    for i, f in knf_struct_def.fields {
      if f.0 == field {
        result = Some(i)
        break
      }
    }
    result
  }
  let field_index = field_index_opt.unwrap_or_else(() => raise CodegenError(
    "Field `\{field}` not found in struct `\{struct_type_name}`",
  ))

  // This is the core instruction: getelementptr %Point, ptr %p, i32 0, i32 <field_index>
  let field_ptr = self.builder.createGEP(struct_ptr, llvm_struct_type, [
    self.llvm_ctx.getConstInt32(0),
    self.llvm_ctx.getConstInt32(field_index),
  ])
  let _ = self.builder.createStore(new_value, field_ptr)

}

///|
pub fn Context::while_codegen(
  self : Self,
  cond_block : @knf.KnfBlock,
  body_block : @knf.KnfBlock,
) -> Unit raise {
  // 获取当前函数和循环开始前的基本块
  let current_func = self.builder.getInsertBlock().getParent()

  // 1. 为循环创建所有必要的基本块,使用唯一标签避免嵌套循环冲突
  let loop_id = self.bb_counter
  self.bb_counter += 1
  let cond_bb = current_func.addBasicBlock(name="while.cond.\{loop_id}")
  let body_bb = current_func.addBasicBlock(name="while.body.\{loop_id}")
  let end_bb = current_func.addBasicBlock(name="while.end.\{loop_id}")

  // 2. 从当前块无条件跳转到循环的条件检查块。
  //    这是进入循环的唯一入口。
  let _ = self.builder.createBr(cond_bb)

  // 3. 生成条件块 (while.cond)
  self.builder.setInsertPoint(cond_bb)

  // 生成条件块中的所有语句 (通常是计算)
  if cond_block.stmts.length() > 1 {
    cond_block.stmts[:-1].each(stmt => self.stmt_codegen(stmt))
  }
  // 最后一个语句必须是条件表达式
  let cond_value = match cond_block.stmts.last() {
    Some(@knf.ExprStmt(expr)) => self.expr_codegen(expr).unwrap()
    _ => raise CodegenError("While condition block must end with ExprStmt")
  }
  // 根据条件结果，跳转到循环体或循环结束块
  let _ = self.builder.createCondBr(cond_value, body_bb, end_bb)

  // 4. 生成循环体块 (while.body)
  self.builder.setInsertPoint(body_bb)

  // 递归地为循环体中的所有语句生成代码。
  // 嵌套的 while 循环会将插入点改到其 end_bb,后续语句会在那里生成。
  body_block.stmts.each(stmt => self.stmt_codegen(stmt))

  // 5. 链接循环体的末尾回到条件块
  //    注意:嵌套循环会改变插入点,循环体的后续语句可能生成在内层循环的 end_bb 中。
  //    需要检查当前插入点所在的块,而不是 body_bb。
  let current_block = self.builder.getInsertBlock()
  if !(current_block.getTerminator() is Some(_)) {
    let _ = self.builder.createBr(cond_bb)

  }

  // 6. 将插入点明确地设置到循环结束后的块 (while.end)
  //    这确保了无论循环体内部发生了什么，所有在 while 循环之后的代码
  //    都会被正确地生成在这个 'end_bb' 中。
  //    注意: end_bb 中可能会生成后续语句(如外层循环的增量操作),
  //    这些语句执行完后需要跳回到外层循环的条件块。
  //    但这个跳转由外层循环的 while_codegen 负责添加,这里只设置插入点。
  self.builder.setInsertPoint(end_bb)
}
