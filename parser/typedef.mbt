///|
pub(all) struct Type {
  kind : TypeKind
} derive(Show, Eq)

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
  Defined(String)
} derive(Hash, Eq) // Show defined manually in `parser_aux.mbt`

///|
fn build_type(kind : TypeKind) -> Type {
  Type::{ kind, }
}

///|
fn parse_type_kind(
  tokens : ArrayView[Token],
) -> (TypeKind, ArrayView[Token]) raise ParseError {
  let (kind, rest) : (TypeKind, ArrayView[Token]) = match tokens {
    [{ kind: Upper("Unit") }, .. rest] => (Unit, rest)
    [{ kind: Upper("Bool") }, .. rest] => (Bool, rest)
    [{ kind: Upper("Int") }, .. rest] => (Int, rest)
    [{ kind: Upper("Double") }, .. rest] => (Double, rest)
    [{ kind: Upper("String") }, .. rest] => (String, rest)
    [{ kind: Upper("Array") }, ..] as tks => parse_array_type(tks)
    [{ kind: Bracket('(') }, ..] as tks => parse_tuple_type(tks)
    [{ kind: Upper(name) }, .. rest] => (Defined(name), rest)
    _ => raise ParseError("Unexpected type, found \{tokens[0].kind}")
  }
  parse_type_tail(kind, rest)
}

///|
fn parse_type_tail(
  lkind : TypeKind,
  rest : ArrayView[Token],
) -> (TypeKind, ArrayView[Token]) raise ParseError {
  match rest {
    [{ kind: Symbol("->") }, .. r1] => {
      let (ret_ty, r2) = parse_type_kind(r1)
      match lkind {
        Tuple(param_tys) => parse_type_tail(Function(param_tys, ret_ty), r2)
        _ => parse_type_tail(Function([lkind], ret_ty), r2)
      }
    }
    _ => (lkind, rest)
  }
}

///|
pub fn parse_type(
  tokens : ArrayView[Token],
) -> (Type, ArrayView[Token]) raise ParseError {
  let (kind, rest) = parse_type_kind(tokens)
  (build_type(kind), rest)
}

///|
fn parse_array_type(
  tokens : ArrayView[Token],
) -> (TypeKind, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Upper("Array") }, { kind: Bracket('[') }, .. tokens] else {
    raise ParseError("Array expects 1 argument")
  }
  let (ty, rest) = parse_type_kind(tokens)
  match rest {
    [{ kind: Bracket(']') }, .. rest] => (Array(ty), rest)
    _ => raise ParseError("Expected closing bracket")
  }
}

///|
fn parse_tuple_type(
  tokens : ArrayView[Token],
) -> (TypeKind, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Bracket('(') }, .. tokens] else {
    raise ParseError("Tuple expects 1 argument")
  }
  let (tys, rest) = {
    let items = Array::new()
    loop tokens {
      [{ kind: Bracket(')') }, .. rest] => break (items, rest)
      [{ kind: Symbol(",") }, .. rest] => continue rest
      _ as rest => {
        let (ty, rest) = parse_type_kind(rest)
        items.push(ty)
        continue rest
      }
    }
  }
  (Tuple(tys), rest)
}

///|
pub impl Show for TypeKind with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Bool => "Bool"
    Int => "Int"
    Double => "Double"
    String => "String"
    Tuple(tys) => {
      let inner = tys.map(ty => ty.to_string()).join(", ")
      "(\{inner})"
    }
    Array(ty) => "Array[\{ty}]"
    Function(params, ret) => {
      let param_str = params.map(ty => ty.to_string()).join(", ")
      "(\{param_str}) -> \{ret}"
    }
    Defined(name) => name
  }
  logger.write_string(s)
}
