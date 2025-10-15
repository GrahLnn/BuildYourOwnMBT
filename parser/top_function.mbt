///|
pub(all) struct Param {
  name : String
  ty : Type
} derive(Show, Eq)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : Type
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_param(
  tokens : ArrayView[Token],
) -> (Param, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}

///|
pub fn parse_top_function(
  tokens : ArrayView[Token],
) -> (TopFunction, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}
