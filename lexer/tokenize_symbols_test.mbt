/// ================================================================================
/// 恭喜你完成了Identifier 和Keyword的词法分析，现在我们来完成符号的词法分析。
///
/// 在Moonbit中，我们会有多种符号：
///
/// - 括号：`()`, `[]`, `{}`
/// - 点号：`.`
/// - 逗号：`,`
/// - 冒号：`:`
/// - 分号：`;`
/// - 双冒号：`::`
/// - 箭头：`->`, `=>`
///
/// lexer.mbt中，已经为你定义好了这些符号对应的Token类型。
///
/// 你需要在tokenize函数中，增加对这些符号的识别。
///
/// ## Tips
///
/// 你可以使用pattern match来检测一个StringView的开头是否是某种符号，但请注意顺序：
///
/// ```moonbit no test
/// let sv : StringView = ...
/// match sv {
///   [.."->", ..] => // 以"->"开头
///   [.."=>", ..] => // 以"=>"开头
///   ['-', ..] => // 以'-'开头，但不以"->"开头
///   ...
/// }
/// ```
///
/// 现在继续修改`lexer/lexer.mbt`文件，完成`tokenize`函数吧。
///
/// 在你实现完成后，可以使用moon test命令来运行所有测试：
///
/// 或者用下面的命令来单独运行当前测试：
///
/// ```
/// moon test -p lexer -f tokenize_symbols_test.mbt
/// ```
///
/// 祝你成功！🚀
/// ================================================================================

///|
test "Tokenize Symbols" {
  let code =
    #|( ) [ ] { } . , : ; -> => ! _ ::
  let tokens = tokenize(code)
  assert_true(tokens.length() is 16)
  assert_true(tokens[0].kind is Bracket('('))
  assert_true(tokens[1].kind is Bracket(')'))
  assert_true(tokens[2].kind is Bracket('['))
  assert_true(tokens[3].kind is Bracket(']'))
  assert_true(tokens[4].kind is Bracket('{'))
  assert_true(tokens[5].kind is Bracket('}'))
  assert_true(tokens[6].kind is Symbol("."))
  assert_true(tokens[7].kind is Symbol(","))
  assert_true(tokens[8].kind is Symbol(":"))
  assert_true(tokens[9].kind is Symbol(";"))
  assert_true(tokens[10].kind is Symbol("->"))
  assert_true(tokens[11].kind is Symbol("=>"))
  assert_true(tokens[12].kind is Not)
  assert_true(tokens[13].kind is Wildcard)
  assert_true(tokens[14].kind is Symbol("::"))
  assert_true(tokens[15].kind is EOF)
}
