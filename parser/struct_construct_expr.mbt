///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show, Eq)

///|
pub fn parse_struct_construct(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  let (name, rest) = match tokens {
    [{ kind: Upper(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect struct name")
  }
  guard rest is [{ kind: Symbol("::") }, { kind: Bracket('{') }, .. rest] else {
    raise ParseError(
      "Expect '::{' after struct name found: \{rest[0]} in \{tokens}",
    )
  }
  let (fields, rest) = {
    let items = Array::new()
    loop rest {
      [{ kind: Bracket('}') }, .. rest] => (items, rest)
      [{ kind: Symbol(",") }, .. rest] => continue rest
      _ as rest => {
        let (name, rest) = match rest {
          [{ kind: Lower(name) }, .. rest] => (name, rest)
          _ => raise ParseError("Expect field name")
        }
        guard rest is [{ kind: Symbol(":") }, .. rest1] else {
          raise ParseError(
            "Expect ':' after field name found: \{rest[0]} in \{tokens}",
          )
        }
        let (expr, rest) = parse_expr(rest1)
        items.push((name, expr))
        continue rest
      }
    }
  }
  (atom_e(StructConstruct(StructConstructExpr::{ name, fields })), rest)
}
