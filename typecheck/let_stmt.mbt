///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub(all) struct Pattern {
  kind : PatternKind
} derive(Show, Eq)

///|
pub(all) enum PatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[Pattern])
} derive(Show, Eq)

///|
pub fn Context::check_let_stmt(
  self : Context,
  let_stmt : @parser.LetStmt,
) -> LetStmt raise TypeCheckError {
  let expr = self.check_expr(let_stmt.expr)
  let pattern = pattern_into(let_stmt.pattern)
  self.bind_pattern_type(pattern, expr.ty)
  LetStmt::{ pattern, ty: expr.ty, expr }
}

///|
fn pattern_into(pattern : @parser.Pattern) -> Pattern {
  match pattern.kind {
    Wildcard => Pattern::{ kind: Wildcard }
    Ident(name) => Pattern::{ kind: Ident(name) }
    Tuple(patterns) => Pattern::{ kind: Tuple(patterns.map(pattern_into)) }
  }
}

///|
fn Context::bind_pattern_type(
  self : Self,
  pattern : Pattern,
  ty : TypeKind,
) -> Unit raise TypeCheckError {
  match pattern.kind {
    Wildcard => ()
    Ident(name) => self.push_type(name, ty, false)
    Tuple(patterns) =>
      match ty {
        Tuple(t) => {
          guard t.length() == patterns.length() else {
            raise TypeCheckError("Pattern and type mismatch")
          }
          loop patterns[:] {
            [p, .. rest] => {
              self.bind_pattern_type(p, t[0])
              continue rest
            }
            [] => break
          }
        }
        _ => raise TypeCheckError("Should be a tuple type")
      }
  }
}
