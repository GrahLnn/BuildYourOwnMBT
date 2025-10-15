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
  ignore(tokens)
  ...
}
