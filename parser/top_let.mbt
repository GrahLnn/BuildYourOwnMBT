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
  ignore(tokens)
  ...
}
