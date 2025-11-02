/// ================================================================================
/// # 可变变量：解析 let mut 语句
///
/// 我们已经可以解析不可变的 `let` 绑定了。现在，我们来处理它的“兄弟”：
/// `let mut` 语句，它用于声明一个**可变变量**。
///
/// ## `let mut` 语句的 EBNF 范式
///
/// `let mut` 语句的结构与 `let` 非常相似，但有一个关键区别：
///
/// ```
/// let_mut_stmt ::= "let" "mut" ident (":" type)? "=" expr ";"
/// ```
///
/// **⚠️ 请务必注意：**
/// `let mut` 的左边只能是一个**单一的标识符（`ident`）**，而**不是**像 `let` 那样可以是复杂的模式（`pattern`）。
/// 这是 MiniMoonBit 的一个设计选择，意味着你不能写 `let mut (a, b) = ...` 这样的代码。
///
/// ## 🎯 你的任务：实现 `parse_let_mut_stmt`
///
/// 你的任务是在 `parser/let_mut_stmt.mbt` 中实现 `parse_let_mut_stmt` 函数。
///
/// 这个任务的流程与 `parse_let_stmt` 高度一致，你只需要：
/// 1.  匹配 `let mut` 这两个连续的关键字。
/// 2.  确保后面跟着的是一个 `Lower` 类型的 Token 作为标识符。
/// 3.  其余部分（可选的类型、`=`、表达式和 `;`）的解析与 `let` 语句完全相同。
///
/// 相信这对你来说已经非常简单了。加油！
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_let_mut_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "Let Mut Stmt Parsing Test" {
  let code =
    #|let mut x : Int = 42;
    #|let mut y = 100;
    #|let mut z : (Int, Double) = (1, 2.0);
  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_let_mut_stmt(tokens)
  assert_true(
    s.name is "x" &&
    s.ty is Some(ty) &&
    ty.kind is Int &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42),
  )
  let (s, tok_view) = parse_let_mut_stmt(tok_view)
  assert_true(
    s.name is "y" &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(100),
  )
  let (s, _) = parse_let_mut_stmt(tok_view)
  assert_true(
    s.name is "z" &&
    s.ty is Some(ty) &&
    ty.kind is Tuple(tys) &&
    tys is [ty1, ty2] &&
    ty1 is Int &&
    ty2 is Double &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Tuple(es) &&
    es is [e1, e2] &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Double(2.0),
  )
}
