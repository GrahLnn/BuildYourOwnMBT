///|
pub(all) struct KnfProgram {
  struct_defs : Map[String, KnfStructDef]
  top_lets : Map[String, KnfTopLet]
  functions : Map[String, KnfFunction]
}

///|
pub fn Context::program_to_knf(
  self : Context,
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let top_lets = Map::new()
  prog.top_lets.each((k, v) => top_lets.set(k, self.top_let_to_knf(v)))
  let struct_defs = Map::new()
  prog.struct_defs.each((k, v) => struct_defs.set(k, self.struct_def_to_knf(v)))
  let functions = Map::new()
  prog.top_functions.each((k, v) => functions.set(
    k,
    self.top_function_to_knf(v),
  ))
  KnfProgram::{ struct_defs, top_lets, functions }
}

///|
pub fn knf_transform(
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let context = Context::new()
  
  // 注册内置函数 - 这些函数在 LLVM codegen 中会被声明
  context.globals.set("print_int", Function([Int], Unit))
  context.globals.set("print_double", Function([Double], Unit))
  context.globals.set("print_bool", Function([Bool], Unit))
  context.globals.set("println", Function([String], Unit))
  
  context.program_to_knf(prog)
}

///|
pub impl Show for KnfProgram with output(self, logger) {
  for _, struct_def in self.struct_defs {
    logger.write_object(struct_def)
    logger.write_char('\n')
  }
  for _, top_let in self.top_lets {
    logger.write_object(top_let)
    logger.write_char('\n')
  }
  for _, func in self.functions {
    logger.write_object(func)
    logger.write_char('\n')
  }
}
