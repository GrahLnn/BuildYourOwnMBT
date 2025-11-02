///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type)]
  ret_ty : Type
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_local_function(
  self : Context,
  func : @parser.LocalFunction,
) -> LocalFunction raise TypeCheckError {
  let param_list = func.param_list.map(nt => {
    let (name, ty) = nt
    let ty = match ty {
      Some(t) => self.check_parser_type(t)
      None => Type::{ kind: self.tyvar(), mutable: false }
    }
    (name, ty)
  })
  let ret_ty = match func.ret_ty {
    Some(t) => self.check_parser_type(t)
    None => Type::{ kind: self.tyvar(), mutable: false }
  }
  let fn_ty = Type::{
    kind: Function(
      param_list.map(nt => {
        let (_, ty) = nt
        ty.kind
      }),
      ret_ty.kind,
    ),
    mutable: false,
  }
  self.type_env.set(func.fname, fn_ty)
  self.enter_scope()
  let _ = param_list.map(nt => {
    let (name, ty) = nt
    self.type_env.set(name, ty)
  })
  self.set_current_func_ret_ty(ret_ty.kind)
  let body = self.check_block_expr(func.body)
  guard self.is_type_compatible(body.ty, ret_ty.kind)
  self.exit_scope()
  LocalFunction::{ fname: func.fname, param_list, ret_ty, body }
}

///|
fn Context::substitute_local_function(
  self : Context,
  func : LocalFunction,
) -> LocalFunction raise TypeCheckError {
  let param_list = func.param_list.map(nt => {
    let (name, ty) = nt
    let ty = self.subst_type(ty)
    (name, ty)
  })
  let ret_ty = self.subst_type(func.ret_ty)
  let body = self.substitute_block_expr(func.body)
  LocalFunction::{ fname: func.fname, param_list, ret_ty, body }
}
