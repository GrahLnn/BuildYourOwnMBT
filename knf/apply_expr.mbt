///|
pub fn Context::apply_expr_to_knf(
  self : Context,
  apply_expr : @typecheck.ApplyExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match apply_expr.kind {
    AtomExpr(atom_expr) => self.atom_expr_to_knf(atom_expr)
    FieldAccess(appexpr, fieldname) => {
      let (stmts, expr) = self.apply_expr_to_knf(appexpr)
      let ty = self.typekind_to_knf(appexpr.ty)
      let name = self.expr_to_knf_name(expr, ty, stmts)
      (stmts, FieldAccess(name, fieldname))
    }
    ArrayAccess(appexpr, expr) => {
      let (stmts, kexpr) = self.apply_expr_to_knf(appexpr)
      let ty = self.typekind_to_knf(appexpr.ty)
      let name = self.expr_to_knf_name(kexpr, ty, stmts)
      let (bstmts, bexpr) = self.expr_to_knf(expr)
      let ty = self.typekind_to_knf(expr.ty)
      let bname = self.expr_to_knf_name(bexpr, ty, bstmts)
      (stmts + bstmts, ArrayAccess(name, bname))
    }
    Call(appexpr, exprs) => {
      let (stmts, kexpr) = self.apply_expr_to_knf(appexpr)
      let ty = self.typekind_to_knf(appexpr.ty)
      let name = self.expr_to_knf_name(kexpr, ty, stmts)
      let names = exprs.map(expr => {
        let (bstmts, bexpr) = self.expr_to_knf(expr)
        let ty = self.typekind_to_knf(expr.ty)
        let bname = self.expr_to_knf_name(bexpr, ty, bstmts)
        stmts.append(bstmts)
        bname
      })
      (stmts, Call(name, names))
    }
  }
}
