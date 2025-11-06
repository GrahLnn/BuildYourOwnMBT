///|
pub(all) enum KnfLeftValue {
  Ident(Name)
  ArrayAcc(Name, Name)
  FieldAcc(Name, String)
} derive(Show)

///|
fn assign_binop(op : @typecheck.AssignOp) -> BinaryOp? {
  match op {
    PlusAssign => Some(Add)
    MinusAssign => Some(Sub)
    MultAssign => Some(Mul)
    DivAssign => Some(Div)
    ModAssign => Some(Mod)
    _ => None
  }
}

///|
/// 把 KnfLeftValue 物化为一个 Name, 需要时插入 Let
fn Context::materialize_left_value(
  self : Context,
  left_value : KnfLeftValue,
  value_type : Type, // left_value 所代表值的类型
  stmts : Array[KnfStmt],
) -> (Array[KnfStmt], Name) {
  match left_value {
    Ident(var_name) => (stmts, var_name)
    ArrayAcc(array_name, index_name) => {
      let temp_name = self.add_temp(value_type)
      stmts.push(
        Let(temp_name, value_type, ArrayAccess(array_name, index_name)),
      )
      (stmts, temp_name)
    }
    FieldAcc(struct_name, field_name) => {
      let temp_name = self.add_temp(value_type)
      stmts.push(
        Let(temp_name, value_type, FieldAccess(struct_name, field_name)),
      )
      (stmts, temp_name)
    }
  }
}

///|
fn Context::left_value_to_knf(
  self : Context,
  typed_left_value : @typecheck.LeftValue,
) -> (Array[KnfStmt], KnfLeftValue) raise KnfTransformError {
  match typed_left_value.kind {
    Ident(var_name) => {
      let new_name = self.name_env
        .get(var_name)
        .unwrap_or_else(() => raise KnfTransformError(
          "knf variable '\{var_name}' not found",
        ))
      ([], Ident(new_name))
    }
    ArrayAccess(base_left_value, index_expr) => {
      // 先分解内层左值
      let (base_stmts, base_lv) = self.left_value_to_knf(base_left_value)

      // 把内层左值物化为 Name. 物化语句接到 base_stmts
      let array_type = self.type_to_knf(base_left_value.ty)
      let (base_stmts, array_name) = self.materialize_left_value(
        base_lv, array_type, base_stmts,
      )

      // 再处理当前层索引表达式
      let (index_stmts, index_expr_knf) = self.expr_to_knf(index_expr)
      let index_type = self.typekind_to_knf(index_expr.ty)
      let index_name = self.expr_to_knf_name(
        index_expr_knf, index_type, index_stmts,
      )

      // 顺序必须是 base_stmts 在前, 然后 index_stmts
      (base_stmts + index_stmts, ArrayAcc(array_name, index_name))
    }
    FieldAccess(base_left_value, field_name) => {
      let (base_stmts, base_lv) = self.left_value_to_knf(base_left_value)
      let struct_type = self.type_to_knf(base_left_value.ty)
      let (base_stmts, struct_name) = self.materialize_left_value(
        base_lv, struct_type, base_stmts,
      )
      (base_stmts, FieldAcc(struct_name, field_name))
    }
  }
}

///|
pub fn Context::assign_stmt_to_knf(
  self : Context,
  assign_stmt : @typecheck.AssignStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let (rhs_stmts, rhs_expr_knf) = self.expr_to_knf(assign_stmt.expr)
  let rhs_type = self.typekind_to_knf(assign_stmt.expr.ty)
  let (left_value_stmts, knf_left_value) = self.left_value_to_knf(
    assign_stmt.left_value,
  )
  let stmts = left_value_stmts + rhs_stmts
  match assign_stmt.op {
    Assign =>
      match knf_left_value {
        Ident(var_name) => stmts.push(Assign(var_name, rhs_expr_knf))
        ArrayAcc(array_name, index_name) =>
          stmts.push(ArrayPut(array_name, index_name, rhs_expr_knf))
        FieldAcc(struct_name, field_name) => {
          let rhs_temp_name = self.expr_to_knf_name(
            rhs_expr_knf, rhs_type, stmts,
          )
          stmts.push(StructFieldSet(struct_name, field_name, rhs_temp_name))
        }
      }
    _ =>
      match assign_binop(assign_stmt.op) {
        Some(binary_op) =>
          match knf_left_value {
            Ident(var_name) => {
              let rhs_temp_name = self.expr_to_knf_name(
                rhs_expr_knf, rhs_type, stmts,
              )
              let combined_temp_name = self.expr_to_knf_name(
                Binary(binary_op, var_name, rhs_temp_name),
                rhs_type,
                stmts,
              )
              stmts.push(Assign(var_name, Ident(combined_temp_name)))
            }
            ArrayAcc(array_name, index_name) => {
              let rhs_temp_name = self.expr_to_knf_name(
                rhs_expr_knf, rhs_type, stmts,
              )
              let combined_temp_name = self.expr_to_knf_name(
                Binary(binary_op, array_name, rhs_temp_name),
                rhs_type,
                stmts,
              )
              stmts.push(
                ArrayPut(array_name, index_name, Ident(combined_temp_name)),
              )
            }
            FieldAcc(struct_name, field_name) => {
              let lhs_ty = self.type_to_knf(assign_stmt.left_value.ty)
              let lhs_temp_name = self.expr_to_knf_name(
                FieldAccess(struct_name, field_name),
                lhs_ty,
                stmts,
              )
              let rhs_temp_name = self.expr_to_knf_name(
                rhs_expr_knf, rhs_type, stmts,
              )
              let combined_temp_name = self.expr_to_knf_name(
                Binary(binary_op, lhs_temp_name, rhs_temp_name),
                rhs_type,
                stmts,
              )
              let moved_name = self.expr_to_knf_name(
                Ident(combined_temp_name),
                lhs_ty,
                stmts,
                coe=true,
              )
              stmts.push(StructFieldSet(struct_name, field_name, moved_name))
            }
          }
        None => raise KnfTransformError("unsupported assignment operator")
      }
  }
  stmts
}
