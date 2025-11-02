///|
pub fn typecheck(program : @parser.Program) -> Program raise TypeCheckError {
  let ctx = Context::new()
  let checked_program = ctx.check_program(program)
  ctx.substitute_type_var(checked_program)
}

///|
pub fn Context::substitute_type_var(
  self : Context,
  program : Program,
) -> Program raise TypeCheckError {
  let top_lets = Map::new()
  let top_functions = Map::new()
  program.top_lets.each((n, e) => top_lets.set(n, self.substitute_top_let(e)))
  program.top_functions.each((n, e) => top_functions.set(
    n,
    self.substitute_top_function(e),
  ))
  Program::{ top_lets, top_functions, struct_defs: program.struct_defs }
}
