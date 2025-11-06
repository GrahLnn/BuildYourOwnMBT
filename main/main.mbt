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
  try {
    @ArgParser.parse(spec, fn(file) { input_files.push(file) }, usage, args)
  } catch {
    @ArgParser.ErrorMsg(msg) => { println(msg); return }
    e => { println(e); abort("argument parsing failed") }
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
      let ast  = @parser.parse(toks)
      let tc   = @typecheck.Context::new()
      let _    = tc.check_program(ast)
      println("Type check passed")
      return
    } catch {
      e => { println(e); abort("typecheck failed") }
    }
  }

  // C. 编译模式 <input> -o <output>
  if output.val == "" {
    abort("missing -o <output>")
  }

  try {
    let src   = @fs.read_file_to_string(input)
    let toks  = @lexer.tokenize(src)
    let ast   = @parser.parse(toks)
    let tc    = @typecheck.Context::new()
    let typed = tc.check_program(ast)

    // D. 代码生成(与 minimoonbit.json 的 emit 匹配)
    let knf_prog = @knf.knf_transform(typed)
    let llvm_mod = @codegen.codegen(knf_prog)
    let ir_text = llvm_mod.to_string()

    @fs.write_string_to_file(output.val, ir_text)
    println("Compilation successful: \{output.val}")
  } catch {
    e => { println(e); abort("compilation failed") }
  }
}
