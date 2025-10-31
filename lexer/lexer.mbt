///|
pub(all) suberror TokenizeError String derive(Show)

///|
pub(all) enum Keyword {
  Fn
  Struct
  Let
  Mut
  If
  Else
  While
  For
  Return
} derive(Show, Eq)

///|
let keywords : Map[String, Keyword] = {
  "fn": Fn,
  "struct": Struct,
  "let": Let,
  "mut": Mut,
  "if": If,
  "else": Else,
  "while": While,
  "for": For,
  "return": Return,
}

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Eq)

///|
pub impl Show for BinaryOp with output(self, logger) {
  let s = match self {
    Add => "+"
    Sub => "-"
    Mul => "*"
    Div => "/"
    Mod => "%"
    ShiftLeft => "<<"
    ShiftRight => ">>"
    Eq => "=="
    NE => "!="
    LT => "<"
    GT => ">"
    LE => "<="
    GE => ">="
    And => "&&"
    Or => "||"
    BitAnd => "&"
    BitOr => "|"
  }
  logger.write_string(s)
}

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq, ToJson)

///|
pub struct Token {
  kind : TokenKind
  // other info
} derive(Show, Eq)

///|
pub fn Token::new(kind : TokenKind) -> Token {
  Token::{ kind, }
}

///|
pub(all) enum TokenKind {
  Bool(Bool) // true, false
  Int(Int) // 1, 42, -100
  Double(Double)
  String(String) // "hello", "world"
  Keyword(Keyword)
  Upper(String)
  Lower(String)
  BinaryOp(BinaryOp) // +, -, *, /, %, =, ==, !=, <, >, <=, >=, &&, ||
  AssignOp(AssignOp) // =, +=, -=, *=, /=, %=
  Not // !
  Bracket(Char) // (, ), [, ], {, }
  Symbol(String) // . , ; : :: -> => 
  Wildcard // _
  EOF
} derive(Show, Eq)

///|
fn lex_number(code : StringView) -> (TokenKind, StringView) raise TokenizeError {
  let digits = Array::new()
  let mut has_dot = false
  let mut rest = loop code {
    ['0'..='9' as c, .. r] => {
      digits.push(c)
      continue r
    }
    _ as r => break r
  }
  rest = match rest {
    ['.', .. dot_rest] => {
      has_dot = true
      digits.push('.')
      loop dot_rest {
        ['0'..='9' as c, .. rest_str] => {
          digits.push(c)
          continue rest_str
        }
        _ as rest_str => break rest_str
      }
    }
    _ => rest
  }
  let num_str = String::from_array(digits)
  let token = if has_dot {
    let n = @strconv.parse_double(num_str) catch {
      StrConvError(e) => raise TokenizeError(e)
    }
    Double(n)
  } else {
    let n = @strconv.parse_int(num_str) catch {
      StrConvError(e) => raise TokenizeError(e)
    }
    Int(n)
  }
  (token, rest)
}

///|
fn lex_string(code : StringView) -> (TokenKind, StringView) raise TokenizeError {
  guard code is ['"', .. code]
  let str = Array::new()
  let rest = loop code {
    ['"', .. rest_str] => break rest_str
    [.. "\\n", .. rest_str] => {
      str.push('\n')
      continue rest_str
    }
    [.. "\\\"", .. rest_str] => {
      str.push('"')
      continue rest_str
    }
    [.. "\\\\", .. rest_str] => {
      str.push('\\')
      continue rest_str
    }
    ['\n', ..] =>
      raise TokenizeError("Unterminated string literal, found newline")
    [c, .. rest_str] => {
      str.push(c)
      continue rest_str
    }
    [] => raise TokenizeError("Unterminated string literal")
  }
  let str = TokenKind::String(String::from_array(str))
  (str, rest)
}

///|
fn lex_identifier(
  code : StringView,
) -> (TokenKind, StringView) raise TokenizeError {
  fn process(code : StringView) -> (String, StringView) {
    let ident = Array::new()
    loop code {
      ['a'..='z' | 'A'..='Z' | '0'..='9' | '_' as c, .. rest_str] => {
        ident.push(c)
        continue rest_str
      }
      _ as rest_str => break (String::from_array(ident), rest_str)
    }
  }

  match code {
    ['A'..='Z', ..] as code => {
      let (ident, rest) = process(code)
      (Upper(ident), rest)
    }
    ['a'..='z' | '_', ..] as code => {
      let (ident, rest) = process(code)
      let tk = match ident {
        "_" => Wildcard
        _ =>
          match keywords.get(ident) {
            Some(kind) => Keyword(kind)
            None => Lower(ident)
          }
      }
      (tk, rest)
    }
    _ => raise TokenizeError("Invalid identifier")
  }
}

