///|
pub(all) struct AtomExpr {
  kind : AtomExprKind
} derive(Show, Eq)

///|
pub(all) enum AtomExprKind {
  Int(Int) // 1, 42, etc
  Double(Double) // 1.0, 3.14, etc
  Bool(Bool) // true | false
  String(String) // "hello", etc
  Ident(String) // var
  Unit // ()
  Paren(Expr) // (expr)
  Tuple(Array[Expr]) // (expr, expr, ...)
  Array(Array[Expr]) // [expr, expr, ...]
  ArrayMake(Expr, Expr) // Array::make(size, init)
  StructConstruct(StructConstructExpr) // StructName::{ field: expr, ... }
} derive(Show, Eq)

///|
fn atom_e(kind : AtomExprKind) -> AtomExpr {
  AtomExpr::{ kind, }
}

///|
pub fn parse_atom_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Int(value) }, .. rest] => (atom_e(Int(value)), rest)
    [{ kind: Double(value) }, .. rest] => (atom_e(Double(value)), rest)
    [{ kind: Bool(value) }, .. rest] => (atom_e(Bool(value)), rest)
    [{ kind: String(value) }, .. rest] => (atom_e(String(value)), rest)
    [{ kind: Lower(name) }, .. rest] => (atom_e(Ident(name)), rest)
    [{ kind: Bracket('(') }, ..] as tks => parse_paren_expr(tks)
    [{ kind: Bracket('[') }, ..] as tks => parse_array_expr(tks)
    [{ kind: Upper("Array") }, ..] as tks => parse_array_make_expr(tks)
    [{ kind: Upper(_) }, ..] as tks => parse_struct_construct(tks)
    _ => raise ParseError("Unexpected atom, found \{tokens[0]}")
  }
}

///|
fn build_paren(exprs : Array[Expr]) -> AtomExpr {
  match exprs.length() {
    0 => atom_e(Unit)
    1 => atom_e(Paren(exprs[0]))
    _ => atom_e(Tuple(exprs))
  }
}

///|
fn build_array_make_expr(exprs : Array[Expr]) -> AtomExpr raise ParseError {
  guard exprs.length() == 2 else {
    raise ParseError("Array make expr must have two arguments")
  }
  atom_e(ArrayMake(exprs[0], exprs[1]))
}

///|
fn parse_array_make_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  guard tokens
    is [
      { kind: Upper("Array") },
      { kind: Symbol("::") },
      { kind: Lower("make") },
      { kind: Bracket('(') },
      .. tokens,
    ]
  let exprs = Array::new()
  loop tokens {
    [{ kind: Bracket(')') }, .. rest] =>
      break (build_array_make_expr(exprs), rest)
    [{ kind: Symbol(",") }, { kind: Bracket(')') }, ..] =>
      raise ParseError("Trailing comma not allowed")
    [{ kind: Symbol(",") }, .. rest] => continue rest
    _ as tokens => {
      let (expr, rest) = parse_expr(tokens)
      exprs.push(expr)
      continue rest
    }
  }
}

///|
pub fn parse_delimited_list(
  toks : ArrayView[Token],
  starter : Char,
  delimiter : Char,
) -> (Array[Expr], ArrayView[Token]) raise ParseError {
  match toks {
    [{ kind: Bracket(b) }, .. rest] if b == starter => {
      if rest is [{ kind: Symbol(",") }, ..] {
        raise ParseError("Beginning with a comma not allowed")
      }
      let items = Array::new()
      loop rest {
        [{ kind: Bracket(b) }, .. r2] if b == delimiter => break (items, r2)
        [{ kind: Symbol(",") }, { kind: Symbol(",") }, ..] =>
          raise ParseError("Consecutive commas not allowed")
        [{ kind: Symbol(",") }, .. r2] => continue r2
        _ as cur => {
          let (e, r2) = parse_expr(cur)
          items.push(e)
          continue r2
        }
      }
    }
    _ => raise ParseError("Expected opener")
  }
}

///|
fn parse_paren_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  let (exprs, rest) = parse_delimited_list(tokens, '(', ')')
  (build_paren(exprs), rest)
}

///|
fn parse_array_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  let (exprs, rest) = parse_delimited_list(tokens, '[', ']')
  (atom_e(Array(exprs)), rest)
}
