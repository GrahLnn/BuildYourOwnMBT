///|
pub(all) struct Param {
  name : String
  ty : TypeKind
} derive(Show)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : TypeKind
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_top_function(
  self : Context,
  func : @parser.TopFunction,
) -> TopFunction raise TypeCheckError {
  let fname = func.fname
  let param_list = func.param_list
  let ret_ty = func.ret_ty
  let body = func.body
  let signiture = self.func_types.get(fname)
  guard signiture is Some(signiture) else {
    raise TypeCheckError("Top function must be declared type")
  }
  self.enter_scope()
  guard signiture is Function(_, rety)
  self.set_current_func_ret_ty(rety)
  let param_list = param_list.map(nt => {
    let name = nt.name
    let ty = self.check_parser_type(nt.ty)
    self.type_env.set(name, ty)
    Param::{ name, ty: ty.kind }
  })
  let body = self.check_block_expr(body)
  let ret_ty = self.check_parser_type(ret_ty).kind
  guard self.is_type_compatible(body.ty, ret_ty) else {
    raise TypeCheckError("Top function return type mismatch")
  }
  self.exit_scope()
  self.current_func_ret_ty = None
  TopFunction::{ fname, param_list, ret_ty, body }
}

///|
fn Context::substitute_top_function(
  self : Context,
  func : TopFunction,
) -> TopFunction raise TypeCheckError {
  let param_list = func.param_list.map(nt => {
    let name = nt.name
    let ty = self.analysis_type(nt.ty)
    Param::{ name, ty }
  })
  let ret_ty = self.analysis_type(func.ret_ty)
  let body = self.substitute_block_expr(func.body)
  TopFunction::{ fname: func.fname, param_list, ret_ty, body }
}
