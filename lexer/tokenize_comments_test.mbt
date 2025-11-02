/// ================================================================================
/// 恭喜你已经完成了Identifier和Keyword的词法分析，现在我们来实现一下注释的跳过。
/// 
/// 通常来说，一个合格的编程语言都支持注释，用来给代码添加说明和文档。
///
/// 我们只需要实现一种注释形式：单行注释，使用 `//` 开头，直到行尾结束。
///
/// 当词法分析器遇到 `//` 时，它应该忽略该行剩余的所有内容，直到遇到换行符或文件结尾。
/// 这样，注释就不会被转换为 Token，从而不会影响后续的语法分析和编译过程。
///
/// 现在继续修改`lexer/lexer.mbt`文件，完成`tokenize`函数吧。
///
/// 在你实现完成后，可以使用moon test命令来运行所有测试：
///
/// 或者用下面的命令来单独运行当前测试：
///
/// ```
/// moon test -p lexer -f tokenize_comments_test.mbt
/// ```
///
/// 祝你成功！🚀
/// ================================================================================

///|
test "Skip Comments" {
  let code =
    #|fnx fn letp mut  // First line
    #|if else struct // Second line
    #|while return    // Third line
  let tokens = tokenize(code)
  assert_true(tokens.length() is 10)
  assert_true(tokens[0].kind is Lower("fnx"))
  assert_true(tokens[1].kind is Keyword(Fn))
  assert_true(tokens[2].kind is Lower("letp"))
  assert_true(tokens[3].kind is Keyword(Mut))
  assert_true(tokens[4].kind is Keyword(If))
  assert_true(tokens[5].kind is Keyword(Else))
  assert_true(tokens[6].kind is Keyword(Struct))
  assert_true(tokens[7].kind is Keyword(While))
  assert_true(tokens[8].kind is Keyword(Return))
  assert_true(tokens[9].kind is EOF)
}
