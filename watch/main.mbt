///|
let challenge_names = [
  // typecheck
  "tokenize_ident_test", "tokenize_keyword_test", "tokenize_comments_test", "tokenize_symbols_test",
  "tokenize_operator_test", "tokenize_integer_test", "tokenize_float_test", "tokenize_string_test",
  "tokenize_code_test",
  // parser
   "parse_simple_atom_expr_test", "parse_simple_apply_expr_test", "parse_simple_expr_test",
  "parse_simple_unary_expr_test", "parse_simple_binary_expr_test", "parse_paren_expr_test",
  "parse_array_make_test", "parse_array_expr_test", "parse_simple_array_access_expr_test",
  "parse_simple_call_expr_test", "parse_simple_field_access_expr_test", "parse_complex_apply_expr_test",
  "parse_type_test", "parse_pattern_test", "parse_let_stmt_test", "parse_let_mut_stmt_test",
  "parse_left_value_test", "parse_assign_stmt_test", "parse_simple_stmt_test", "parse_block_expr_test",
  "parse_if_expr_test", "parse_while_stmt_test", "parse_complex_expr_test", "parse_local_function_test",
  "parse_top_function_test", "parse_struct_def_test", "parse_struct_construct_test",
  "parse_top_let_test", "parse_program_test",
  // typecheck
   "typecheck_normal_type_test", "typecheck_struct_def_test", "typecheck_type_var_test",
  "typecheck_simple_atom_expr_test", "typecheck_simple_apply_expr_test", "typecheck_simple_expr_test",
  "typecheck_atom_expr_test", "typecheck_apply_expr_test", "typecheck_let_mut_stmt_test",
  "typecheck_top_let_test", "typecheck_let_stmt_test", "typecheck_assign_stmt_test",
  "typecheck_block_expr_test", "typecheck_expr_test", "typecheck_if_expr_test", "typecheck_while_stmt_test",
  "typecheck_local_func_test", "typecheck_struct_construct_test", "typecheck_top_func_test",
  "typecheck_program_test", "typechecker_test",
  // Knf
   "knf_type_trans_test", "knf_simple_atom_trans_test", "knf_simple_apply_trans_test",
  "knf_simple_expr_trans_test", "knf_atom_trans_test", "knf_apply_trans_test", "knf_expr_trans_test",
  "knf_let_mut_trans_test", "knf_let_stmt_trans_test", "knf_assign_stmt_trans_test",
  "knf_stmt_trans_test", "knf_block_expr_trans_test", "knf_if_expr_trans_test", "knf_while_stmt_trans_test",
  "knf_top_let_trans_test", "knf_struct_def_trans_test", "knf_top_func_trans_test",
  "knf_local_func_trans_test", "knf_program_trans_test",
  // Codegen
   "codegen_demo_func_test", "codegen_demo_struct_test", "codegen_empty_top_func_test",
  "codegen_simple_top_func_test", "codegen_simple_let_test", "codegen_binary_test",
  "codegen_unary_test", "codegen_assign_test", "codegen_array_make_test", "codegen_array_acc_and_put_test",
  "codegen_array_expr_test", "codegen_block_test", "codegen_if_expr_test", "codegen_struct_test",
  "codegen_tuple_test", "codegen_call_test", "codegen_program_test",
]

///|
struct Challenge {
  name : String
  dir : String
}

///|
async fn Challenge::mbt_existed(self : Self) -> Bool {
  @fs.exists("\{self.dir}/\{self.name}.mbt")
}

///|
async fn Challenge::extract(self : Self) -> Unit {
  let _ = @process.collect_output_merged("unzip", [
    "data.zip",
    "\{self.name}.mbt",
    "-d",
    self.dir,
  ])

}

///|
async fn Challenge::is_passed(self : Self) -> Bool {
  // check if self.dir/self.name.mbt exists
  if !self.mbt_existed() {
    return false
  }
  let (_, output) = @process.collect_output_merged("moon", [
    "test",
    "--verbose",
    "-p",
    self.dir,
    "-f",
    "\{self.name}.mbt",
  ])
  let output = output.text()
  let head = output.find("[moonbitlang/MiniMoonbit] test ")
  if head is None {
    return false
  }
  let head = head.unwrap()
  let output = output[head:]
  if !output.contains(self.name) {
    return false
  }
  let mut all_passed = true
  let mut slice = output[:]
  while slice.find(self.name) is Some(idx) {
    slice = output[idx:]
    let next_newline = slice.find("\n")
    if next_newline is None {
      break
    }
    let next_newline = next_newline.unwrap()
    let slice2 = slice[:next_newline]
    all_passed = all_passed && slice2.has_suffix("ok")
    break
  }
  all_passed
}

