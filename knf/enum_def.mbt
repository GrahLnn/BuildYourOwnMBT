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

///|
/// 给定 scrutinee 的 KNF 类型和模式里的枚举名字/变体名字, 查出该变体的字段类型列表
/// 以及该变体在枚举定义中的索引。
pub fn Context::lookup_enum_variant_field_types(
  self : Context,
  scr_ty : Type,
  enum_name_opt : String?,
  variant_name : String,
) -> (Array[Type], Int) raise KnfTransformError {
  // 从 scr_ty 推出真正的枚举名: 允许 Enum(name) 或 Struct(name) 两种情况
  let enum_name = match scr_ty {
    Enum(n) => n
    Struct(n) => n
    _ =>
      raise KnfTransformError("Enum pattern on non-enum/struct type: \{scr_ty}")
  }

  // 如果模式里显式写了枚举名, 做一次一致性检查
  match enum_name_opt {
    Some(explicit) =>
      if explicit != enum_name {
        raise KnfTransformError(
          "Enum pattern name mismatch: expect \{enum_name}, got \{explicit}",
        )
      }
    None => ()
  }
  let edef = self.enum_defs
    .get(enum_name)
    .unwrap_or_else(() => raise KnfTransformError(
      "Enum def not found: \{enum_name}",
    ))

  // 通过名字查找变体索引
  let variant_names = edef.variants.map(v => v.name)
  let variant_index = variant_names
    .search(variant_name)
    .unwrap_or_else(() => raise KnfTransformError(
      "Variant not found: \{enum_name}::\{variant_name}",
    ))
  let field_tys = edef.variants[variant_index].fields
  (field_tys, variant_index)
}
