///|
using @either {type Either}

///|
pub(all) suberror TypeCheckError String derive(Show)

///|
pub(all) struct Env {
  local_ : Map[String, Type]
  parent : Env?
}

///|
pub fn Env::new(parent? : Env? = None) -> Env {
  Env::{ local_: Map::new(), parent }
}

///|
pub fn Env::get(self : Env, name : String) -> Type? {
  match self.local_.get(name) {
    Some(t) => Some(t)
    None =>
      match self.parent {
        Some(p) => p.get(name)
        None => None
      }
  }
}

///|
pub fn Env::set(self : Env, name : String, t : Type) -> Unit {
  self.local_.set(name, t)
}

///|
pub(all) struct Context {
  mut type_env : Env
  type_vars : Map[Int, TypeKind]
  struct_defs : Map[String, StructDef]
  func_types : Map[String, TypeKind]
  mut current_func_ret_ty : TypeKind?
}

///|
pub fn Context::new() -> Context {
  Context::{
    type_env: Env::new(),
    type_vars: Map::new(),
    struct_defs: Map::new(),
    func_types: Map::new(),
    current_func_ret_ty: None,
  }
}

///|
pub fn Context::lookup_type(self : Context, name : String) -> Type? {
  self.type_env.get(name)
}

///|
pub fn Context::enter_scope(self : Self) -> Unit {
  let sub_env = Env::new(parent=Some(self.type_env))
  self.type_env = sub_env
}

///|
pub fn Context::exit_scope(self : Context) -> Unit {
  self.type_env = match self.type_env.parent {
    Some(p) => p
    None => self.type_env
  }
}

///|
pub fn Context::set_current_func_ret_ty(self : Context, ty : TypeKind) -> Unit {
  self.current_func_ret_ty = Some(ty)
}

///|
pub(all) struct Program {
  top_lets : Map[String, TopLet]
  top_functions : Map[String, TopFunction]
  struct_defs : Map[String, StructDef]
} derive(Show)

///|
pub fn Context::check_program(
  self : Context,
  program : @parser.Program,
) -> Program raise TypeCheckError {
  ignore(self)
  ignore(program)
  raise TypeCheckError("check_program not implemented")
}

///|
pub fn Context::collect_struct_names(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  ignore(self)
  ignore(program)
  raise TypeCheckError("collect_struct_names not implemented")
}

///|
pub fn Context::collect_function_types(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  ignore(self)
  ignore(program)
  raise TypeCheckError("collect_function_types not implemented")
}
