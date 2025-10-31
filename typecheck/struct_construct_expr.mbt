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
  let fields = sc_expr.fields.map(fields => {
    let (name, expr) = fields
    (name, self.check_expr(expr))
  })
  let name = sc_expr.name
  (StructConstructExpr::{ name, fields }, Struct(name))
}
