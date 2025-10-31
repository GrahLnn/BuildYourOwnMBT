///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
} derive(Show, Eq)

///|
pub fn parse_if_expr(
  tokens : ArrayView[Token],
) -> (IfExpr, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(If) }, .. rest]
  let (cond, rest) = parse_expr(rest)
  let (then_block, rest) = parse_block_expr(rest)
  let (else_block, rest) = match rest {
    [{ kind: Keyword(Else) }, .. rest] =>
      match rest {
        [{ kind: Keyword(If) }, ..] as rest => {
          let (if_expr, r) = parse_if_expr(rest)
          (Some(Left(if_expr)), r)
        }
        _ => {
          let (blk, r) = parse_block_expr(rest)
          (Some(Right(blk)), r)
        }
      }
    _ as rest => (None, rest)
  }
  (IfExpr::{ cond, then_block, else_block }, rest)
}
