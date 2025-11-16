// ///|
// pub(all) struct KnfEnumDef {
//   name : String
//   variants : Array[(String, Array[Type])]
// }

// ///|
// pub fn Context::enum_def_to_knf(
//   self : Context,
//   enum_def : @typecheck.EnumDef,
// ) -> KnfEnumDef raise KnfTransformError {
//   let variants = enum_def.variants.map(v => {
//     let name = v.name
//     let ty = self.type_to_knf(v.ty)
//     (name, ty)
//   })
//   KnfEnumDef::{ name: enum_def.name, variants }
// }
