///|
pub(all) struct LeftValue {
  kind : LeftValueKind
} derive(Show, Eq)

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show, Eq)

///|
fn consume(
  acc : LeftValue,
  rest : ArrayView[Token],
) -> (LeftValue, ArrayView[Token]) raise ParseError {
  match rest {
    [{ kind: Bracket('[') }, .. r1] => {
      if r1 is [{ kind: Bracket(']') }, ..] {
        raise ParseError("Empty index not allowed")
      }
      let (idx, r2) = parse_expr(r1)
      match r2 {
        [{ kind: Bracket(']') }, .. r3] =>
          consume(LeftValue::{ kind: ArrayAccess(acc, idx) }, r3)
        _ => raise ParseError("Expected ']'")
      }
    }
    [{ kind: Symbol(".") }, .. rest] =>
      match rest {
        [{ kind: Lower(name) }, .. rest] =>
          consume(LeftValue::{ kind: FieldAccess(acc, name) }, rest)
        _ => raise ParseError("Expected field name after '.'")
      }
    _ => (acc, rest)
  }
}

///|
pub fn parse_left_value(
  tokens : ArrayView[Token],
) -> (LeftValue, ArrayView[Token]) raise ParseError {
  let (ident, rest) : (LeftValueKind, ArrayView[Token]) = match tokens {
    [{ kind: Lower(name) }, .. tokens] => (Ident(name), tokens)
    _ => raise ParseError("Expected identifier")
  }
  consume(LeftValue::{ kind: ident }, rest)
}
