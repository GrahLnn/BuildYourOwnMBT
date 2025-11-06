///|
pub(all) enum KnfExpr {
  Unit
  Int(Int)
  Bool(Bool)
  Double(Double)
  String(String)
  Ident(Name)
  Not(Name)
  Neg(Name)
  Binary(BinaryOp, Name, Name)
  If(KnfExpr, KnfBlock, KnfBlock)
  Block(KnfBlock)
  Call(Name, Array[Name])
  ArrayAccess(Name, Name)
  FieldAccess(Name, String)
  TupleAccess(Name, Int)
  CreateStruct(String, Array[(String, Name)])
  ArrayLiteral(Type, Array[Name])
  ArrayMake(Name, Name)
  TupleLiteral(Array[Name])
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
pub fn binop_to_knf(binop : @typecheck.BinaryOp) -> BinaryOp {
  match binop {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Mod => Mod
    ShiftLeft => ShiftLeft
    ShiftRight => ShiftRight
    Eq => Eq
    NE => NE
    LT => LT
    GT => GT
    LE => LE
    GE => GE
    And => And
    Or => Or
    BitAnd => BitAnd
    BitOr => BitOr
  }
}

///|
pub fn Context::expr_to_knf(
  self : Context,
  expr : @typecheck.Expr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match expr.kind {
    ApplyExpr(apply_expr) => self.apply_expr_to_knf(apply_expr)
    NotExpr(e) => {
      let ty = self.typekind_to_knf(e.ty)
      let (stmts, expr) = self.expr_to_knf(e)
      let name = self.expr_to_knf_name(expr, ty, stmts, coe=true)
      (stmts, Not(name))
    }
    NegExpr(e) => {
      let ty = self.typekind_to_knf(e.ty)
      let (stmts, expr) = self.expr_to_knf(e)
      let name = self.expr_to_knf_name(expr, ty, stmts, coe=true)
      (stmts, Neg(name))
    }
    BinaryExpr(binop, lhs, rhs) => {
      let lty = self.typekind_to_knf(lhs.ty)
      let rty = self.typekind_to_knf(rhs.ty)
      let (lst, lex) = self.expr_to_knf(lhs)
      let (rs, re) = self.expr_to_knf(rhs)
      let lname = self.expr_to_knf_name(lex, lty, lst)
      let rname = self.expr_to_knf_name(re, rty, rs)
      (lst + rs, Binary(binop_to_knf(binop), lname, rname))
    }
    IfExpr(expr) => self.if_expr_to_knf(expr)
    BlockExpr(block) => ([], Block(self.block_expr_to_knf(block)))
  }
}

///|
fn Context::expr_to_knf_name(
  self : Context,
  expr : KnfExpr,
  ty : Type,
  stmts : Array[KnfStmt],
  coe? : Bool = false,
) -> Name {
  match expr {
    Ident(name) =>
      if coe {
        let name = self.add_temp(ty)
        stmts.push(Let(name, ty, expr))
        name
      } else {
        name
      }
    _ => {
      let name = self.add_temp(ty)
      stmts.push(Let(name, ty, expr))
      name
    }
  }
}

///|
pub fn KnfExpr::to_string(self : KnfExpr, ident? : Int = 0) -> String {
  match self {
    Unit => "()"
    Int(i) => i.to_string()
    Bool(b) => b.to_string()
    Double(d) => d.to_string()
    String(s) => "\"\{s}\""
    Ident(name) => name.to_string()
    Not(name) => "!\{name}"
    Neg(name) => "-\{name}"
    Binary(op, lhs, rhs) => "\{lhs} \{op} \{rhs}"
    Call(func_name, args) => {
      let args_strs = args.map(arg => arg.to_string()).join(", ")
      "\{func_name}(\{args_strs})"
    }
    ArrayAccess(array_name, index_name) => "\{array_name}[\{index_name}]"
    FieldAccess(struct_name, field_name) => "\{struct_name}.\{field_name}"
    TupleAccess(tuple_name, index) => "\{tuple_name}.\{index}"
    CreateStruct(struct_name, init_arr) => {
      let init_strs = init_arr.map(field => "\{field.0}: \{field.1}").join(", ")
      "\{struct_name}::{\{init_strs}}"
    }
    ArrayLiteral(ty, elem_names) => {
      let elems_strs = elem_names.map(elem => elem.to_string()).join(", ")
      "[\{elems_strs}]::Array[\{ty}]"
    }
    ArrayMake(size_name, init_name) => "array_make(\{size_name}, \{init_name})"
    TupleLiteral(elem_names) => {
      let elems_strs = elem_names.map(elem => elem.to_string()).join(", ")
      "(\{elems_strs})"
    }
    Block(block) => block.to_string(ident)
    If(cond, then_block, else_block) => {
      let cond_str = cond.to_string()
      let then_str : String = then_block.to_string(ident)
      if else_block.stmts.is_empty() {
        "if \{cond_str} \{then_str}"
      } else {
        let else_str : String = else_block.to_string(ident)
        "if \{cond_str} \{then_str} else \{else_str}"
      }
    }
  }
}

///|
pub impl Show for KnfExpr with output(self, logger) {
  logger.write_string(self.to_string(ident=0))
}
