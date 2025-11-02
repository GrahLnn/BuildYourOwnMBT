/// ================================================================================
/// 恭喜你完成了Identifier, Keyword, Symbol, Operator
/// 的词法分析，现在我们来完成整数的词法分析。
///
/// 在Moonbit中，整数（Int）是由一串数字组成的，
/// 没有小数点，没有前缀或后缀，例如：`42`, `0`, `15899`。
///
/// 实现原理与Identifier类似，循环读取连续的数字字符，
/// 然后解析成整数。
///
/// MoonBit的标准库中，已经为你提供了将String转换成数字的工具: @strconv.parse_int
///
/// 例如：
///
/// ```moonbit no test
/// let s : String = "42"
/// let i : Int = @strconv.parse_int(s)
/// assert_eq(i, 42)
/// ```
///
/// 请查阅标准库文档https://mooncakes.io/docs/moonbitlang/core/strconv
///
/// 现在继续修改`lexer/lexer.mbt`文件，完成`tokenize`函数吧。
///
/// 在你实现完成后，可以使用moon test命令来运行所有测试：
///
/// 或者用下面的命令来单独运行当前测试：
///
/// ```
/// moon test -p lexer -f tokenize_integer_test.mbt
/// ```
///
/// 祝你成功！🚀
/// ================================================================================

///|
test "Tokenize Int Number" {
  let code =
    #|42 0 65 15899 65355 78451 00012
  let tokens = tokenize(code)
  assert_true(tokens.length() is 8)
  assert_true(tokens[0].kind is Int(42))
  assert_true(tokens[1].kind is Int(0))
  assert_true(tokens[2].kind is Int(65))
  assert_true(tokens[3].kind is Int(15899))
  assert_true(tokens[4].kind is Int(65355))
  assert_true(tokens[5].kind is Int(78451))
  assert_true(tokens[6].kind is Int(12))
  assert_true(tokens[7].kind is EOF)
}
