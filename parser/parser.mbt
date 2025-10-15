///|
pub(all) struct Program {
  top_lets : Map[String, TopLet]
  top_functions : Map[String, TopFunction]
  struct_defs : Map[String, StructDef]
} derive(Show)

///|
pub fn parse(tokens : Array[Token]) -> Program raise ParseError {
  let top_lets = Map::new()
  let top_functions = Map::new()
  let struct_defs = Map::new()
  loop tokens[:] {
    [{ kind: Keyword(Fn) }, ..] as tokens => {
      ...
      continue tokens[1:]
    }
    [{ kind: Keyword(Let) }, ..] as tokens => {
      ...
      continue tokens[1:]
    }
    [{ kind: Keyword(Struct) }, ..] as tokens => {
      ...
      continue tokens[1:]
    }
    [{ kind: EOF }, ..] => break
    [] => {
      panic()
    }
    tokens => raise ParseError("Unexpected token in top level: \{tokens[0]}")
  }
  let prog = Program::{ top_lets, top_functions, struct_defs }
  prog
}
