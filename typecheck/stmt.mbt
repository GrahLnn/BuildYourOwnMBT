///|
pub(all) struct Stmt {
  kind : StmtKind
} derive(Show)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show)

///|
pub fn Context::check_stmt(
  self : Context,
  stmt : @parser.Stmt,
) -> Stmt raise TypeCheckError {
  let kind = match stmt.kind {
    LetStmt(s) => LetStmt(self.check_let_stmt(s))
    LetMutStmt(s) => LetMutStmt(self.check_let_mut_stmt(s))
    AssignStmt(s) => AssignStmt(self.check_assign_stmt(s))
    WhileStmt(s) => WhileStmt(self.check_while_stmt(s))
    ExprStmt(s) => ExprStmt(self.check_expr(s))
    LocalFunction(s) => LocalFunction(self.check_local_function(s))
    ReturnStmt(s) => ReturnStmt(self.check_return(s))
  }
  Stmt::{ kind, }
}

///|
pub fn Context::substitute_stmt(
  self : Context,
  stmt : Stmt,
) -> Stmt raise TypeCheckError {
  let kind = match stmt.kind {
    LetStmt(s) => LetStmt(self.substitute_let_stmt(s))
    LetMutStmt(s) => LetMutStmt(self.substitute_let_mut_stmt(s))
    AssignStmt(s) => AssignStmt(self.substitute_assign_stmt(s))
    WhileStmt(s) => WhileStmt(self.substitute_while_stmt(s))
    ExprStmt(s) => ExprStmt(self.substitute_expr(s))
    ReturnStmt(s) => ReturnStmt(self.substitute_return(s))
    LocalFunction(s) => LocalFunction(self.substitute_local_function(s))
  }
  Stmt::{ kind, }
}

///|
fn Context::check_return(
  self : Context,
  stmt : @parser.Expr?,
) -> Expr? raise TypeCheckError {
  match stmt {
    None => {
      guard self.current_func_ret_ty is Some(Unit) else {
        raise TypeCheckError(
          "return statement without value in a function that does not return a value",
        )
      }
      None
    }
    Some(s) => {
      let expr = self.check_expr(s)
      match self.current_func_ret_ty {
        Some(ty) =>
          if self.is_type_compatible(expr.ty, ty) {
            ()
          } else {
            raise TypeCheckError(
              "return statement with value of type \{expr.ty} in a function that returns \{self.current_func_ret_ty.unwrap()}",
            )
          }
        None =>
          raise TypeCheckError(
            "return statement with value in a function that does not return a value",
          )
      }
      Some(expr)
    }
  }
}

///|
fn Context::substitute_return(
  self : Context,
  stmt : Expr?,
) -> Expr? raise TypeCheckError {
  match stmt {
    None => stmt
    Some(s) => Some(self.substitute_expr(s))
  }
}
