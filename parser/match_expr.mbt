///|
pub(all) struct MatchExpr {
  expr : Expr
  arms : Array[MatchArm]
} derive(Show, Eq)

///|
pub(all) struct MatchArm {
  pattern : ArmPattern
  body : Expr
} derive(Show, Eq)

///|
pub(all) struct ArmPattern {
  kind : ArmPatternKind
} derive(Show, Eq)

///|
pub(all) enum ArmPatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[ArmPattern])
  Bool(Bool)
  Enum(String?, String, Array[ArmPattern]?)
  Int(Int)
  Double(Double)
} derive(Show, Eq)

///|
fn ap(kind : ArmPatternKind) -> ArmPattern {
  ArmPattern::{ kind, }
}

///|
pub fn parse_match_expr(
  tokens : ArrayView[Token],
) -> (MatchExpr, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Match) }, .. tokens]
  let (expr, rest) = parse_expr(tokens)
  guard rest is [{ kind: Bracket('{') }, .. rest] else {
    raise ParseError("Expected '{' after 'match'")
  }
  let arms = Array::new()
  loop rest {
    [{ kind: Bracket('}') }, .. rest] => break (MatchExpr::{ expr, arms }, rest)
    [{ kind: Symbol(";") }, .. rest] => continue rest
    _ as rest => {
      let (arm, r) = parse_arm(rest)
      arms.push(arm)
      continue r
    }
  }
}

///|
pub fn parse_arm(
  tokens : ArrayView[Token],
) -> (MatchArm, ArrayView[Token]) raise ParseError {
  let (pattern, r) = parse_arm_pattern(tokens)
  guard r is [{ kind: Symbol("=>") }, .. r] else {
    raise ParseError("Expected '=>'")
  }
  let (body, r2) = parse_expr(r)
  (MatchArm::{ pattern, body }, r2)
}

///|
pub fn parse_arm_pattern(
  tokens : ArrayView[Token],
) -> (ArmPattern, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Wildcard }, .. rest] => (ap(Wildcard), rest)
    [{ kind: Lower(name) }, .. rest] => (ap(Ident(name)), rest)
    [{ kind: Bool(v) }, .. rest] => (ap(Bool(v)), rest)
    [{ kind: Bracket('(') }, ..] as tks => parse_tuple_arm_pattern(tks)
    [{ kind: Upper(_) }, ..] as tks => parse_enum(tks)
    [{ kind: Int(n) }, .. rest] => (ap(Int(n)), rest)
    [{ kind: Double(n) }, .. rest] => (ap(Double(n)), rest)
    _ => raise ParseError("Invalid pattern: \{tokens[0].kind}")
  }
}

///|
pub fn parse_tuple_arm_pattern(
  tokens : ArrayView[Token],
) -> (ArmPattern, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Bracket('(') }, .. tokens]
  let items = Array::new()
  loop tokens {
    [{ kind: Bracket(')') }, .. rest] => break (ap(Tuple(items)), rest)
    [{ kind: Symbol(",") }, { kind: Symbol(",") }, ..] =>
      raise ParseError("Consecutive commas not allowed")
    [{ kind: Symbol(",") }, .. r] => continue r
    _ as cur => {
      let (e, r) = parse_arm_pattern(cur)
      items.push(e)
      continue r
    }
  }
}

///|
pub fn parse_enum(
  tokens : ArrayView[Token],
) -> (ArmPattern, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Upper(enum_name) }, .. rest]
  fn brak_rest(tokens : ArrayView[Token], name) raise ParseError {
    let ps = Array::new()
    loop tokens {
      [{ kind: Bracket(')') }, .. rest] =>
        break (ap(Enum(Some(enum_name), name, Some(ps))), rest)
      [{ kind: Symbol(",") }, .. rest] => continue rest
      _ as rest => {
        let (p, r) = parse_arm_pattern(rest)
        ps.push(p)
        continue r
      }
    }
  }

  match rest {
    [{ kind: Symbol("::") }, { kind: Upper(name) }, .. rest] =>
      match rest {
        [{ kind: Bracket('(') }, .. rest] => brak_rest(rest, name)
        _ => (ap(Enum(Some(enum_name), name, None)), rest)
      }
    _ =>
      match rest {
        [{ kind: Bracket('(') }, .. rest] => brak_rest(rest, enum_name)
        _ => (ap(Enum(None, enum_name, None)), rest)
      }
  }
}
