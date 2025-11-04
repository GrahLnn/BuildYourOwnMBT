///|
pub fn Context::atom_expr_to_knf(
  self : Context,
  atom_expr : @typecheck.AtomExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match atom_expr.kind {
    Int(n) => (Array::new(), Int(n))
    Double(n) => (Array::new(), Double(n))
    Bool(b) => (Array::new(), Bool(b))
    String(s) => (Array::new(), String(s))
    Ident(name) => {
      let look = self.lookup_name(name)
      guard look is Some((name, _)) else {
        raise KnfTransformError("Unknown identifier: \{name}")
      }
      (Array::new(), Ident(name))
    }
    Unit => (Array::new(), Unit)
    Paren(expr) => self.expr_to_knf(expr)
    Tuple(exprs) => {
      let stmts = Array::new()
      let names = Array::new()
      exprs.each(e => {
        let ty = self.typekind_to_knf(e.ty)
        let (s, e) = self.expr_to_knf(e)
        stmts.append(s)
        names.push(self.expr_to_knf_name(e, ty, stmts))
      })
      (stmts, TupleLiteral(names))
    }
    Array(exprs) => {
      let ty = self.typekind_to_knf(atom_expr.ty)
      let stmts = Array::new()
      let names = Array::new()
      exprs.each(e => {
        let t = self.typekind_to_knf(e.ty)
        let (s, e) = self.expr_to_knf(e)
        stmts.append(s)
        names.push(self.expr_to_knf_name(e, t, stmts))
      })
      (stmts, ArrayLiteral(ty, names))
    }
    ArrayMake(size, init) => {
      let (size_knf, size_expr) = self.expr_to_knf(size)
      let (init_knf, init_expr) = self.expr_to_knf(init)
      let size_name = self.expr_to_knf_name(
        size_expr,
        self.typekind_to_knf(size.ty),
        size_knf,
      )
      let init_name = self.expr_to_knf_name(
        init_expr,
        self.typekind_to_knf(init.ty),
        init_knf,
      )
      (size_knf + init_knf, ArrayMake(size_name, init_name))
    }
    StructConstruct(expr) => {
      let struct_name = expr.name
      let fields = Array::new()
      let stmts = Array::new()
      expr.fields.each(f => {
        let (n, f) = f
        let (s, e) = self.expr_to_knf(f)
        let name = self.expr_to_knf_name(e, self.typekind_to_knf(f.ty), s)
        stmts.append(s)
        fields.push((n, name))
      })
      (stmts, CreateStruct(struct_name, fields))
    }
  }
}
