///|
pub(all) struct LetMutStmt {
  name : String
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_let_mut_stmt(
  tokens : ArrayView[Token],
) -> (LetMutStmt, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Let) }, { kind: Keyword(Mut) }, .. tokens]
  let (name, tokens) = match tokens {
    [{ kind: Lower(name) }, .. tokens] => (name, tokens)
    _ => raise ParseError("Expected identifier")
  }
  let (ty, tokens) = match tokens {
    [{ kind: Symbol(":") }, .. tokens] => {
      let (ty, tokens) = parse_type(tokens)
      (Some(ty), tokens)
    }
    _ => (None, tokens)
  }
  guard tokens is [{ kind: AssignOp(Assign) }, .. tokens] else {
    raise ParseError("Expected assignment operator")
  }
  let (expr, tokens) = parse_expr(tokens)
  guard tokens is [{ kind: Symbol(";") }, .. tokens] else {
    raise ParseError("Expected semicolon")
  }
  (LetMutStmt::{ name, ty, expr }, tokens)
}
