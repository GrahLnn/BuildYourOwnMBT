///|
pub(all) struct WhileStmt {
  cond : Expr
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_while_stmt(
  tokens : ArrayView[Token],
) -> (WhileStmt, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}
