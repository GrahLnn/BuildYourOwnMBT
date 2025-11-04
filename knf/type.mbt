///|
pub(all) enum Type {
  Unit
  Int
  Bool
  Double
  String
  Array(Type)
  Struct(String)
  Tuple(Array[Type])
  Function(Array[Type], Type)
}

///|
pub impl Show for Type with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Int => "Int"
    Bool => "Bool"
    Double => "Double"
    String => "String"
    Array(elem_type) => "Array[\{elem_type}]"
    Struct(name) => "\{name}"
    Tuple(elem_types) => {
      let elem_strs = elem_types.map(et => "\{et}").join(", ")
      "(\{elem_strs})"
    }
    Function(param_types, ret_type) => {
      let param_strs = param_types.map(pt => "\{pt}").join(", ")
      "(\{param_strs}) -> \{ret_type}"
    }
  }
  logger.write_string(s)
}

///|
pub fn Context::typekind_to_knf(
  self : Context,
  tk : @typecheck.TypeKind,
) -> Type raise KnfTransformError {
  match tk {
    Unit => Unit
    Int => Int
    Bool => Bool
    Double => Double
    String => String
    Array(elem_type) => Array(self.typekind_to_knf(elem_type))
    Struct(name) => Struct(name)
    Tuple(elem_types) => Tuple(elem_types.map(et => self.typekind_to_knf(et)))
    Function(param_types, ret_type) =>
      Function(
        param_types.map(pt => self.typekind_to_knf(pt)),
        self.typekind_to_knf(ret_type),
      )
    _ => raise KnfTransformError("typekind_to_knf Not implemented, found \{tk}")
  }
}

///|
pub fn Context::type_to_knf(
  self : Context,
  t : @typecheck.Type,
) -> Type raise KnfTransformError {
  self.typekind_to_knf(t.kind)
}
