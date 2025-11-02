/// ================================================================================
/// # 终极挑战：解析二元表达式与运算符优先级
///
/// 欢迎来到 `Expr` 解析的终极挑战！我们即将要攻克的，是编译器中最经典、也最具挑战性的问题之一：
/// **带有优先级的二元表达式解析（Binary Expression Parsing with Precedence）**。
///
/// ⚠️ **高能预警：** 这部分内容的实现难度较高，其算法复杂度不亚于一道 LeetCode 的中等偏上难度的题目。
/// 请做好充分的心理准备，这将是一次绝佳的算法思维锻炼！
///
/// ## 🤔 挑战的核心：运算符优先级
///
/// 为什么这很难？思考一下表达式 `1 + 2 * 3`。
///
/// 我们人类知道应该先算 `2 * 3`，因为 `*` 的优先级高于 `+`。
/// 但我们的解析器是自左向右读取 Token 的。当它看到 `1 + 2` 时，它如何知道不能立刻将它们组合，
/// 而是要“等待”后面的 `*` 运算先完成呢？
///
/// 这就是我们需要解决的核心问题：实现一个能够理解并正确处理不同运算符优先级的解析算法。
///
/// ## 🎯 你的任务：在 `parse_expr` 中实现完整的二元表达式解析
///
/// 现在，请再次回到 `parser/expr.mbt`，准备对 `parse_expr` 函数进行一次“大手术”。
///
/// **💡 核心思路提示：双栈
///
/// 1.  **两个栈：** 你可以考虑使用两个栈：一个用于存放**待处理的运算符（Operator Stack）**，另一个用于存放**已经解析出的表达式（Expression Stack）**。
///
/// 2.  **处理流程：**
///     *   当你解析出一个 `ApplyExpr`（我们称之为一个操作数）时，将它压入表达式栈。
///     *   当你遇到一个运算符时，你需要将它与运算符栈顶的运算符进行**优先级比较**。
///         *   如果当前运算符的优先级**高于**栈顶运算符，说明它可以“抢先”执行，将它压入运算符栈。
///         *   如果当前运算符的优先级**低于或等于**栈顶运算符，说明栈顶的运算需要先进行。
///             此时，从运算符栈弹出一个运算符，从表达式栈弹出两个表达式，将它们组合成一个新的 `BinaryExpr`，
///             然后将结果压回表达式栈。重复此过程，直到当前运算符可以被压入栈中。
///
/// 3.  **收尾工作：** 当所有 Token 都处理完毕后，清空运算符栈中的所有剩余运算符，完成最后的组合。
///
/// 这只是一个高层次的思路概述。你需要仔细思考其中的细节，例如循环条件、栈的清空时机以及如何处理括号（尽管本测试暂不涉及）。
///
/// **precedence 函数：**
///
/// 为了帮助你，`parser/expr.mbt` 中已经为你提供了一个 `precedence(op: BinaryOp) -> Int` 的辅助函数，你可以直接使用它来获取运算符的优先级。
///
/// **阶段性测试：**
///
/// 完成这个艰巨的任务后，运行以下命令来检验你的成果：
///
/// ```bash
/// moon test -p parser -f parse_simple_binary_expr_test.mbt
/// ```
///
/// **祝你挑战成功！攻克了它，你对表达式解析的理解将达到一个新的高度！**
/// ================================================================================

///|
test "Binary Expr Parsing Test" {
  let code =
    #|1 + 2 * 3 ;
    #|4 * 5 - 6 / 2 ;
    #|a && b || c && d ;
    #|x << 2 + y >> 3 ;
    #|p > q != r < s
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = parse_expr(tokens[:])
  assert_true(
    e.kind is BinaryExpr(Add, left, right) &&
    left.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(1) &&
    right.kind is BinaryExpr(Mul, left, right) &&
    left.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(2) &&
    right.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(3),
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(Sub, left1, right1) &&
    left1.kind is BinaryExpr(Mul, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(4) &&
    right2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(5) &&
    right1.kind is BinaryExpr(Div, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(6) &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(2),
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(Or, left1, right1) &&
    left1.kind is BinaryExpr(And, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("a") &&
    right2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("b") &&
    right1.kind is BinaryExpr(And, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("c") &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("d"),
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(ShiftRight, left1, right1) &&
    left1.kind is BinaryExpr(ShiftLeft, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("x") &&
    right2.kind is BinaryExpr(Add, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(2) &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("y") &&
    right1.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(3),
  )
  let (e, _) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(NE, left1, right1) &&
    left1.kind is BinaryExpr(GT, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("p") &&
    right2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("q") &&
    right1.kind is BinaryExpr(LT, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("r") &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("s"),
  )
}
