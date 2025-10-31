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
  guard rest is [{ kind: Symbol("::") }, { kind: Bracket('{') }, .. rest]
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
        guard rest is [{ kind: Symbol(":") }, .. rest]
        let (expr, rest) = parse_expr(rest)
        items.push((name, expr))
        continue rest
      }
    }
  }
  (atom_e(StructConstruct(StructConstructExpr::{ name, fields })), rest)
}
