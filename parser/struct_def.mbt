///|
pub(all) struct StructDef {
  name : String
  fields : Array[StructField]
} derive(Show, Eq)

///|
pub(all) struct StructField {
  name : String
  is_mut : Bool
  ty : Type
} derive(Show, Eq)

///|
pub fn parse_struct_field(
  tokens : ArrayView[Token],
) -> (StructField, ArrayView[Token]) raise ParseError {
  let mut is_mut = false
  let rest = match tokens {
    [{ kind: Keyword(Mut) }, .. rest] => {
      is_mut = true
      rest
    }
    _ as rest => rest
  }
  let (name, rest) = match rest {
    [{ kind: Lower(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect string")
  }
  guard rest is [{ kind: Symbol(":") }, .. rest]
  let (ty, rest) = parse_type(rest)
  (StructField::{ name, is_mut, ty }, rest)
}

///|
pub fn parse_struct_def(
  tokens : ArrayView[Token],
) -> (StructDef, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Struct) }, .. rest]
  let (name, rest) = match rest {
    [{ kind: Upper(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect string")
  }
  guard rest is [{ kind: Bracket('{') }, .. rest]
  let (fields, rest) = {
    let items = Array::new()
    loop rest {
      [{ kind: Bracket('}') }, .. rest] => (items, rest)
      [{ kind: Symbol(";") }, .. rest] => continue rest
      _ as rest => {
        let (field, rest) = parse_struct_field(rest)
        items.push(field)
        continue rest
      }
    }
  }
  (StructDef::{ name, fields }, rest)
}
