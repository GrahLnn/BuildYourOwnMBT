/// ================================================================================
/// 恭喜你完成了Symbols的词法分析器，现在我们来完成操作符的词法分析。
///
/// 在Moonbit中，我们会有多种操作符：
///
/// - 基础运算操作符：`+`, `-`, `*`, `/`, `%`
/// - 比较操作符：`==`, `!=`, `<`, `>`, `<=`, `>=`
/// - 逻辑操作符：`&&`, `||`
/// - 位运算操作符：`&`, `|`, `<<`, `>>`
/// - 赋值操作符：`=`, `+=`, `-=`, `*=`, `/=`, `%=`
///
/// 实现原理与Symbols类似，但需要归类这些操作符到不同的Token类型中。
///
/// 现在继续修改`lexer/lexer.mbt`文件，完成`tokenize`函数吧。
///
/// 在你实现完成后，可以使用moon test命令来运行所有测试：
///
/// 或者用下面的命令来单独运行当前测试：
///
/// ```
/// moon test -p lexer -f tokenize_operator_test.mbt
/// ```
///
/// 祝你成功！🚀
/// ================================================================================

///|
test "Tokenize Binary Operators" {
  let code =
    #|+ - * / % == != < > <= >= && || & | << >> !
  let tokens = tokenize(code)
  assert_true(tokens.length() is 19)
  assert_true(tokens[0].kind is BinaryOp(Add))
  assert_true(tokens[1].kind is BinaryOp(Sub))
  assert_true(tokens[2].kind is BinaryOp(Mul))
  assert_true(tokens[3].kind is BinaryOp(Div))
  assert_true(tokens[4].kind is BinaryOp(Mod))
  assert_true(tokens[5].kind is BinaryOp(Eq))
  assert_true(tokens[6].kind is BinaryOp(NE))
  assert_true(tokens[7].kind is BinaryOp(LT))
  assert_true(tokens[8].kind is BinaryOp(GT))
  assert_true(tokens[9].kind is BinaryOp(LE))
  assert_true(tokens[10].kind is BinaryOp(GE))
  assert_true(tokens[11].kind is BinaryOp(And))
  assert_true(tokens[12].kind is BinaryOp(Or))
  assert_true(tokens[13].kind is BinaryOp(BitAnd))
  assert_true(tokens[14].kind is BinaryOp(BitOr))
  assert_true(tokens[15].kind is BinaryOp(ShiftLeft))
  assert_true(tokens[16].kind is BinaryOp(ShiftRight))
  assert_true(tokens[17].kind is Not)
  assert_true(tokens[18].kind is EOF)
}

///|
test "Tokenize Assignment Operators" {
  let code =
    #|= += -= *= /= %=
  let tokens = tokenize(code)
  assert_true(tokens.length() is 7)
  assert_true(tokens[0].kind is AssignOp(Assign))
  assert_true(tokens[1].kind is AssignOp(PlusAssign))
  assert_true(tokens[2].kind is AssignOp(MinusAssign))
  assert_true(tokens[3].kind is AssignOp(MultAssign))
  assert_true(tokens[4].kind is AssignOp(DivAssign))
  assert_true(tokens[5].kind is AssignOp(ModAssign))
  assert_true(tokens[6].kind is EOF)
}
