///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_let_stmt(
  tokens : ArrayView[Token],
) -> (LetStmt, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Let) }, .. tokens]
  let (pattern, tokens) = parse_pattern(tokens)
  let (ty, tokens) = match tokens {
    [{ kind: Symbol(":") }, .. tokens] => {
      let (ty, tokens) = parse_type(tokens)
      (Some(ty), tokens)
    }
    _ => (None, tokens)
  }
  guard tokens is [{ kind: AssignOp(Assign) }, .. tokens]
  let (expr, tokens) = parse_expr(tokens)
  guard tokens is [{ kind: Symbol(";") }, .. tokens]
  (LetStmt::{ pattern, ty, expr }, tokens)
}
