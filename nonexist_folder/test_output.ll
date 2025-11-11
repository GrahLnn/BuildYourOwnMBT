;; ModuleID = 'main'
;; Source File = "main"

declare ptr @moonbit_malloc(i32)

declare void @print_int(i32)

declare void @print_double(double)

declare void @print_bool(i1)

declare ptr @make_int_array(i32, i32)

declare ptr @make_double_array(i32, double)

declare ptr @make_bool_array(i32, i1)

declare ptr @make_ptr_array(i32, ptr)

declare i32 @get_array_length(ptr)

declare void @array_int_push(ptr, i32)

declare void @array_double_push(ptr, double)

declare void @array_bool_push(ptr, i1)

declare void @array_ptr_push(ptr, ptr)

declare i32 @array_int_get(ptr, i32)

declare double @array_double_get(ptr, i32)

declare i1 @array_bool_get(ptr, i32)

declare ptr @array_ptr_get(ptr, i32)

declare void @array_int_put(ptr, i32, i32)

declare void @array_double_put(ptr, i32, double)

declare void @array_bool_put(ptr, i32, i1)

declare void @array_ptr_put(ptr, i32, ptr)

define i32 @ack(ptr %0, i32 %1, i32 %2) {
entry:
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %5, label %8

5:                                     ; preds = %entry
  %6 = add i32 %2, 1
  br label %11

8:                                     ; preds = %entry
  %9 = icmp eq i32 %2, 0
  br i1 %9, label %14, label %18

11:                                     ; preds = %5, %24
  %12 = phi i32 [ %6, %5 ], [ %25, %24 ]
  ret i32 %12

14:                                     ; preds = %8
  %15 = sub i32 %1, 1
  %16 = call i32 @ack(ptr null, i32 %15, i32 1)
  br label %24

18:                                     ; preds = %8
  %19 = sub i32 %1, 1
  %20 = sub i32 %2, 1
  %21 = call i32 @ack(ptr null, i32 %1, i32 %20)
  %22 = call i32 @ack(ptr null, i32 %19, i32 %21)
  br label %24

24:                                     ; preds = %14, %18
  %25 = phi i32 [ %16, %14 ], [ %22, %18 ]
  br label %11
}

define void @main() {
entry:
  %0 = call i32 @ack(ptr null, i32 3, i32 4)
  call void @print_int(i32 %0)
  ret void
}
