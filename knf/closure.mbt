///|
pub(all) struct KnfClosure {
  name : Name
  params : Array[(Name, Type)]
  ret_ty : Type
  body : KnfBlock
  captured_vars : Map[Name, Type]
}

///|
pub fn KnfClosure::to_string(self : KnfClosure, ident? : Int = 0) -> String {
  let sb = StringBuilder::new()
  let indent_str = " ".repeat(ident)
  if !self.captured_vars.is_empty() {
    sb.write_string("// Captured variables: \n")
    for name, ty in self.captured_vars {
      sb.write_string(indent_str)
      sb.write_string("// - \{name} : \{ty}\n")
    }
    sb.write_string(indent_str)
    sb.write_string("fn \{self.name}(")
  } else {
    sb.write_string("fn \{self.name}(")
  }
  let param_strs = self.params.map(name_ty => {
    let (name, ty) = name_ty
    "\{name} : \{ty}"
  })
  sb.write_string(param_strs.join(", "))
  sb.write_string(") -> \{self.ret_ty} ")
  sb.write_string(self.body.to_string(ident))
  sb.to_string()
}

///|
pub fn Context::local_function_to_knf(
  self : Context,
  local_function : @typecheck.LocalFunction,
) -> KnfClosure raise KnfTransformError {
  let params_ty = local_function.param_list.map(arg => {
    let (_, arg_ty) = arg
    let ty = self.type_to_knf(arg_ty)
    ty
  })
  let ret_ty = self.type_to_knf(local_function.ret_ty)
  let name = self.add_new_name(
    local_function.fname,
    Function(params_ty, ret_ty),
  )
  self.enter_scope()
  let params = local_function.param_list.map(arg => {
    let (str_name, arg_ty) = arg
    let ty = self.type_to_knf(arg_ty)
    let name = self.add_new_name(str_name, ty)
    self.name_env.set(str_name, name, ty)
    (name, ty)
  })
  let body = self.block_expr_to_knf(local_function.body)
  self.exit_scope()
  let captured_vars = self.name_env.capture
  KnfClosure::{ name, params, ret_ty, body, captured_vars }
}
