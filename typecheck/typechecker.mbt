///|
pub fn typecheck(program : @parser.Program) -> Program raise TypeCheckError {
  let ctx = Context::new()
  
  // 注册所有内置函数
  let builtins : Array[(String, TypeKind)] = [
    ("print_int", Function([Int], Unit)),
    ("print_double", Function([Double], Unit)),
    ("print_bool", Function([Bool], Unit)),
    ("println", Function([String], Unit)),
    ("moonbit_malloc", Function([Int], Any)),
    ("make_int_array", Function([Int, Int], Array(Int))),
    ("make_double_array", Function([Int, Double], Array(Double))),
    ("make_bool_array", Function([Int, Bool], Array(Bool))),
    ("make_ptr_array", Function([Int, Any], Array(Any))),
    ("get_array_length", Function([Array(Any)], Int)),
    ("array_int_push", Function([Array(Int), Int], Unit)),
    ("array_double_push", Function([Array(Double), Double], Unit)),
    ("array_bool_push", Function([Array(Bool), Bool], Unit)),
    ("array_ptr_push", Function([Array(Any), Any], Unit)),
    ("array_int_get", Function([Array(Int), Int], Int)),
    ("array_double_get", Function([Array(Double), Int], Double)),
    ("array_bool_get", Function([Array(Bool), Int], Bool)),
    ("array_ptr_get", Function([Array(Any), Int], Any)),
    ("array_int_put", Function([Array(Int), Int, Int], Unit)),
    ("array_double_put", Function([Array(Double), Int, Double], Unit)),
    ("array_bool_put", Function([Array(Bool), Int, Bool], Unit)),
    ("array_ptr_put", Function([Array(Any), Int, Any], Unit)),
  ]
  
  builtins.each(fn(item) {
    let (name, ty) = item
    ctx.type_env.set(name, Type::{ kind: ty, mutable: false })
    ctx.func_types.set(name, ty)
  })
  
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
