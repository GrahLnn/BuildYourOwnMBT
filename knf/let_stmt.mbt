///|
pub fn Context::let_stmt_to_knf(
  self : Context,
  let_stmt : @typecheck.LetStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let knf = self.expr_to_knf(let_stmt.expr)
  match let_stmt.pattern.kind {
    Wildcard => {
      let ty = self.typekind_to_knf(let_stmt.ty)
      let name = Name::wildcard()
      let (s, e) = knf
      s.push(Let(name, ty, e))
      s
    }
    Ident(n) => {
      let ty = self.typekind_to_knf(let_stmt.ty)
      let name = self.add_new_name(n, ty)
      let (s, e) = knf
      s.push(Let(name, ty, e))
      s
    }
    Tuple(patterns) => self.pattern_to_expr(patterns, knf, let_stmt.ty)
  }
}

///|
fn Context::pattern_to_expr(
  self : Context,
  patterns : Array[@typecheck.Pattern],
  knf : (Array[KnfStmt], KnfExpr),
  ty : @typecheck.TypeKind,
) -> Array[KnfStmt] raise KnfTransformError {
  guard ty is Tuple(tys) else {
    raise KnfTransformError("Type mismatch in tuple destructuring")
  }
  let (s, e) = knf
  match e {
    TupleLiteral(eles) =>
      eles.eachi((i, ele) => match patterns[i].kind {
        Wildcard => ()
        Ident(n) => {
          let ty = self.typekind_to_knf(tys[i])
          let name = self.add_new_name(n, ty)
          s.push(Let(name, ty, Ident(ele)))
        }
        _ =>
          raise KnfTransformError("Nested tuple destructuring not implemented")
      })
    Ident(tuple_name) =>
      patterns.eachi((i, pattern) => match pattern.kind {
        Wildcard => ()
        Ident(n) => {
          let elem_ty = self.typekind_to_knf(tys[i])
          let name = self.add_new_name(n, elem_ty)
          s.push(Let(name, elem_ty, TupleAccess(tuple_name, i)))
        }
        _ =>
          raise KnfTransformError("Nested tuple destructuring not implemented")
      })
    _ => {
      let tuple_ty = self.typekind_to_knf(ty)
      let tmp_name = self.add_temp(tuple_ty)
      s.push(Let(tmp_name, tuple_ty, e))
      patterns.eachi((i, pattern) => match pattern.kind {
        Wildcard => ()
        Ident(n) => {
          let elem_ty = self.typekind_to_knf(tys[i])
          let name = self.add_new_name(n, elem_ty)
          s.push(Let(name, elem_ty, TupleAccess(tmp_name, i)))
        }
        _ =>
          raise KnfTransformError("Nested tuple destructuring not implemented")
      })
    }
  }
  s
}
