///|
///
/// 注意这里的expr_codegen的返回值是Option[&@llvm.Value]
/// 对于Unit类型的表达式，应当返回None做特殊处理。
///
/// 对于像let a: Unit = (); 这种表达式，可以考虑把a的值设为null指针，
/// 使用llvm_ctx.getConstPointerNull(llvm_ctx.getPtrTy())
pub fn Context::expr_codegen(
  self : Self,
  expr : @knf.KnfExpr,
) -> &@llvm.Value? raise {
  match expr {
    Int(i) => (self.llvm_ctx.getConstInt32(i) : &@llvm.Value) |> Some
    Double(d) => self.llvm_ctx.getConstDouble(d) |> Some
    Bool(b) =>
      if b {
        self.llvm_ctx.getConstTrue() |> Some
      } else {
        self.llvm_ctx.getConstFalse() |> Some
      }
    String(s) => {
      let name = "str_lit_" + self.str_cnt.to_string()
      self.str_cnt += 1
      // 返回的是指向全局只读字符串的 ptr 值. 与函数返回类型的 ptr 匹配
      self.builder.createGlobalString(s, name~) |> Some
    }
    Unit => None
    Ident(name) => {
      let value = self.name_values.get(name)
      guard value is Some(value) else { return None }
      if value.asValueEnum() is AllocaInst(ptr) {
        Some(
          self.builder.createLoad(
            self.type_codegen_opaque(self.name_types.get(name).unwrap()),
            ptr,
          ),
        )
      } else {
        Some(value)
      }
    }
    Binary(op, lname, rname) => {
      let lv_raw = self.name_values.get(lname).unwrap()
      let rv_raw = self.name_values.get(rname).unwrap()
      // 如果是 AllocaInst（可变变量），需要先 load
      let lv = if lv_raw.asValueEnum() is AllocaInst(ptr) {
        self.builder.createLoad(
          self.type_codegen_opaque(self.name_types.get(lname).unwrap()),
          ptr,
        )
      } else {
        lv_raw
      }
      let rv = if rv_raw.asValueEnum() is AllocaInst(ptr) {
        self.builder.createLoad(
          self.type_codegen_opaque(self.name_types.get(rname).unwrap()),
          ptr,
        )
      } else {
        rv_raw
      }
      let is_float = lv.getType().isIEEELikeFPTy()
      let r = match op {
        Add =>
          if is_float {
            self.builder.createFAdd(lv, rv)
          } else {
            self.builder.createAdd(lv, rv)
          }
        Sub =>
          if is_float {
            self.builder.createFSub(lv, rv)
          } else {
            self.builder.createSub(lv, rv)
          }
        Mul =>
          if is_float {
            self.builder.createFMul(lv, rv)
          } else {
            self.builder.createMul(lv, rv)
          }
        Div =>
          if is_float {
            self.builder.createFDiv(lv, rv)
          } else {
            self.builder.createSDiv(lv, rv)
          }
        Mod =>
          if is_float {
            self.builder.createFRem(lv, rv)
          } else {
            self.builder.createSRem(lv, rv)
          }
        Eq =>
          if is_float {
            self.builder.createFCmpOEQ(lv, rv)
          } else {
            self.builder.createICmpEQ(lv, rv)
          }
        NE =>
          if is_float {
            self.builder.createFCmpONE(lv, rv)
          } else {
            self.builder.createICmpNE(lv, rv)
          }
        LT =>
          if is_float {
            self.builder.createFCmpOLT(lv, rv)
          } else {
            self.builder.createICmpSLT(lv, rv)
          }
        GT =>
          if is_float {
            self.builder.createFCmpOGT(lv, rv)
          } else {
            self.builder.createICmpSGT(lv, rv)
          }
        LE =>
          if is_float {
            self.builder.createFCmpOLE(lv, rv)
          } else {
            self.builder.createICmpSLE(lv, rv)
          }
        GE =>
          if is_float {
            self.builder.createFCmpOGE(lv, rv)
          } else {
            self.builder.createICmpSGE(lv, rv)
          }
        _ =>
          raise CodegenError("Unsupported binary operation in codegen: \{op}")
      }
      r |> Some
    }
    Not(name) => {
      let value_raw = self.name_values.get(name).unwrap()
      let value = if value_raw.asValueEnum() is AllocaInst(ptr) {
        self.builder.createLoad(
          self.type_codegen_opaque(self.name_types.get(name).unwrap()),
          ptr,
        )
      } else {
        value_raw
      }
      self.builder.createXor(self.llvm_ctx.getConstTrue(), value) |> Some
    }
    Neg(name) => {
      let value_raw = self.name_values.get(name).unwrap()
      let value = if value_raw.asValueEnum() is AllocaInst(ptr) {
        self.builder.createLoad(
          self.type_codegen_opaque(self.name_types.get(name).unwrap()),
          ptr,
        )
      } else {
        value_raw
      }
      let is_float = value.getType().isIEEELikeFPTy()
      let zero = self.llvm_ctx.getConstInt32(0)
      if is_float {
        self.builder.createFNeg(value) |> Some
      } else {
        self.builder.createSub(zero, value) |> Some
      }
    }
    ArrayMake(size_name, init_name) => {
      let size = self.name_values.get(size_name).unwrap()
      let init = self.name_values.get(init_name).unwrap()
      let init_ty = self.name_types.get(init_name).unwrap()
      self.make_array(init_ty, size, init)
    }
    ArrayAccess(array_name, index_name) => {
      let array = self.name_values.get(array_name).unwrap()
      let index = self.name_values.get(index_name).unwrap()
      let arr_ty = self.name_types.get(array_name).unwrap()
      self.get_array(arr_ty, array, index)
    }
    ArrayLiteral(ty, names) => {
      let elem_ty = match ty {
        Array(t) => t
        _ => ty
      }
      let arr = self
        .make_array(
          elem_ty,
          self.llvm_ctx.getConstInt32(names.length()),
          self.default_value(elem_ty),
        )
        .unwrap()
      names.eachi((i, e) => self.put_array(
        ty,
        arr,
        self.llvm_ctx.getConstInt32(i),
        self.name_values.get(e).unwrap(),
      ))
      arr |> Some
    }
    Block(block) => self.block_codegen(block)
    If(cond, then_block, else_block) =>
      self.if_codegen(cond, then_block, else_block)
    CreateStruct(name, fields) => {
      let struct_ty = self.struct_types.get(name).unwrap()
      let layout = self.llvm_mod.getDataLayout().getTypeAllocSize(struct_ty)
      let struct_ptr = self.builder.createCall(
        self.builtin_funcs.get("moonbit_malloc").unwrap(),
        [self.llvm_ctx.getConstInt32(layout)],
      )
      fields.eachi((idx, field) => {
        let (_, knf_name) = field
        // 唯一 hint（或不传）
        let field_ptr = self.builder.createGEP(struct_ptr, struct_ty, [
          self.llvm_ctx.getConstInt32(0),
          self.llvm_ctx.getConstInt32(idx),
        ])
        let _ = self.builder.createStore(
          self.name_values.get(knf_name).unwrap(),
          field_ptr,
        )

      })
      struct_ptr |> Some
    }
    FieldAccess(struct_name, field_name) => {
      // 步骤 1: 获取结构体实例的指针 (例如变量 `p` 的指针)
      let struct_ptr = self.name_values
        .get(struct_name)
        .unwrap_or_else(() => raise CodegenError(
          "Unknown struct variable: \{struct_name}",
        ))

      // 步骤 2: 获取该变量的 KNF 类型，并从中提取出结构体的名称 (例如 "Point")
      let struct_knf_type = self.name_types
        .get(struct_name)
        .unwrap_or_else(() => raise CodegenError(
          "Type for variable \{struct_name} not found",
        ))
      let struct_type_name = match struct_knf_type {
        Struct(sname) => sname
        _ => raise CodegenError("Variable `\{struct_name}` is not a struct")
      }

      // 步骤 3: 使用提取出的类型名称去查找类型定义
      let knf_struct_def = self.knf_struct_types
        .get(struct_type_name)
        .unwrap_or_else(() => raise CodegenError(
          "KNF struct definition not found: \{struct_type_name}",
        ))
      let llvm_struct_ty = self.struct_types
        .get(struct_type_name)
        .unwrap_or_else(() => raise CodegenError(
          "LLVM struct type not found: \{struct_type_name}",
        ))

      // 步骤 4: 查找字段的数字索引
      let field_names = knf_struct_def.fields.map(f => f.0)
      let field_index = field_names
        .search(field_name)
        .unwrap_or_else(() => raise CodegenError(
          "Field `\{field_name}` not found in struct `\{struct_type_name}`",
        ))

      // 步骤 5: 使用 GEP 计算字段的地址
      let field_ptr = self.builder.createGEP(struct_ptr, llvm_struct_ty, [
        self.llvm_ctx.getConstInt32(0),
        self.llvm_ctx.getConstInt32(field_index),
      ])

      // 步骤 6: 从地址加载值
      let field_knf_type = knf_struct_def.fields[field_index].2
      let field_llvm_type = self.type_codegen_opaque(field_knf_type)
      let field_value = self.builder.createLoad(field_llvm_type, field_ptr)
      field_value |> Some
    }
    TupleLiteral(ts) => {
      // 1) 元素 LLVM 类型列表
      let elem_knf_tys = ts.map(n => self.name_types.get(n).unwrap())
      let elem_llvm_tys = elem_knf_tys.map(t => self.type_codegen_opaque(t))

      // 2) 匿名结构体类型作为元组承载
      let tuple_llvm_ty = self.llvm_ctx.getStructType(elem_llvm_tys)

      // 3) 按数据布局分配堆内存
      let layout = self.llvm_mod.getDataLayout().getTypeAllocSize(tuple_llvm_ty)
      let tuple_ptr = self.builder.createCall(
        self.builtin_funcs.get("moonbit_malloc").unwrap(),
        [self.llvm_ctx.getConstInt32(layout)],
      )

      // 4) 逐元素 GEP 并写入. 不命名临时 SSA
      ts.eachi((idx, n) => {
        let field_ptr = self.builder.createGEP(tuple_ptr, tuple_llvm_ty, [
          self.llvm_ctx.getConstInt32(0),
          self.llvm_ctx.getConstInt32(idx),
        ])
        let v = self.name_values.get(n).unwrap()
        // 如需强制匹配类型. 在此处按需插入整型截断/扩展或 bitcast
        let _ = self.builder.createStore(v, field_ptr)

      })
      tuple_ptr |> Some
    }
    TupleAccess(tuple_name, index) => {
      let tuple_ptr = self.name_values.get(tuple_name).unwrap()
      let tuple_knf_type = self.name_types.get(tuple_name).unwrap()
      guard tuple_knf_type is Tuple(elem_tys) else {
        raise CodegenError("TupleAccess on non-tuple type: \{tuple_knf_type}")
      }
      let elem_llvm_tys = elem_tys.map(t => self.type_codegen_opaque(t))
      let tuple_llvm_ty = self.llvm_ctx.getStructType(elem_llvm_tys)
      let elem_ptr = self.builder.createGEP(tuple_ptr, tuple_llvm_ty, [
        self.llvm_ctx.getConstInt32(0),
        self.llvm_ctx.getConstInt32(index),
      ])
      let elem_llvm_ty = elem_llvm_tys[index]
      self.builder.createLoad(elem_llvm_ty, elem_ptr) |> Some
    }
    Call(func_name, args) => {
      // 先检查是否是局部变量(函数指针)
      let arg_values : Array[&@llvm.Value] = Array::new()
      let func : @either.Either[@llvm.Function, &@llvm.Value] = match
        self.name_values.get(func_name) {
        Some(func_ptr) => {
          // 局部变量(函数指针),需要添加环境指针
          arg_values.push(
            self.llvm_ctx.getConstPointerNull(self.llvm_ctx.getPtrTy()),
          )
          Right(func_ptr)
        }
        None => {
          let func = match self.builtin_funcs.get(func_name.to_string()) {
            Some(builtin) => builtin
            None => {
              // 用户定义函数,需要添加环境指针
              arg_values.push(
                self.llvm_ctx.getConstPointerNull(self.llvm_ctx.getPtrTy()),
              )
              self.functions.get(func_name.to_string()).unwrap()
            }
          }
          Left(func)
        }
      }
      args.each(n => {
        let arg_val = match self.name_values.get(n) {
          Some(value_raw) =>
            // 找到了，走原来的逻辑（如果是指针就加载）
            if value_raw.asValueEnum() is AllocaInst(ptr) {
              self.builder.createLoad(
                self.type_codegen_opaque(self.name_types.get(n).unwrap()),
                ptr,
              )
            } else {
              value_raw
            }
          None =>
            // 2. 在局部变量中没找到，尝试在全局函数中查找
            match self.functions.get(n.to_string()) {
              Some(func_val) =>
                // 找到了！直接返回这个 llvm::Function 对象。
                // 它本身就是一个 &@llvm.Value，可以被当作函数指针传递。
                func_val
              None =>
                // 3. 如果两处都找不到，那才是真正的错误
                raise CodegenError("Undefined identifier: \{n}")
            }
        }
        arg_values.push(arg_val)
      })
      match func {
        Left(func) => self.builder.createCall(func, arg_values) |> Some
        Right(func_ptr) => {
          // 函数指针需要获取函数类型
          let func_type = match self.name_types.get(func_name) {
            Some(@knf.Function(param_tys, ret_ty)) => {
              let llvm_param_types = param_tys.map(pt => self.type_codegen_opaque(
                pt,
              ))
              // 添加环境指针参数类型
              let all_param_types : Array[&@llvm.Type] = [
                self.llvm_ctx.getPtrTy(),
              ]
              llvm_param_types.each(pt => all_param_types.push(pt))
              let llvm_ret_type = self.type_codegen_opaque(ret_ty)
              self.llvm_ctx.getFunctionType(llvm_ret_type, all_param_types)
            }
            _ =>
              raise CodegenError(
                "Cannot determine function type for \{func_name}",
              )
          }
          self.builder.createCallPtr(func_ptr, func_type, arg_values) |> Some
        }
      }
    }
  }
}

