///|
pub(all) struct KnfEnumVariant {
  name : String
  fields : Array[Type] // 这里是 knf.Type
} derive(Show)

///|
pub(all) struct KnfEnumDef {
  name : String
  variants : Array[KnfEnumVariant]
} derive(Show)

///|
pub fn Context::enum_def_to_knf(
  self : Context,
  enum_def : @typecheck.EnumDef,
) -> KnfEnumDef raise KnfTransformError {
  let variants = enum_def.variants.map(v => {
    let field_tys = v.fields.map(ft => self.type_to_knf(ft))
    KnfEnumVariant::{ name: v.name, fields: field_tys }
  })
  KnfEnumDef::{ name: enum_def.name, variants }
}
