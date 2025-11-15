///|
pub(all) struct EnumDef {
  name : String
  generic : String?
  variants : Array[EnumVariant]
} derive(Show, Eq)

///|
pub(all) struct EnumVariant {
  name : String
  fields : Array[Type]
} derive(Show, Eq)

///|
pub fn parse_enum_variant(
  tokens : ArrayView[Token],
) -> (EnumVariant, ArrayView[Token]) raise ParseError {
  let (name, rest) = match tokens {
    [{ kind: Upper(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect Upper string")
  }
  let (fields, rest) = match rest {
    [{ kind: Bracket('(') }, .. rest] => {
      let fs = Array::new()
      loop rest {
        [{ kind: Symbol(",") }, .. rest] => continue rest
        [{ kind: Bracket(')') }, .. rest] => break (fs, rest)
        _ as rest => {
          let (ty, rest) = parse_type(rest)
          fs.push(ty)
          continue rest
        }
      }
    }
    _ => (Array::new(), rest)
  }
  (EnumVariant::{ name, fields }, rest)
}

///|
pub fn parse_enum_def(
  tokens : ArrayView[Token],
) -> (EnumDef, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Enum) }, .. rest]
  let (generic, rest) = match rest {
    [
      { kind: Bracket('[') },
      { kind: Upper(name) },
      { kind: Bracket(']') },
      .. rest,
    ] => (Some(name), rest)
    _ as rest => (None, rest)
  }
  let (name, rest) = match rest {
    [{ kind: Upper(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect string")
  }
  guard rest is [{ kind: Bracket('{') }, .. rest]
  let (variants, rest) = {
    let items = Array::new()
    loop rest {
      [{ kind: Bracket('}') }, .. rest] => (items, rest)
      [{ kind: Symbol(";") }, .. rest] => continue rest
      _ as rest => {
        let (variant, rest) = parse_enum_variant(rest)
        items.push(variant)
        continue rest
      }
    }
  }
  (EnumDef::{ name, generic, variants }, rest)
}
