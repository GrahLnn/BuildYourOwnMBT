///|
pub(all) struct Type {
  kind : TypeKind
  mutable : Bool
} derive(Show)

///|
pub(all) enum TypeKind {
  Unit
  Bool
  Int
  Double
  String
  Tuple(Array[TypeKind])
  Array(TypeKind)
  Function(Array[TypeKind], TypeKind)
  Struct(String)
  Any
  TypeVar(Int)
} derive(Hash)

///|
pub fn Context::check_parser_typekind(
  self : Context,
  ty : @parser.TypeKind,
) -> TypeKind raise TypeCheckError {
  match ty {
    Unit => Unit
    Bool => Bool
    Int => Int
    Double => Double
    String => String
    Tuple(types) =>
      Tuple(types.map(typekind => self.check_parser_typekind(typekind)))
    Array(elem_type) => Array(self.check_parser_typekind(elem_type))
    Function(param_types, return_type) =>
      Function(
        param_types.map(typekind => self.check_parser_typekind(typekind)),
        self.check_parser_typekind(return_type),
      )
    Defined(name) => {
      guard self.struct_defs.contains(name) else {
        raise TypeCheckError("Struct \{name} not defined")
      }
      Struct(name)
    }
  }
}

///|
pub fn Context::check_parser_type(
  self : Context,
  ty : @parser.Type,
  mutable? : Bool = false,
) -> Type raise TypeCheckError {
  let kind = self.check_parser_typekind(ty.kind)
  Type::{ kind, mutable }
}

///|
pub fn Context::tyvar(self : Context) -> TypeKind {
  let id = self.type_vars.length()
  let var_ty = TypeVar(id)
  self.type_vars.set(id, var_ty)
  var_ty
}

///|
pub fn Context::deref_type(
  self : Context,
  ty : TypeKind,
) -> TypeKind raise TypeCheckError {
  match ty {
    TypeVar(id) => {
      let inner = self.type_vars.get(id).unwrap()
      match inner {
        TypeVar(d) => {
          guard d != id else { inner }
          let rep = self.deref_type(inner)
          self.type_vars.set(id, rep)
          rep
        }
        _ => {
          self.type_vars.set(id, inner)
          inner
        }
      }
    }
    _ => ty
  }
}

///|
pub fn Context::is_type_compatible(
  self : Context,
  a : TypeKind,
  b : TypeKind,
) -> Bool raise TypeCheckError {
  match (a, b) {
    (TypeVar(a), TypeVar(b)) => {
      guard self.type_vars.get(a).unwrap() is TypeVar(_) else { false }
      let inner_b = self.type_vars
        .get(b)
        .unwrap_or_else(() => raise TypeCheckError("TypeVar not found"))
      match inner_b {
        TypeVar(_) => {
          self.type_vars.set(a, TypeVar(b))
          if b > a {
            self.type_vars.set(b, TypeVar(a))
          }
          true
        }
        _ => {
          self.type_vars.set(a, inner_b)
          true
        }
      }
    }
    (TypeVar(id), ty) => {
      guard self.type_vars.get(id).unwrap() is TypeVar(_) else { false }
      let ty = self.de_var_wrap(id, ty)
      self.set_var_type_to_typekind(id, ty)
      true
    }
    (Tuple(a), Tuple(b)) => {
      guard a.length() == b.length() else { false }
      let n = a.length().min(b.length())
      for i in 0..<n {
        if !self.is_type_compatible(a[i], b[i]) {
          return false
        }
      }
      true
    }
    (Array(a), Array(b)) => self.is_type_compatible(a, b)
    (Function(a, ra), Function(b, rb)) => {
      guard a.length() == b.length() else { false }
      let n = a.length().min(b.length())
      for i in 0..<n {
        if !self.is_type_compatible(a[i], b[i]) {
          return false
        }
      }
      self.is_type_compatible(ra, rb)
    }
    (Any, _) => true
    (_, Any) => true
    (Bool, Bool) => true
    (Unit, Unit) => true
    (Int, Int) => true
    (Double, Double) => true
    (String, String) => true
    _ => false
  }
}

