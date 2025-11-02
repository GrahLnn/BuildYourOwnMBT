/// ================================================================================
/// # 程序的顶层结构：解析顶层 let 绑定
///
/// 除了顶层函数，一个 MiniMoonBit 程序还可以包含顶层的 `let` 绑定，
/// 用于定义全局常量。
///
/// ## 顶层 `let` vs. 语句 `let`
///
/// 顶层 `let` 与我们在函数体内解析的 `let` 语句非常相似，但有一个核心区别：
///
/// **顶层 `let` 的左边只能是一个标识符，不能是复杂的模式。**
///
/// ## 顶层 `let` 的 EBNF 范式
///
/// ```
/// top_let ::= "let" ident (":" type)? "=" expr ";"
/// ```
///
/// ## 🎯 你的任务：实现 `parse_top_let`
///
/// 你的任务是在 `parser/top_let.mbt` 中实现 `parse_top_let` 函数。
///
/// 这个函数的逻辑与我们之前实现的 `parse_let_mut_stmt` 几乎一模一样，
/// 只是将 `let mut` 换成了 `let`。
///
/// 相信这个任务对你来说已经非常轻松了。
///
/// 加油！
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_top_let_test.mbt
/// ```
/// ================================================================================

///|
test "Top Let Parsing Test" {
  let code =
    #|let x: Int = 42;
    #|let y: Bool = true;
    #|let z: Array[Int] = [1, 2, 3];
  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_top_let(tokens)
  assert_true(
    s.name is "x" &&
    s.ty is Some(ty) &&
    ty.kind is Int &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42),
  )
  let (s, tok_view) = parse_top_let(tok_view)
  assert_true(
    s.name is "y" &&
    s.ty is Some(ty) &&
    ty.kind is Bool &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Bool(true),
  )
  let (s, _) = parse_top_let(tok_view)
  assert_true(
    s.name is "z" &&
    s.ty is Some(ty) &&
    ty.kind is Array(Int) &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Array([e1, e2, e3]) &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(2) &&
    e3.kind is ApplyExpr(a3) &&
    a3.kind is AtomExpr(atom3) &&
    atom3.kind is Int(3),
  )
}
