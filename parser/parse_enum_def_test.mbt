test "Enum Def Parsing Test" {
  let code =
    #|enum Color {
    #|  Red;
    #|  Green;
    #|  Blue;
    #|}
  let tokens = @lexer.tokenize(code)
  let (enum_def, _) = parse_enum_def(tokens)
  assert_true(enum_def.name is "Color")
  assert_true(enum_def.variants.length() is 3)
  assert_true(enum_def.variants[0] is { name: "Red", .. })
  assert_true(enum_def.variants[1] is { name: "Green", .. })
  assert_true(enum_def.variants[2] is { name: "Blue", .. })
}
