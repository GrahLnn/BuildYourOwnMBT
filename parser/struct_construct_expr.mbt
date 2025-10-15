///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show, Eq)

///|
pub fn parse_struct_construct(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}
