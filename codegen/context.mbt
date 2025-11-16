///|
pub(all) suberror CodegenError String derive(Show)

///|
pub struct Context {
  llvm_ctx : @llvm.Context
  llvm_mod : @llvm.Module
  builder : @llvm.IRBuilder
  mut str_cnt : Int
  mut bb_counter : Int // 基本块计数器,用于生成唯一的基本块标签
  struct_types : Map[String, @llvm.StructType]
  knf_struct_types : Map[String, @knf.KnfStructDef]
  functions : Map[String, @llvm.Function]
  global_lets : Map[@knf.Name, &@llvm.Value]
  global_lets_types : Map[@knf.Name, @knf.Type]
  // mut the follow two if neccessary
  name_values : Map[@knf.Name, &@llvm.Value]
  name_types : Map[@knf.Name, @knf.Type]
  builtin_funcs : Map[String, @llvm.Function]

  // 当前函数路径,用于闭包名称混淆
  mut current_func_path : String
}

///|
pub fn Context::new(mod_name : String) -> Context {
  let llvm_ctx = @llvm.Context::new()
  let llvm_mod = llvm_ctx.addModule(mod_name)
  let builder = llvm_ctx.createBuilder()
  let i32ty = llvm_ctx.getInt32Ty()
  let doublety = llvm_ctx.getDoubleTy()
  let boolty = llvm_ctx.getInt1Ty()
  let ptrty = llvm_ctx.getPtrTy()
  let voidty = llvm_ctx.getVoidTy()
  let moonbit_malloc_ty = try! llvm_ctx.getFunctionType(ptrty, [i32ty])
  let moonbit_malloc = try! llvm_mod.addFunction(
    moonbit_malloc_ty, "minimbt_malloc",
  )
  let print_int_ty = try! llvm_ctx.getFunctionType(llvm_ctx.getVoidTy(), [i32ty])
  let print_int = try! llvm_mod.addFunction(print_int_ty, "minimbt_print_int")
  let print_double_ty = try! llvm_ctx.getFunctionType(llvm_ctx.getVoidTy(), [
    doublety,
  ])
  let print_double = try! llvm_mod.addFunction(
    print_double_ty, "minimbt_print_double",
  )
  let print_bool_ty = try! llvm_ctx.getFunctionType(llvm_ctx.getVoidTy(), [
    boolty,
  ])
  let print_bool = try! llvm_mod.addFunction(
    print_bool_ty, "minimbt_print_bool",
  )
  let make_int_array_ty = try! llvm_ctx.getFunctionType(ptrty, [i32ty, i32ty])
  let make_double_array_ty = try! llvm_ctx.getFunctionType(ptrty, [
    i32ty, doublety,
  ])
  // let make_bool_array_ty = try! llvm_ctx.getFunctionType(ptrty, [i32ty, boolty])
  let make_ptr_array_ty = try! llvm_ctx.getFunctionType(ptrty, [i32ty, ptrty])
  let get_array_length_ty = try! llvm_ctx.getFunctionType(i32ty, [ptrty])
  let array_int_push_ty = try! llvm_ctx.getFunctionType(llvm_ctx.getVoidTy(), [
    ptrty, i32ty,
  ])
  let truncate_ty = try! llvm_ctx.getFunctionType(i32ty, [doublety])
  let int_of_float_ty = try! llvm_ctx.getFunctionType(i32ty, [doublety])
  let float_of_int_ty = try! llvm_ctx.getFunctionType(doublety, [i32ty])
  let floor_ty = try! llvm_ctx.getFunctionType(i32ty, [doublety])
  let abs_float_ty = try! llvm_ctx.getFunctionType(doublety, [doublety])
  let sqrt_ty = try! llvm_ctx.getFunctionType(doublety, [doublety])
  let sin_ty = try! llvm_ctx.getFunctionType(doublety, [doublety])
  let cos_ty = try! llvm_ctx.getFunctionType(doublety, [doublety])
  let atan_ty = try! llvm_ctx.getFunctionType(doublety, [doublety])
  let array_double_push_ty = try! llvm_ctx.getFunctionType(
    llvm_ctx.getVoidTy(),
    [ptrty, doublety],
  )
  let array_bool_push_ty = try! llvm_ctx.getFunctionType(llvm_ctx.getVoidTy(), [
    ptrty, boolty,
  ])
  let array_ptr_push_ty = try! llvm_ctx.getFunctionType(llvm_ctx.getVoidTy(), [
    ptrty, ptrty,
  ])
  // let array_int_get_ty = try! llvm_ctx.getFunctionType(i32ty, [ptrty, i32ty])
  // let array_double_get_ty = try! llvm_ctx.getFunctionType(doublety, [
  // ptrty, i32ty,
  // ])
  let array_bool_get_ty = try! llvm_ctx.getFunctionType(boolty, [ptrty, i32ty])
  // let array_ptr_get_ty = try! llvm_ctx.getFunctionType(ptrty, [ptrty, i32ty])
  // let array_int_put_ty = try! llvm_ctx.getFunctionType(voidty, [
  //   ptrty, i32ty, i32ty,
  // ])
  let array_double_put_ty = try! llvm_ctx.getFunctionType(voidty, [
    ptrty, i32ty, doublety,
  ])
  let array_bool_put_ty = try! llvm_ctx.getFunctionType(voidty, [
    ptrty, i32ty, boolty,
  ])
  // let array_ptr_put_ty = try! llvm_ctx.getFunctionType(voidty, [
  //   ptrty, i32ty, ptrty,
  // ])
  let make_int_array = try! llvm_mod.addFunction(
    make_int_array_ty, "minimbt_create_array",
  )
  let make_double_array = try! llvm_mod.addFunction(
    make_double_array_ty, "minimbt_create_float_array",
  )
  let make_ptr_array = try! llvm_mod.addFunction(
    make_ptr_array_ty, "minimbt_create_ptr_array",
  )
  let minimbt_truncate = try! llvm_mod.addFunction(
    truncate_ty, "minimbt_truncate",
  )
  let minimbt_int_of_float = try! llvm_mod.addFunction(
    int_of_float_ty, "minimbt_int_of_float",
  )
  let minimbt_float_of_int = try! llvm_mod.addFunction(
    float_of_int_ty, "minimbt_float_of_int",
  )
  let minimbt_floor = try! llvm_mod.addFunction(floor_ty, "minimbt_floor")
  let minimbt_abs_float = try! llvm_mod.addFunction(
    abs_float_ty, "minimbt_abs_float",
  )
  let minimbt_sqrt = try! llvm_mod.addFunction(sqrt_ty, "minimbt_sqrt")
  let minimbt_sin = try! llvm_mod.addFunction(sin_ty, "minimbt_sin")
  let minimbt_cos = try! llvm_mod.addFunction(cos_ty, "minimbt_cos")
  let minimbt_atan = try! llvm_mod.addFunction(atan_ty, "minimbt_atan")
  let get_array_length = try! llvm_mod.addFunction(
    get_array_length_ty, "get_array_length",
  )
  let array_int_push = try! llvm_mod.addFunction(
    array_int_push_ty, "array_int_push",
  )
  let array_double_push = try! llvm_mod.addFunction(
    array_double_push_ty, "array_double_push",
  )
  let array_bool_push = try! llvm_mod.addFunction(
    array_bool_push_ty, "array_bool_push",
  )
  let array_ptr_push = try! llvm_mod.addFunction(
    array_ptr_push_ty, "array_ptr_push",
  )
  // let array_int_get = try! llvm_mod.addFunction(
  //     array_int_get_ty, "array_int_get",
  //   )
  // let array_double_get = try! llvm_mod.addFunction(
  //     array_double_get_ty, "array_double_get",
  //   )
  let array_bool_get = try! llvm_mod.addFunction(
    array_bool_get_ty, "array_bool_get",
  )
  // let array_ptr_get = try! llvm_mod.addFunction(
  //     array_ptr_get_ty, "array_ptr_get",
  //   )
  // let array_int_put = try! llvm_mod.addFunction(
  //     array_int_put_ty, "array_int_put",
  //   )
  let array_double_put = try! llvm_mod.addFunction(
    array_double_put_ty, "array_double_put",
  )
  let array_bool_put = try! llvm_mod.addFunction(
    array_bool_put_ty, "array_bool_put",
  )
  // let array_ptr_put = try! llvm_mod.addFunction(
  //     array_ptr_put_ty, "array_ptr_put",
  //   )
  let builtin_funcs = {
    "moonbit_malloc": moonbit_malloc,
    "print_int": print_int,
    "print_double": print_double,
    "print_bool": print_bool,
    "make_int_array": make_int_array,
    "make_float_array": make_double_array,
    "make_ptr_array": make_ptr_array,
    "get_array_length": get_array_length,
    "truncate": minimbt_truncate,
    "int_of_float": minimbt_int_of_float,
    "float_of_int": minimbt_float_of_int,
    "floor": minimbt_floor,
    "abs_float": minimbt_abs_float,
    "sqrt": minimbt_sqrt,
    "sin": minimbt_sin,
    "cos": minimbt_cos,
    "atan": minimbt_atan,
    "array_int_push": array_int_push,
    "array_double_push": array_double_push,
    "array_bool_push": array_bool_push,
    "array_ptr_push": array_ptr_push,
    // "array_int_get": array_int_get,
    // "array_double_get": array_double_get,
    "array_bool_get": array_bool_get,
    // "array_ptr_get": array_ptr_get,
    // "array_int_put": array_int_put,
    "array_double_put": array_double_put,
    "array_bool_put": array_bool_put,
    // "array_ptr_put": array_ptr_put,
  }
  let ctx = Context::{
    llvm_ctx,
    llvm_mod,
    builder,
    str_cnt: 0,
    bb_counter: 0,
    struct_types: Map::new(),
    knf_struct_types: Map::new(),
    functions: Map::new(),
    global_lets: Map::new(),
    global_lets_types: Map::new(),
    name_values: Map::new(),
    name_types: Map::new(),
    builtin_funcs,
    current_func_path: "",
  }
  ctx.str_cnt += 1
  ctx
}
