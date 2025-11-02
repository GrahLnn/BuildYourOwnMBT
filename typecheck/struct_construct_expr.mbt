///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show)

///|
pub fn Context::check_struct_construct_expr(
  self : Self,
  sc_expr : @parser.StructConstructExpr,
) -> (StructConstructExpr, TypeKind) raise TypeCheckError {
  let name = sc_expr.name
  let definition = self.struct_defs.get(name)
  guard definition is Some(definition) else {
    raise TypeCheckError("Struct \{name} undefined")
  }
  let defined_field_names = definition.fields.map(field => field.name)
  guard sc_expr.fields.length() == defined_field_names.length() else {
    raise TypeCheckError(
      "Struct \{name} has \{defined_field_names.length()} fields, but \{sc_expr.fields.length()} were provided",
    )
  }
  let fields = sc_expr.fields.map(fields => {
    let (name, expr) = fields
    guard defined_field_names.contains(name) else {
      raise TypeCheckError("Field \{name} not defined in struct \{name}")
    }
    let expr = self.check_expr(expr)
    guard self.is_type_compatible(
      expr.ty,
      definition.fields.filter(f => f.name == name).map(f => f.ty.kind)[0],
    ) else {
      raise TypeCheckError("Type mismatch for field \{name} in struct \{name}")
    }
    (name, expr)
  })
  (StructConstructExpr::{ name, fields }, Struct(name))
}