///|
fn Context::make_array(
  self : Self,
  ty : @knf.Type,
  size : &@llvm.Value,
  init : &@llvm.Value,
) -> &@llvm.Value? raise {
  match ty {
    Int =>
      self.builder.createCall(
        self.builtin_funcs.get("make_int_array").unwrap(),
        [size, init],
      )
      |> Some
    Double =>
      self.builder.createCall(
        self.builtin_funcs.get("make_double_array").unwrap(),
        [size, init],
      )
      |> Some
    Bool =>
      self.builder.createCall(
        self.builtin_funcs.get("make_bool_array").unwrap(),
        [size, init],
      )
      |> Some
    _ =>
      self.builder.createCall(
        self.builtin_funcs.get("make_ptr_array").unwrap(),
        [size, init],
      )
      |> Some
  }
}

///|
fn Context::get_array(
  self : Self,
  arr_ty : @knf.Type,
  array : &@llvm.Value,
  index : &@llvm.Value,
) -> &@llvm.Value? raise {
  let index_value = if index.asValueEnum() is AllocaInst(ptr) {
    self.builder.createLoad(self.llvm_ctx.getInt32Ty(), ptr)
  } else {
    index
  }
  match arr_ty {
    Array(ty) =>
      match ty {
        Int =>
          self.builder.createCall(
            self.builtin_funcs.get("array_int_get").unwrap(),
            [array, index_value],
          )
          |> Some
        Double =>
          self.builder.createCall(
            self.builtin_funcs.get("array_double_get").unwrap(),
            [array, index_value],
          )
          |> Some
        Bool =>
          self.builder.createCall(
            self.builtin_funcs.get("array_bool_get").unwrap(),
            [array, index_value],
          )
          |> Some
        _ =>
          self.builder.createCall(
            self.builtin_funcs.get("array_ptr_get").unwrap(),
            [array, index_value],
          )
          |> Some
      }
    _ =>
      raise CodegenError(
        "Unsupported array type in get array codegen: \{arr_ty}",
      )
  }
}

