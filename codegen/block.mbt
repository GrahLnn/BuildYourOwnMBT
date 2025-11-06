///|
pub fn Context::block_codegen(
  self : Self,
  block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  let func = self.builder.getInsertFunction()
  let block_bb = func.addBasicBlock()
  let after_bb = func.addBasicBlock()
  let _ = self.builder.createBr(block_bb)
  self.builder.setInsertPoint(block_bb)
  let mut last_val = None
  block.stmts.each(stmt => match stmt {
    ExprStmt(e) => last_val = self.expr_codegen(e)
    _ => self.stmt_codegen(stmt)
  })
  let _ = self.builder.createBr(after_bb)
  self.builder.setInsertPoint(after_bb)
  match block.ty {
    Unit => None
    _ => last_val
  }
}
