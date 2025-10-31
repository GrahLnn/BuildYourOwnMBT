///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type?)]
  ret_ty : Type?
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_local_function(
  tokens : ArrayView[Token],
) -> (LocalFunction, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Fn) }, .. rest]
  let (fname, rest) = match rest {
    [{ kind: Lower(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect string")
  }
  guard rest is [{ kind: Bracket('(') }, .. rest]
  let (param_list, rest) = {
    let items = Array::new()
    loop rest {
      [{ kind: Bracket(')') }, .. rest] => (items, rest)
      [{ kind: Symbol(",") }, .. rest] => continue rest
      _ as rest =>
        match rest {
          [{ kind: Lower(name) }, { kind: Symbol(":") }, .. rest] => {
            let (ty, rest) = parse_type(rest)
            items.push((name, Some(ty)))
            continue rest
          }
          [{ kind: Lower(name) }, .. rest] => {
            items.push((name, None))
            continue rest
          }
          _ => raise ParseError("Expect parameter")
        }
    }
  }
  let (ret_ty, rest) = match rest {
    [{ kind: Symbol("->") }, .. rest] => {
      let (ty, rest) = parse_type(rest)
      (Some(ty), rest)
    }
    _ => (None, rest)
  }
  let (body, rest) = parse_block_expr(rest)
  (LocalFunction::{ fname, param_list, ret_ty, body }, rest)
}
