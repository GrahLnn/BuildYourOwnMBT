///|
pub(all) struct EnumDef {
  name : String
  generic : String?
  variants : Array[EnumVariant]
} derive(Show)

///|
pub(all) struct EnumVariant {
  name : String
  fields : Array[Type]
} derive(Show)

///|
pub fn Context::check_enum_def(
  self : Self,
  enum_def : @parser.EnumDef,
) -> EnumDef raise TypeCheckError {
  let variants = enum_def.variants.map(v => {
    let field_tys = v.fields.map(t => self.check_parser_type(t, mutable=false))
    EnumVariant::{ name: v.name, fields: field_tys }
  })
  EnumDef::{ name: enum_def.name, generic: enum_def.generic, variants }
}
