///|
pub(all) struct TopLet {
  name : String
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_top_let(
  tokens : ArrayView[Token],
) -> (TopLet, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Let) }, .. rest]
  let (name, rest) = match rest {
    [{ kind: Lower(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect top let name")
  }
  let (ty, rest) = match rest {
    [{ kind: Symbol(":") }, .. rest] => {
      let (ty, rest) = parse_type(rest)
      (Some(ty), rest)
    }
    _ => (None, rest)
  }
  guard rest is [{ kind: AssignOp(Assign) }, .. rest]
  let (expr, rest) = parse_expr(rest)
  guard rest is [{ kind: Symbol(";") }, .. rest]
  (TopLet::{ name, ty, expr }, rest)
}
