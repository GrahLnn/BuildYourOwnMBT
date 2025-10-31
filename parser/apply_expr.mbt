///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
} derive(Show, Eq)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show, Eq)

///|
fn apply_e(kind : ApplyExprKind) -> ApplyExpr {
  ApplyExpr::{ kind, }
}

///|
pub fn parse_apply_expr(
  tokens : ArrayView[Token],
) -> (ApplyExpr, ArrayView[Token]) raise ParseError {
  let (atom, rest) = parse_atom_expr(tokens)
  let init = apply_e(AtomExpr(atom))
  fn consume(
    acc : ApplyExpr,
    rest : ArrayView[Token],
  ) -> (ApplyExpr, ArrayView[Token]) raise ParseError {
    match rest {
      [{ kind: Bracket('[') }, .. r1] => {
        if r1 is [{ kind: Bracket(']') }, ..] {
          raise ParseError("Empty index not allowed")
        }
        let (idx, r2) = parse_expr(r1)
        match r2 {
          [{ kind: Bracket(']') }, .. r3] =>
            consume(apply_e(ArrayAccess(acc, idx)), r3)
          _ => raise ParseError("Expected ']'")
        }
      }
      [{ kind: Bracket('(') }, .. r1] => {
        let items = Array::new()
        loop r1 {
          [{ kind: Bracket(')') }, .. rest] =>
            break consume(apply_e(Call(acc, items)), rest)
          [{ kind: Symbol(",") }, { kind: Symbol(",") }, ..] =>
            raise ParseError("Consecutive commas not allowed")
          [{ kind: Symbol(",") }, .. r] => continue r
          _ as cur => {
            let (e, r) = parse_expr(cur)
            items.push(e)
            continue r
          }
        }
      }
      [{ kind: Symbol(".") }, .. rest] =>
        match rest {
          [{ kind: Lower(name) }, .. rest] =>
            consume(apply_e(FieldAccess(acc, name)), rest)
          _ => raise ParseError("Expected field name after '.'")
        }
      _ => (acc, rest)
    }
  }

  consume(init, rest)
}
