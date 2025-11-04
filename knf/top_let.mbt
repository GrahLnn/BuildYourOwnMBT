///|
pub(all) struct KnfTopLet {
  name : Name
  ty : Type
  expr : KnfExpr
}

///|
pub fn Context::top_let_to_knf(
  self : Context,
  top_let : @typecheck.TopLet,
) -> KnfTopLet raise KnfTransformError {
  let ty = self.type_to_knf(top_let.ty)
  let name = self.add_new_name(top_let.name, ty)
  guard self.globals.get(top_let.name) is None else {
    raise KnfTransformError(
      "Duplicate global variable declaration: \{top_let.name}",
    )
  }
  self.globals.set(top_let.name, ty)
  let (_, expr) = self.expr_to_knf(top_let.expr)
  KnfTopLet::{ name, ty, expr }
}

///|
pub impl Show for KnfTopLet with output(self, logger) {
  let { name, ty, expr } = self
  logger.write_string("let \{name} : \{ty} = \{expr};")
}
