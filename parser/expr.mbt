///|
pub(all) struct Expr {
  kind : ExprKind
} derive(Show, Eq)

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
} derive(Show, Eq)

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Show, Eq)

///|
fn BinaryOp::from_tok_binary_op(tok_bin_op : @lexer.BinaryOp) -> BinaryOp {
  match tok_bin_op {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Mod => Mod
    ShiftLeft => ShiftLeft
    ShiftRight => ShiftRight
    Eq => Eq
    NE => NE
    LT => LT
    GT => GT
    LE => LE
    GE => GE
    And => And
    Or => Or
    BitAnd => BitAnd
    BitOr => BitOr
  }
}

///|
fn expr(kind : ExprKind) -> Expr {
  Expr::{ kind, }
}

///|
fn tok_prec(op_tok : @lexer.BinaryOp) -> Int {
  BinaryOp::from_tok_binary_op(op_tok).precedence()
}

///|
fn parse_tail(
  lhs : Expr,
  rest : ArrayView[Token],
  min_bp : Int,
) -> (Expr, ArrayView[Token]) raise ParseError {
  match rest {
    [{ kind: BinaryOp(op_tok) }, .. r2] => {
      let bp = tok_prec(op_tok)
      if bp < min_bp {
        (lhs, rest)
      } else {
        let (rhs, r3) = parse_expr(r2, min_bp=bp + 1)
        let op = BinaryOp::from_tok_binary_op(op_tok)
        let lhs2 = expr(BinaryExpr(op, lhs, rhs))
        parse_tail(lhs2, r3, min_bp)
      }
    }
    _ => (lhs, rest)
  }
}

///|
pub fn parse_expr(
  tokens : ArrayView[Token],
  min_bp? : Int = 0,
) -> (Expr, ArrayView[Token]) raise ParseError {
  let (lhs0, rest0) = match tokens {
    [{ kind: Keyword(If) }, ..] as tks => {
      let (e, r) = parse_if_expr(tks)
      (expr(IfExpr(e)), r)
    }
    [{ kind: Bracket('{') }, ..] as tks => {
      let (e, r) = parse_block_expr(tks)
      (expr(BlockExpr(e)), r)
    }
    [{ kind: Not }, .. r] => {
      let (e, r2) = parse_expr(r)
      (expr(NotExpr(e)), r2)
    }
    [{ kind: BinaryOp(Sub) }, .. r] => {
      let (e, r2) = parse_expr(r)
      (expr(NegExpr(e)), r2)
    }
    _ => {
      let (ap, r) = parse_apply_expr(tokens)
      (expr(ApplyExpr(ap)), r)
    }
  }
  parse_tail(lhs0, rest0, min_bp)
}

///|
fn BinaryOp::precedence(self : Self) -> Int {
  match self {
    Or => 1
    And => 2
    Eq | NE => 3
    LT | GT | LE | GE => 4
    BitOr => 5
    BitAnd => 7
    ShiftLeft | ShiftRight => 8
    Add | Sub => 9
    Mul | Div | Mod => 10
  }
}
