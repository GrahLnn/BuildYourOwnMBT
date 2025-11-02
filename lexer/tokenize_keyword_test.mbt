/// ================================================================================
/// 恭喜你已经完成了Identifier的词法分析，现在我们来完成关键字的词法分析。
///
/// 其实非常简单，只需要在Identifier的基础上，增加对关键字的判断即可。
///
/// 当你获得第一个Identifier之后，先别急着把它变成Lower或者Upper返回，
/// 而是先检查它是不是关键字，如果是，就返回对应的Keyword
/// 否则再根据首字母大小写返回Lower或者Upper。
///
/// 如何判断一个字符串是不是关键字呢？
///
/// 你可以使用match语法：
///
/// ```moonbit no test
/// let ident : String = ...
/// match ident {
///   "fn" => Fn
///   "let" => Let
///   ...
/// }
/// ```
///
/// 或者，你也可以声明一个map:
///
/// ```moonbit no test
/// let keywords : Map[String, Keyword] = {
///   "fn" : Fn,
///   "let" : Let,
///   ...
/// }
/// ```
///
/// 现在继续修改`lexer/lexer.mbt`文件，完成`tokenze`函数吧。
///
/// 在你实现完成后，可以使用moon test命令来运行所有测试：
///
/// 或者用下面的命令来单独运行当前测试：
///
/// ```
/// moon test -p lexer -f tokenize_keyword_test.mbt
/// ```
///
/// 祝你成功！🚀
/// ================================================================================

///|
test "Tokenize Keyword" {
  let code =
    #|fn let mut if else struct return _
  let tokens = tokenize(code)
  assert_true(tokens.length() is 9)
  assert_true(tokens[0].kind is Keyword(Fn))
  assert_true(tokens[1].kind is Keyword(Let))
  assert_true(tokens[2].kind is Keyword(Mut))
  assert_true(tokens[3].kind is Keyword(If))
  assert_true(tokens[4].kind is Keyword(Else))
  assert_true(tokens[5].kind is Keyword(Struct))
  assert_true(tokens[6].kind is Keyword(Return))
  assert_true(tokens[7].kind is Wildcard)
  assert_true(tokens[8].kind is EOF)
}
