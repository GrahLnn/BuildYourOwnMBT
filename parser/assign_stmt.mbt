///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show, Eq)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
fn AssignOp::from_tok_assign_op(op : @lexer.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn parse_assign_stmt(
  tokens : ArrayView[Token],
) -> (AssignStmt, ArrayView[Token]) raise ParseError {
  let (left_value, tokens) = parse_left_value(tokens)
  let (op, tokens) = match tokens {
    [{ kind: AssignOp(op) }, .. tokens] =>
      (AssignOp::from_tok_assign_op(op), tokens)
    _ => raise ParseError("Expected assignment operator")
  }
  let (expr, tokens) = parse_expr(tokens)
  guard tokens is [{ kind: Symbol(";") }, .. tokens] else {
    raise ParseError("Expected semicolon")
  }
  (AssignStmt::{ left_value, op, expr }, tokens)
}
