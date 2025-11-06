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
pub fn Context::lookup_type(
  self : Context,
  name : String,
) -> Type? raise TypeCheckError {
  match self.type_env.get(name) {
    Some(t) => {
      let k = self.analysis_type(t.kind)
      Some(Type::{ kind: k, mutable: t.mutable })
    }
    None => None
  }
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
  self.collect_struct_names(program)
  self.collect_top_lets(program)
  self.collect_function_types(program)
  let struct_defs = Map::new()
  program.struct_defs.each((n, s) => struct_defs.set(
    n,
    self.check_struct_def(s),
  ))
  let top_functions = Map::new()
  program.top_functions.each((n, s) => top_functions.set(
    n,
    self.check_top_function(s),
  ))
  let top_lets = Map::new()
  program.top_lets.each((n, s) => top_lets.set(n, self.check_top_let(s)))
  Program::{ top_lets, top_functions, struct_defs }
}

///|
pub fn Context::collect_struct_names(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  for sd in program.struct_defs {
    let (_, struc) = sd
    let _ = self.check_struct_def(struc)

  }
}

///|
pub fn Context::collect_function_types(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  for fd in program.top_functions {
    let (name, func) = fd
    let args = func.param_list
      .map(p => self.check_parser_type(p.ty))
      .map(p => p.kind)
    let ret_ty = self.check_parser_type(func.ret_ty)
    let ty = Function(args, ret_ty.kind)
    self.func_types.set(name, ty)
    self.type_env.set(name, Type::{ kind: ty, mutable: false })
  }
}

///|
pub fn Context::collect_top_lets(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  for topl in program.top_lets {
    let (name, let_def) = topl
    let ty = match let_def.ty {
      Some(ty) => self.check_parser_type(ty)
      None => Type::{ kind: self.check_expr(let_def.expr).ty, mutable: false }
    }
    self.type_env.set(name, ty)
  }
}
