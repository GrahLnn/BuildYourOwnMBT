///|
pub(all) struct Stmt {
  kind : StmtKind
} derive(Show, Eq)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show, Eq)

///|
fn stmt(pair : (StmtKind, ArrayView[Token])) -> (Stmt, ArrayView[Token]) {
  let (kind, rest) = pair
  (Stmt::{ kind, }, rest)
}

///|
pub fn parse_stmt(
  tokens : ArrayView[Token],
) -> (Stmt, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Keyword(Let) }, { kind: Keyword(Mut) }, ..] as tks => {
      let (s, r) = parse_let_mut_stmt(tks)
      stmt((LetMutStmt(s), r))
    }
    [{ kind: Keyword(Let) }, ..] as tks => {
      let (s, r) = parse_let_stmt(tks)
      stmt((LetStmt(s), r))
    }
    [{ kind: Keyword(While) }, ..] as tks => {
      let (s, r) = parse_while_stmt(tks)
      stmt((WhileStmt(s), r))
    }
    [{ kind: Keyword(Fn) }, ..] as tks => {
      let (s, r) = parse_local_function(tks)
      stmt((LocalFunction(s), r))
    }
    [{ kind: Keyword(Return) }, .. rest] =>
      match rest {
        [{ kind: Symbol(";") }, .. r] => stmt((ReturnStmt(None), r))
        _ => {
          let (e, r) = parse_expr(rest)
          guard r is [{ kind: Symbol(";") }, .. r]
          stmt((ReturnStmt(Some(e)), r))
        }
      }
    _ as tks =>
      try {
        let (s, r) = parse_assign_stmt(tks)
        stmt((AssignStmt(s), r))
      } catch {
        _ => {
          let (s, r) = parse_expr(tks)
          if r is [{ kind: Symbol(";") }, .. r] {
            stmt((ExprStmt(s), r))
          } else if r is [{ kind: Bracket('}') }, ..] {
            stmt((ExprStmt(s), r))
          } else {
            raise ParseError("Expected ';' or '}', found \{r[0].kind}")
          }
        }
      }
  }
}
