///|
pub(all) struct Type {
  kind : TypeKind
} derive(Show, Eq)

///|
pub(all) enum TypeKind {
  Unit
  Bool
  Int
  Double
  String
  Tuple(Array[TypeKind])
  Array(TypeKind)
  Function(Array[TypeKind], TypeKind)
  Defined(String)
} derive(Hash, Eq) // Show defined manually in `parser_aux.mbt`

///|
pub fn parse_type(
  tokens : ArrayView[Token],
) -> (Type, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}

///|
pub impl Show for TypeKind with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Bool => "Bool"
    Int => "Int"
    Double => "Double"
    String => "String"
    Tuple(tys) => {
      let inner = tys.map(ty => ty.to_string()).join(", ")
      "(\{inner})"
    }
    Array(ty) => "Array[\{ty}]"
    Function(params, ret) => {
      let param_str = params.map(ty => ty.to_string()).join(", ")
      "(\{param_str}) -> \{ret}"
    }
    Defined(name) => name
  }
  logger.write_string(s)
}
