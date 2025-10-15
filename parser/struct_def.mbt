///|
pub(all) struct StructDef {
  name : String
  fields : Array[StructField]
} derive(Show, Eq)

///|
pub(all) struct StructField {
  name : String
  is_mut : Bool
  ty : Type
} derive(Show, Eq)

///|
pub fn parse_struct_field(
  tokens : ArrayView[Token],
) -> (StructField, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}

///|
pub fn parse_struct_def(
  tokens : ArrayView[Token],
) -> (StructDef, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}
