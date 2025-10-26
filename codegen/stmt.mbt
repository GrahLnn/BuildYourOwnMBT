///|
pub fn Context::stmt_codegen(self : Self, stmt : @knf.KnfStmt) -> Unit raise {
  match stmt {
    Let(name, ty, expr) => self.let_stmt_codegen(name, ty, expr)
    LetMut(_) => raise CodegenError("LetMut not implemented yet")
    Assign(_) => raise CodegenError("Assign not implemented yet")
    ArrayPut(_) => raise CodegenError("ArrayPut not implemented yet")
    StructFieldSet(_) => raise CodegenError("StructFieldSet not implemented yet")
    While(_) => raise CodegenError("While not implemented yet")
    ExprStmt(_) => raise CodegenError("ExprStmt not implemented yet")
    Return(_) => raise CodegenError("Return with value not implemented yet")
    ReturnUnit => raise CodegenError("Return unit not implemented yet")
    ClosureDef(_) => raise CodegenError("ClosureDef not implemented yet")
  }
}

///|
pub fn Context::let_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  ignore(self)
  ignore(name)
  ignore(ty)
  ignore(expr)
  raise CodegenError("Let statement codegen not implemented yet")
}

///|
pub fn Context::let_mut_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  ignore(self)
  ignore(name)
  ignore(ty)
  ignore(expr)
  raise CodegenError("LetMut statement codegen not implemented yet")
}

///|
pub fn Context::assign_stmt_codegen(
  self : Self,
  name : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  ignore(self)
  ignore(name)
  ignore(expr)
  raise CodegenError("Assign statement codegen not implemented yet")
}

///|
pub fn Context::array_put_codegen(
  self : Self,
  name : @knf.Name,
  idx : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  ignore(self)
  ignore(name)
  ignore(idx)
  ignore(expr)
  raise CodegenError("ArrayPut codegen not implemented yet")
}

///|
pub fn Context::struct_field_set_codegen(
  self : Self,
  name : @knf.Name,
  field : String,
  value_name : @knf.Name,
) -> Unit raise {
  ignore(self)
  ignore(name)
  ignore(field)
  ignore(value_name)
  raise CodegenError("StructFieldSet codegen not implemented yet")
}