///|
fn next_line(code : StringView) -> StringView {
  loop code {
    ['\n', .. rest] => break rest
    [_, .. rest] => continue rest
    _ as rest => break rest
  }
}

///|
pub fn tokenize(code : String) -> Array[Token] raise TokenizeError {
  let tokens : Array[Token] = []
  fn op(pair : (TokenKind, StringView)) {
    let (tk, rest) = pair
    tokens.push(Token::new(tk))
    rest
  }

  fn done() {
    tokens.push(Token::new(EOF))
    tokens
  }

  loop code[:] {
    [] => break done()
    [.. "//", .. rest] => continue next_line(rest)
    [' ' | '\r' | '\t' | '\n', .. rest] => continue rest
    [.. "<<", .. rest] => continue op((BinaryOp(ShiftLeft), rest))
    [.. ">>", .. rest] => continue op((BinaryOp(ShiftRight), rest))
    [.. "==", .. rest] => continue op((BinaryOp(Eq), rest))
    [.. "!=", .. rest] => continue op((BinaryOp(NE), rest))
    [.. "<=", .. rest] => continue op((BinaryOp(LE), rest))
    [.. ">=", .. rest] => continue op((BinaryOp(GE), rest))
    [.. "&&", .. rest] => continue op((BinaryOp(And), rest))
    [.. "||", .. rest] => continue op((BinaryOp(Or), rest))
    [.. "+=", .. rest] => continue op((AssignOp(PlusAssign), rest))
    [.. "-=", .. rest] => continue op((AssignOp(MinusAssign), rest))
    [.. "*=", .. rest] => continue op((AssignOp(MultAssign), rest))
    [.. "/=", .. rest] => continue op((AssignOp(DivAssign), rest))
    [.. "%=", .. rest] => continue op((AssignOp(ModAssign), rest))
    [.. "::", .. rest] => continue op((Symbol("::"), rest))
    [.. "->", .. rest] => continue op((Symbol("->"), rest))
    [.. "=>", .. rest] => continue op((Symbol("=>"), rest))
    ['.', .. rest] => continue op((Symbol("."), rest))
    [',', .. rest] => continue op((Symbol(","), rest))
    [';', .. rest] => continue op((Symbol(";"), rest))
    [':', .. rest] => continue op((Symbol(":"), rest))
    ['+', .. rest] => continue op((BinaryOp(Add), rest))
    ['-', .. rest] => continue op((BinaryOp(Sub), rest))
    ['*', .. rest] => continue op((BinaryOp(Mul), rest))
    ['/', .. rest] => continue op((BinaryOp(Div), rest))
    ['%', .. rest] => continue op((BinaryOp(Mod), rest))
    ['=', .. rest] => continue op((AssignOp(Assign), rest))
    ['&', .. rest] => continue op((BinaryOp(BitAnd), rest))
    ['|', .. rest] => continue op((BinaryOp(BitOr), rest))
    ['<', .. rest] => continue op((BinaryOp(LT), rest))
    ['>', .. rest] => continue op((BinaryOp(GT), rest))
    ['{', .. rest] => continue op((Bracket('{'), rest))
    ['}', .. rest] => continue op((Bracket('}'), rest))
    ['[', .. rest] => continue op((Bracket('['), rest))
    [']', .. rest] => continue op((Bracket(']'), rest))
    ['(', .. rest] => continue op((Bracket('('), rest))
    [')', .. rest] => continue op((Bracket(')'), rest))
    ['!', .. rest] => continue op((Not, rest))
    [.. "true", .. rest] => continue op((Bool(true), rest))
    [.. "false", .. rest] => continue op((Bool(false), rest))
    ['0'..='9', ..] as code => continue op(lex_number(code))
    ['"', ..] as code => continue op(lex_string(code))
    ['a'..='z' | 'A'..='Z' | '_', ..] as code =>
      continue op(lex_identifier(code))
    _ => raise TokenizeError("Invalid token")
  }
}