///|
fn Context::de_var_wrap(
  self : Context,
  id : Int,
  ty : TypeKind,
) -> TypeKind raise TypeCheckError {
  match ty {
    Tuple(t) => {
      let ts = Array::new()
      loop t[:] {
        [TypeVar(i), .. rest] => {
          ts.push(self.deref_type(TypeVar(i)))
          continue rest
        }
        [c, .. rest] => {
          ts.push(c)
          continue rest
        }
        [] => break
      }
      Tuple(ts)
    }
    Array(t) =>
      match t {
        TypeVar(i) => {
          if id > i {
            self.type_vars.set(i, TypeVar(id))
          }
          ty
        }
        _ => Array(t)
      }
    Function(args, ret) => {
      let argts = Array::new()
      loop args[:] {
        [TypeVar(i), .. rest] => {
          argts.push(self.deref_type(TypeVar(i)))
          continue rest
        }
        [c, .. rest] => {
          argts.push(c)
          continue rest
        }
        [] => break
      }
      let rety = match ret {
        TypeVar(i) => self.deref_type(TypeVar(i))
        _ => self.de_var_wrap(id, ret)
      }
      Function(argts, rety)
    }
    _ => self.deref_type(ty)
  }
}

///|
pub fn Context::confirm_type(
  self : Context,
  a : TypeKind,
  kind : TypeKind,
  name : String,
  mutable : Bool,
) -> Bool raise TypeCheckError {
  let b = self.type_env.get(name)
  let others = match b {
    Some(ty) => {
      let others = Array::new()
      for k, v in self.type_env.local_ {
        match (ty.kind, v.kind) {
          (TypeVar(a), TypeVar(b)) => if a == b { others.push(k) }
          _ => ()
        }
      }
      Some(others)
    }
    None => None
  }
  guard self.is_type_compatible(a, kind) else { false }
  self.type_env.set(name, Type::{ kind, mutable })
  match others {
    Some(names) =>
      for name in names {
        self.type_env.set(name, Type::{ kind, mutable })
      }
    None => ()
  }
  true
}

///|
pub fn Context::push_type(
  self : Self,
  name : String,
  kind : TypeKind,
  mutable : Bool,
) -> Unit {
  self.type_env.set(name, Type::{ kind, mutable })
}

///|
fn Context::update_type(
  self : Context,
  ty : TypeKind,
) -> TypeKind raise TypeCheckError {
  match ty {
    Tuple(t) => {
      let ts = Array::new()
      loop t[:] {
        [TypeVar(i), .. rest] => {
          ts.push(self.deref_type(TypeVar(i)))
          continue rest
        }
        [c, .. rest] => {
          ts.push(c)
          continue rest
        }
        [] => break
      }
      Tuple(ts)
    }
    Array(t) => {
      let inner = match t {
        TypeVar(i) => self.deref_type(TypeVar(i))
        _ => t
      }
      Array(inner)
    }
    Function(args, ret) => {
      let argts = Array::new()
      loop args[:] {
        [TypeVar(i), .. rest] => {
          argts.push(self.deref_type(TypeVar(i)))
          continue rest
        }
        [c, .. rest] => {
          argts.push(c)
          continue rest
        }
        [] => break
      }
      let rety = match ret {
        TypeVar(i) => self.deref_type(TypeVar(i))
        _ => ret
      }
      Function(argts, rety)
    }
    _ => ty
  }
}

///|
fn has_type_var(ty : TypeKind) -> Bool {
  match ty {
    TypeVar(_) => true
    Tuple(t) =>
      loop t[:] {
        [TypeVar(_), ..] => break true
        [_, .. rest] => continue rest
        [] => break false
      }
    Array(t) =>
      match t {
        TypeVar(_) => true
        _ => false
      }
    Function(args, ret) => {
      let check_arg = loop args[:] {
        [TypeVar(_), ..] => break true
        [_, .. rest] => continue rest
        [] => break false
      }
      let check_ret = match ret {
        TypeVar(_) => true
        _ => false
      }
      check_arg || check_ret
    }
    _ => false
  }
}

///|
fn Context::set_var_type_to_typekind(
  self : Context,
  id : Int,
  to : TypeKind,
) -> Unit raise TypeCheckError {
  match self.type_vars.get(id) {
    Some(t) =>
      match t {
        TypeVar(t) => {
          self.type_vars.set(id, to)
          if t != id {
            self.set_var_type_to_typekind(t, to)
          }
        }
        _ as t => {
          let ty : TypeKind = self.update_type(t)
          self.type_vars.set(id, ty)
        }
      }
    _ => raise TypeCheckError("TypeVar not found")
  }
}

///|
pub impl Show for TypeKind with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Bool => "Bool"
    Int => "Int"
    Double => "Double"
    String => "String"
    Tuple(types) => {
      let inner = types.map(typekind => typekind.to_string()).join(", ")
      "(\{inner})"
    }
    Array(elem_type) => "Array[\{elem_type.to_string()}]"
    Function(param_types, return_type) => {
      let params = param_types.map(typekind => typekind.to_string()).join(", ")
      "(\{params}) -> \{return_type.to_string()}"
    }
    Struct(name) => "\{name}"
    Any => "Any"
    TypeVar(name) => "TypeVar(\{name})"
  }
  logger.write_string(s)
}