///|
async fn construct_challenges() -> Array[Challenge] {
  let challenges = Array::new()
  if !@fs.exists("data.zip") {
    println(
      "\x1b[31m❌ [致命错误] data.zip 文件未找到！请检查项目根目录。\x1b[0m",
    )
    return challenges
  }
  let (_, msg) = @process.collect_output_merged("unzip", ["-l", "data.zip"])
  let msg = msg.text()
  for name in challenge_names {
    let mbt_name = "\{name}.mbt"
    if !msg.contains(mbt_name) {
      println(
        "\x1b[31m❌ [致命错误] data.zip 中缺少挑战文件：\{mbt_name}！\x1b[0m",
      )
      return challenges
    }
  }
  for name in challenge_names {
    let dir = if name.has_prefix("tokenize") {
      "lexer"
    } else if name.has_prefix("parse") {
      "parser"
    } else if name.has_prefix("typecheck") {
      "typecheck"
    } else if name.has_prefix("knf") {
      "knf"
    } else if name.has_prefix("interp") {
      "interp"
    } else if name.has_prefix("codegen") {
      "codegen"
    } else {
      println("\x1b[31m❌ [配置错误] 未知挑战类型：\{name}\x1b[0m")
      panic()
    }
    challenges.push(Challenge::{ name, dir })
  }
  challenges
}

///|
async fn main {
  let challenges = construct_challenges()

  // find first not passed challenge
  println("\n\x1b[1m\x1b[34m🔍 正在检查挑战进度...\x1b[0m")
  // 黄色警告
  println(
    "\x1b[33m⚠️ 注意：如果长时间未退出，请检查你的代码是否存在潜在的无限循环。\x1b[0m",
  )
  let mut first_not_passed : Challenge? = None
  let mut challenge_idx = 0
  for i, challenge in challenges {
    if !challenge.is_passed() {
      first_not_passed = Some(challenge)
      challenge_idx = i
      break
    }
  }
  if first_not_passed is None {
    print_conguratulation()
    return
  }
  let first_not_passed = first_not_passed.unwrap()
  println(
    "\n\x1b[1m\x1b[34m🎯 当前需要攻克的挑战：\{first_not_passed.name}\x1b[0m",
  )
  if first_not_passed.mbt_existed() {
    println(
      "\x1b[31m💔 \{first_not_passed.name}.mbt \x1b[1m测试未通过。",
    )
    println(
      "\x1b[0m\x1b[33m 别灰心，在 \{first_not_passed.dir} 目录下修改代码，加油！\x1b[0m",
    )
    return
  }
  if first_not_passed.name == challenge_names[0] {
    print_start()
  }
  let challenge_view = challenges[challenge_idx:]
  for challenge in challenge_view {
    println(
      "\n\x1b[34m✨ 为你激活下一项挑战：\x1b[1m\{challenge.name}\x1b[0m",
    )
    println(
      "\x1b[34m(位于 \x1b[36m\{challenge.dir}/\{challenge.name}.mbt\x1b[0m\x1b[34m) ...\x1b[0m",
    )
    challenge.extract()
    if challenge.is_passed() {
      println(
        "\x1b[32m🎉 \x1b[1m\{challenge.name}\x1b[0m \x1b[32m也顺利通过了！干得漂亮！继续前进！\x1b[0m",
      )
      continue
    } else {
      let dir_name = challenge.dir
      println(
        "\n\x1b[1m\x1b[33m🚧 下一项挑战已就位！请前往 \x1b[36m\{dir_name}/\{challenge.name}.mbt。\x1b[0m",
      )
      println("\x1b[33m祝你成功！\x1b[0m")
      return
    }
  }
  print_conguratulation()
}

///|
fn print_start() -> Unit {
  // 粗体蓝色标题
  println(
    "\x1b[1m\x1b[34m========================================================\x1b[0m",
  )
  println("\x1b[1m\x1b[32m🚀 欢迎来到 MiniMoonBit 挑战！\x1b[0m")
  println(
    "在这里，你将逐步完成一系列挑战，最终实现一个简化版的 MoonBit 语言编译器。",
  )
  println(
    "每个挑战都包含一个测试文件（.mbt），你需要通过这些测试来验证你的实现。",
  )
  // 黄色提示
  println(
    "\x1b[33m💡 准备好了吗？运行 'moon run watch' 时，系统会提示你需要完成的第一个任务！\x1b[0m",
  )
  println(
    "\x1b[1m\x1b[34m========================================================\x1b[0m",
  )
}

///|
fn print_conguratulation() -> Unit {
  // 粗体绿色庆祝
  println(
    "\n\x1b[1m\x1b[32m========================================================\x1b[0m",
  )
  println(
    "\x1b[1m\x1b[32m🏆 恭喜！所有挑战均已通过！为你点赞！\x1b[0m",
  )
  println(
    "\x1b[33m✨ 下一步：你可以将你的 MiniMoonBit 项目整理，提交给 MGPIC 评测机，获得最终认证和丰厚奖励！\x1b[0m",
  )
  println(
    "也可以继续探索 MoonBit 语言的更多特性，尝试为你的编译器添加更多功能！",
  )
  println("祝你在编程的星辰大海中一切顺利！")
  println(
    "\x1b[1m\x1b[32m========================================================\x1b[0m",
  )
}
