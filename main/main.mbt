// 同步入口. 不依赖 async.
fn main {
  // A. 读取命令行
  let args = @sys.args()

  // B. --typecheck <input>
  if args.length() >= 3 && args[1] == "--typecheck" {
    let input = args[2]
    let src = @fs.read_file_to_string(~input)
    let toks = @lexer.tokenize(src)
    let ast  = @parser.parse(toks)
    let tc   = @typecheck.Context::new()
    let _    = tc.check_program(ast)
    return
  }

  // C. <input> -o <output>
  if args.length() < 4 { panic("usage: <input> -o <output>") }
  let input = args[1]
  let oidx  = args.search_by(a => a == "-o")
  let output = match oidx {
    Some(i) if i + 1 < args.length() => args[i + 1]
    _ => panic("missing -o <output>")
  }

  let src   = @fs.read_file_to_string!(~input)
  let toks  = @lexer.tokenize(src)
  let ast   = @parser.parse(toks)
  let tc    = @typecheck.Context::new()
  let typed = tc.check_program(ast)

  // D. 代码生成（与 minimoonbit.json 的 emit 匹配）
  let ir_text = @codegen.emit_llvm_ir(typed)   // 或改成 emit_riscv_asm

  @fs.write_string_to_file(path=output, content=ir_text)
}
