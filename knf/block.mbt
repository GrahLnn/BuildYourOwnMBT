///|
pub(all) struct KnfBlock {
  stmts : Array[KnfStmt]
  ty : Type
}

///|
pub fn Context::block_expr_to_knf(
  self : Context,
  expr : @typecheck.BlockExpr,
) -> KnfBlock raise KnfTransformError {
  ignore(self)
  ignore(expr)
  raise KnfTransformError("block_expr_to_knf not implemented")
}

///|
pub fn KnfBlock::to_string(self : KnfBlock, ident : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  for stmt in self.stmts {
    sb.write_string(stmt.to_string(ident=ident + 2))
    sb.write_string("\n")
  }
  sb.write_string(" ".repeat(ident))
  sb.write_string("}")
  sb.to_string()
}

///|
pub fn KnfBlock::nested_to_string(self : KnfBlock) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{")
  for stmt in self.stmts {
    sb.write_string(stmt.to_string(ident=0))
    sb.write_string(" ")
  }
  sb.write_string("}")
  sb.to_string()
}

///|
pub impl Show for KnfBlock with output(self, logger) {
  logger.write_string(self.to_string(0))
}
