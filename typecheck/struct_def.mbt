///|
pub(all) struct StructDef {
  name : String
  fields : Array[StructField]
} derive(Show)

///|
pub(all) struct StructField {
  name : String
  ty : Type
} derive(Show)

///|
pub fn StructDef::get_field_type(self : Self, field_name : String) -> Type? {
  for field in self.fields {
    if field.name == field_name {
      return Some(field.ty)
    }
  }
  return None
}

///|
pub fn Context::check_struct_def(
  self : Self,
  struct_def : @parser.StructDef,
) -> StructDef raise TypeCheckError {
  let name = struct_def.name
  let fields = struct_def.fields.map(field => StructField::{
    name: field.name,
    ty: self.check_parser_type(field.ty, mutable=field.is_mut),
  })
  StructDef::{ name, fields }
}
