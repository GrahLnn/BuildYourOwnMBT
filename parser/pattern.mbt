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
fn pet(kind : PatternKind) -> Pattern {
  Pattern::{ kind, }
}

///|
pub fn parse_pattern(
  tokens : ArrayView[Token],
) -> (Pattern, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Wildcard }, .. rest] => (pet(Wildcard), rest)
    [{ kind: Lower(name) }, .. rest] => (pet(Ident(name)), rest)
    [{ kind: Bracket('(') }, ..] as tks => parse_tuple_pattern(tks)
    _ => raise ParseError("Invalid pattern")
  }
}

///|
fn parse_tuple_pattern(
  tokens : ArrayView[Token],
) -> (Pattern, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Bracket('(') }, .. tokens]
  let items = Array::new()
  loop tokens {
    [{ kind: Bracket(')') }, .. rest] => break (pet(Tuple(items)), rest)
    [{ kind: Symbol(",") }, { kind: Symbol(",") }, ..] =>
      raise ParseError("Consecutive commas not allowed")
    [{ kind: Symbol(",") }, .. r] => continue r
    _ as cur => {
      let (e, r) = parse_pattern(cur)
      items.push(e)
      continue r
    }
  }
}