///|
fn Context::put_array(
  self : Self,
  arr_ty : @knf.Type,
  array : &@llvm.Value,
  index : &@llvm.Value,
  value : &@llvm.Value,
) -> Unit raise {
  let index_value = if index.asValueEnum() is AllocaInst(ptr) {
    self.builder.createLoad(self.llvm_ctx.getInt32Ty(), ptr)
  } else {
    index
  }
  match arr_ty {
    Array(ty) => {
      let value_actual = if value.asValueEnum() is AllocaInst(ptr) {
        self.builder.createLoad(self.type_codegen_opaque(ty), ptr)
      } else {
        value
      }
      match ty {
        Int => {
          let _ = self.builder.createCall(
            self.builtin_funcs.get("array_int_put").unwrap(),
            [array, index_value, value_actual],
          )

        }
        Double => {
          let _ = self.builder.createCall(
            self.builtin_funcs.get("array_double_put").unwrap(),
            [array, index_value, value_actual],
          )

        }
        Bool => {
          let _ = self.builder.createCall(
            self.builtin_funcs.get("array_bool_put").unwrap(),
            [array, index_value, value_actual],
          )

        }
        _ => {
          let _ = self.builder.createCall(
            self.builtin_funcs.get("array_ptr_put").unwrap(),
            [array, index_value, value_actual],
          )

        }
      }
    }
    _ =>
      raise CodegenError(
        "Unsupported array type in put array codegen: \{arr_ty}",
      )
  }
}

///|
pub fn Context::default_value(
  self : Context,
  ty : @knf.Type,
) -> &@llvm.Value raise {
  match ty {
    Unit => raise CodegenError("unit has no value")
    Int => (self.llvm_ctx.getConstInt32(0) : &@llvm.Value)
    Double => self.llvm_ctx.getConstDouble(0.0)
    Bool => self.llvm_ctx.getConstFalse()
    // 统一把聚合/函数/数组/字符串当作 ptr，在 opaque 下降解下合法
    _ => self.llvm_ctx.getConstPointerNull(self.llvm_ctx.getPtrTy())
  }
}
