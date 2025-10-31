///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
} derive(Show, Eq)

///|
pub fn parse_block_expr(
  tokens : ArrayView[Token],
) -> (BlockExpr, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Bracket('{') }, .. rest]
  let items = Array::new()
  loop rest {
    [{ kind: Bracket('}') }, .. r] => break (BlockExpr::{ stmts: items }, r)
    _ as rest => {
      let (s, r) = parse_stmt(rest)
      items.push(s)
      continue r
    }
  }
}
