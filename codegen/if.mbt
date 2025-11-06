///|
pub fn Context::if_codegen(
  self : Self,
  cond : @knf.KnfExpr,
  then_block : @knf.KnfBlock,
  else_block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  let func = self.builder.getInsertFunction()

  // 1) 创建基本块
  let then_bb = func.addBasicBlock()
  let else_bb = func.addBasicBlock()
  let merge_bb = func.addBasicBlock()

  // 2) 创建条件分支
  let cond_val = self.expr_codegen(cond).unwrap()
  let _ = self.builder.createCondBr(cond_val, then_bb, else_bb)

  // --- 3) 处理 then 分支 (不再调用 block_codegen) ---
  self.builder.setInsertPoint(then_bb)
  // **直接在这里实现块内代码的生成**
  let mut then_val = None
  then_block.stmts.each(stmt => match stmt {
    ExprStmt(e) => then_val = self.expr_codegen(e)
    _ => self.stmt_codegen(stmt)
  })
  let then_end_bb = self.builder.getInsertBlock()
  let then_terminated = match then_end_bb.getTerminator() {
    Some(_) => true
    None => false
  }
  if !then_terminated {
    let _ = self.builder.createBr(merge_bb)

  }

  // --- 4) 处理 else 分支 (不再调用 block_codegen) ---
  self.builder.setInsertPoint(else_bb)
  // **再次实现块内代码的生成**
  let mut else_val = None
  else_block.stmts.each(stmt => match stmt {
    ExprStmt(e) => else_val = self.expr_codegen(e)
    _ => self.stmt_codegen(stmt)
  })
  let else_end_bb = self.builder.getInsertBlock()
  let else_terminated = match else_end_bb.getTerminator() {
    Some(_) => true
    None => false
  }
  if !else_terminated {
    let _ = self.builder.createBr(merge_bb)

  }

  // --- 5) 合并与 PHI 节点 (这部分逻辑保持不变) ---
  if then_terminated && else_terminated {
    merge_bb.removeFromParent()
    return None
  }
  self.builder.setInsertPoint(merge_bb)
  let has_value = !(then_block.ty is Unit)
  if !has_value {
    return None
  }
  let phi_ty = self.type_codegen_opaque(then_block.ty)
  let phi = self.builder.createPHI(phi_ty)
  if !then_terminated {
    let tv = match then_val {
      Some(v) => v
      None => self.default_value(then_block.ty)
    }
    phi.addIncoming(tv, then_end_bb)
  }
  if !else_terminated {
    let ev = match else_val {
      Some(v) => v
      None => self.default_value(else_block.ty)
    }
    phi.addIncoming(ev, else_end_bb)
  }
  Some(phi)
}
