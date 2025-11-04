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
        // Tuple(patts) => {
        //   let ele_ty = self.name_env.get_name_type(ele)
        //   guard ele_ty is Some(ty)
        //   match ty {
        //     Tuple(tys) => {
        //       let (s, e) = self.pattern_to_knf(patts, (s, ele), tys[i])

        //     }
        //     _ => raise KnfTransformError("Expected tuple type")
        //   }
        // }
        _ => raise KnfTransformError("Tuple not implemented")
      })
    _ => raise KnfTransformError("Expected tuple literal")
  }
  s
}
