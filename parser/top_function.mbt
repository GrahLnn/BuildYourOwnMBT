///|
pub(all) struct Param {
  name : String
  ty : Type
} derive(Show, Eq)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : Type
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_params(
  tokens : ArrayView[Token],
) -> (Array[Param], ArrayView[Token]) raise ParseError {
  let items = Array::new()
  loop tokens {
    [{ kind: Bracket(')') }, .. rest] => (items, rest)
    [{ kind: Symbol(",") }, .. rest] => continue rest
    _ as rest =>
      match rest {
        [{ kind: Lower(name) }, { kind: Symbol(":") }, .. rest] => {
          let (ty, rest) = parse_type(rest)
          items.push(Param::{ name, ty })
          continue rest
        }
        _ => raise ParseError("Expect parameter and type")
      }
  }
}

///|
pub fn parse_top_function(
  tokens : ArrayView[Token],
) -> (TopFunction, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Fn) }, .. rest]
  let (fname, rest) = match rest {
    [{ kind: Lower(name) }, .. rest] => (name, rest)
    _ => raise ParseError("Expect string")
  }
  match fname {
    "main" => {
      let param_list = Array::new()
      let ret_ty = Type::{ kind: Unit }
      let (body, rest) = parse_block_expr(rest)
      (TopFunction::{ fname, param_list, ret_ty, body }, rest)
    }
    _ => {
      guard rest is [{ kind: Bracket('(') }, .. rest]
      let (param_list, rest) = parse_params(rest)
      let (ret_ty, rest) = match rest {
        [{ kind: Symbol("->") }, .. rest] => parse_type(rest)
        _ => raise ParseError("Expect return type")
      }
      let (body, rest) = parse_block_expr(rest)
      (TopFunction::{ fname, param_list, ret_ty, body }, rest)
    }
  }
}
