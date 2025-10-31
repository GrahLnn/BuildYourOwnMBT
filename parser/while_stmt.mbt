///|
pub(all) struct WhileStmt {
  cond : Expr
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_while_stmt(
  tokens : ArrayView[Token],
) -> (WhileStmt, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(While) }, .. rest]
  let (cond, rest) = parse_expr(rest)
  let (body, rest) = parse_block_expr(rest)
  (WhileStmt::{ cond, body }, rest)
}
