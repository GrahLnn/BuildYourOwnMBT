///|
/// 确保输出文件的父目录存在
fn ensure_parent_dir(path : String) -> Unit {
  // 查找最后一个路径分隔符
  let mut last_sep = -1
  for i = 0; i < path.length(); i = i + 1 {
    let c = path[i]
    if c == '/' || c == '\\' {
      last_sep = i
    }
  }
  
  // 如果有父目录，确保它存在
  if last_sep > 0 {
    let parent : String = path.substring(start=0, end=last_sep)
    if not(@fs.path_exists(parent)) {
      try {
        @fs.create_dir(parent)
      } catch {
        _ => () // 忽略创建失败，可能已存在或无权限
      }
    }
  }
}

fn main {
  let cli_args = @sys.get_cli_args()

  // 命令行参数配置
  let typecheck_only : Ref[Bool] = @ref.new(false)
  let output : Ref[String] = @ref.new("")
  let input_files : Array[String] = []
  let spec : Array[(String, String, @ArgParser.Spec, String)] = [
    ("--typecheck", "", @ArgParser.Spec::Set(typecheck_only), "type check only"),
    ("-o", "--output", @ArgParser.Spec::Set_string(output), "output file"),
  ]
  let usage =
    #| MiniMoonbit Compiler
    #| usage: 
    #|   minimoonbit <input> -o <output>
    #|   minimoonbit <input> --typecheck
    #|

  // 解析命令行参数 (跳过 argv[0] 程序名)
  let args : Array[String] = []
  for i = 1; i < cli_args.length(); i = i + 1 {
    args.push(cli_args[i])
  }
  @ArgParser.parse(spec, fn(file) { input_files.push(file) }, usage, args) catch {
    @ArgParser.ErrorMsg(msg) => {
      println(msg)
      return
    }
    e => {
      println(e)
      abort("argument parsing failed")
    }
  }

  // 检查输入文件
  if input_files.is_empty() {
    abort("no input file")
  }
  let input = input_files[0]

  // B. --typecheck 模式
  if typecheck_only.val {
    try {
      let src = @fs.read_file_to_string(input)
      let toks = @lexer.tokenize(src)
      let ast = @parser.parse(toks)
      let _ = @typecheck.typecheck(ast)
      println("Type check passed")
      return
    } catch {
      e => {
        println(e)
        abort("typecheck failed")
      }
    }
  }

  // C. 编译模式 <input> -o <output>
  if output.val == "" {
    abort("missing -o <output>")
  }
  try {
    let src = @fs.read_file_to_string(input)
    let toks = @lexer.tokenize(src)
    let ast = @parser.parse(toks)
    let typed = @typecheck.typecheck(ast)
    let knf_prog = @knf.knf_transform(typed)
    let llvm_mod = @codegen.codegen(knf_prog)
    let ir_text = llvm_mod.to_string()
    
    // 确保输出目录存在
    ensure_parent_dir(output.val)
    @fs.write_string_to_file(output.val, ir_text)
  } catch {
    @lexer.TokenizeError(msg) => {
      println("Tokenize error: \{msg}")
      abort("tokenize failed")
    }
    @parser.ParseError(msg) => {
      println("Parse error: \{msg}")
      abort("parse failed")
    }
    @typecheck.TypeCheckError(msg) => {
      println("Type error: \{msg}")
      abort("type check failed")
    }
    e => {
      println("Error: \{e}")
      abort("compilation failed")
    }
  }
}
