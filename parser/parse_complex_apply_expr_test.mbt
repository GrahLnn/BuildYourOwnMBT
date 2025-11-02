///|
test "Complex Apply Expr Parsing Test" {
  let code =
    #|obj.field1[0].method(a1, b2) ;
    #|matrix[1][2].to_string() ;
    #|arr[3](5)[7]
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(
    a.kind is Call(call_expr, [a1, a2]) &&
    a1.kind is ApplyExpr(arg1) &&
    arg1.kind is AtomExpr(atom_a1) &&
    atom_a1.kind is Ident("a1") &&
    a2.kind is ApplyExpr(arg2) &&
    arg2.kind is AtomExpr(atom_b2) &&
    atom_b2.kind is Ident("b2") &&
    call_expr.kind is FieldAccess(field_access2, field_name2) &&
    field_name2 is "method" &&
    field_access2.kind is ArrayAccess(array_access, index_expr) &&
    index_expr.kind is ApplyExpr(index_apply) &&
    index_apply.kind is AtomExpr(index_atom) &&
    index_atom.kind is Int(0) &&
    array_access.kind is FieldAccess(field_access, field_name) &&
    field_name is "field1" &&
    field_access.kind is AtomExpr(atom_obj) &&
    atom_obj.kind is Ident("obj"),
  )
  let (a, tok_view) = parse_apply_expr(tok_view[1:])
  assert_true(
    a.kind is Call(call_expr2, []) &&
    call_expr2.kind is FieldAccess(field_access4, field_name4) &&
    field_name4 is "to_string" &&
    field_access4.kind is ArrayAccess(array_access2, index_expr2) &&
    index_expr2.kind is ApplyExpr(index_apply2) &&
    index_apply2.kind is AtomExpr(index_atom2) &&
    index_atom2.kind is Int(2) &&
    array_access2.kind is ArrayAccess(array_access1, index_expr1) &&
    index_expr1.kind is ApplyExpr(index_apply1) &&
    index_apply1.kind is AtomExpr(index_atom1) &&
    index_atom1.kind is Int(1) &&
    array_access1.kind is AtomExpr(atom_matrix) &&
    atom_matrix.kind is Ident("matrix"),
  )
  let (a, _) = parse_apply_expr(tok_view[1:])
  assert_true(
    a.kind is ArrayAccess(array_access3, index_expr3) &&
    index_expr3.kind is ApplyExpr(index_apply3) &&
    index_apply3.kind is AtomExpr(index_atom3) &&
    index_atom3.kind is Int(7) &&
    array_access3.kind is Call(call_expr3, [arg_expr]) &&
    arg_expr.kind is ApplyExpr(arg_apply) &&
    arg_apply.kind is AtomExpr(arg_atom) &&
    arg_atom.kind is Int(5) &&
    call_expr3.kind is ArrayAccess(array_access4, index_expr4) &&
    index_expr4.kind is ApplyExpr(index_apply4) &&
    index_apply4.kind is AtomExpr(index_atom4) &&
    index_atom4.kind is Int(3) &&
    array_access4.kind is AtomExpr(atom_arr) &&
    atom_arr.kind is Ident("arr"),
  )
}
