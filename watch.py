import asyncio
import subprocess
from pathlib import Path
from typing import List, Optional, Tuple
import re
import zipfile

# 相当于 MoonBit 的 challenge_names 数组
challenge_names: List[str] = [
    # typecheck
    "tokenize_ident_test",
    "tokenize_keyword_test",
    "tokenize_comments_test",
    "tokenize_symbols_test",
    "tokenize_operator_test",
    "tokenize_integer_test",
    "tokenize_float_test",
    "tokenize_string_test",
    "tokenize_code_test",
    # parser
    "parse_simple_atom_expr_test",
    "parse_simple_apply_expr_test",
    "parse_simple_expr_test",
    "parse_simple_unary_expr_test",
    "parse_simple_binary_expr_test",
    "parse_paren_expr_test",
    "parse_array_make_test",
    "parse_array_expr_test",
    "parse_simple_array_access_expr_test",
    "parse_simple_call_expr_test",
    "parse_simple_field_access_expr_test",
    "parse_complex_apply_expr_test",
    "parse_type_test",
    "parse_pattern_test",
    "parse_let_stmt_test",
    "parse_let_mut_stmt_test",
    "parse_left_value_test",
    "parse_assign_stmt_test",
    "parse_simple_stmt_test",
    "parse_block_expr_test",
    "parse_if_expr_test",
    "parse_while_stmt_test",
    "parse_complex_expr_test",
    "parse_local_function_test",
    "parse_top_function_test",
    "parse_struct_def_test",
    "parse_struct_construct_test",
    "parse_top_let_test",
    "parse_program_test",
    # typecheck
    "typecheck_normal_type_test",
    "typecheck_struct_def_test",
    "typecheck_type_var_test",
    "typecheck_simple_atom_expr_test",
    "typecheck_simple_apply_expr_test",
    "typecheck_simple_expr_test",
    "typecheck_atom_expr_test",
    "typecheck_apply_expr_test",
    "typecheck_let_mut_stmt_test",
    "typecheck_top_let_test",
    "typecheck_let_stmt_test",
    "typecheck_assign_stmt_test",
    "typecheck_block_expr_test",
    "typecheck_expr_test",
    "typecheck_if_expr_test",
    "typecheck_while_stmt_test",
    "typecheck_local_func_test",
    "typecheck_struct_construct_test",
    "typecheck_top_func_test",
    "typecheck_program_test",
    "typechecker_test",
    # Knf
    "knf_type_trans_test",
    "knf_simple_atom_trans_test",
    "knf_simple_apply_trans_test",
    "knf_simple_expr_trans_test",
    "knf_atom_trans_test",
    "knf_apply_trans_test",
    "knf_expr_trans_test",
    "knf_let_mut_trans_test",
    "knf_let_stmt_trans_test",
    "knf_assign_stmt_trans_test",
    "knf_stmt_trans_test",
    "knf_block_expr_trans_test",
    "knf_if_expr_trans_test",
    "knf_while_stmt_trans_test",
    "knf_top_let_trans_test",
    "knf_struct_def_trans_test",
    "knf_top_func_trans_test",
    "knf_local_func_trans_test",
    "knf_program_trans_test",
    # Codegen
    "codegen_demo_func_test",
    "codegen_demo_struct_test",
    "codegen_empty_top_func_test",
    "codegen_simple_top_func_test",
    "codegen_simple_let_test",
    "codegen_binary_test",
    "codegen_unary_test",
    "codegen_assign_test",
    "codegen_array_make_test",
    "codegen_array_acc_and_put_test",
    "codegen_array_expr_test",
    "codegen_block_test",
    "codegen_if_expr_test",
    "codegen_struct_test",
    "codegen_tuple_test",
    "codegen_call_test",
    "codegen_program_test",
]


class Challenge:
    """对应 MoonBit 的 struct Challenge"""

    def __init__(self, name: str, dir: str):
        self.name = name
        self.dir = dir

    def __repr__(self) -> str:
        return f"Challenge(name='{self.name}', dir='{self.dir}')"

    async def mbt_existed(self) -> bool:
        """检查 self.dir/self.name.mbt 是否存在"""
        return Path(self.dir, f"{self.name}.mbt").exists()

    async def extract(self) -> None:
        target = Path(self.dir, f"{self.name}.mbt")
        if target.exists():
            return
        target.parent.mkdir(parents=True, exist_ok=True)

        def _extract_one():
            data_zip = Path("data.zip")
            if not data_zip.exists():
                print(
                    "\x1b[31m❌ [致命错误] data.zip 文件未找到！请检查项目根目录。\x1b[0m"
                )
                return

            try:
                with zipfile.ZipFile(data_zip, "r") as zf:
                    # 优先精确匹配，其次后缀匹配（兼容 zip 内含目录的情况）
                    want = f"{self.name}.mbt"
                    names = zf.namelist()
                    cand = None
                    if want in names:
                        cand = want
                    else:
                        for n in names:
                            if n.endswith("/"):
                                continue
                            if Path(n).name == want:
                                cand = n
                                break
                    if cand is None:
                        print(
                            f"\x1b[31m❌ [致命错误] data.zip 中缺少文件：{want}！\x1b[0m"
                        )
                        return

                    # ZipSlip 防护：禁止把文件解到目标目录之外
                    out_path = target.resolve()
                    base_dir = target.parent.resolve()
                    if not str(out_path).startswith(str(base_dir)):
                        print("\x1b[31m❌ [安全错误] 目标路径异常，已拒绝写入。\x1b[0m")
                        return

                    # 不覆盖：如果并发写入导致此时已存在，则直接返回
                    if out_path.exists():
                        return

                    # 逐字节写入，避免 zip 中的目录结构污染
                    with zf.open(cand, "r") as src, open(out_path, "wb") as dst:
                        while True:
                            chunk = src.read(1024 * 1024)
                            if not chunk:
                                break
                            dst.write(chunk)

            except zipfile.BadZipFile:
                print("\x1b[31m❌ [致命错误] data.zip 已损坏或不是合法 ZIP！\x1b[0m")
            except Exception as e:
                print(f"\x1b[31m❌ [致命错误] 解压失败：{e}\x1b[0m")

        # 与原语义一致：在工作线程中执行阻塞 IO
        await asyncio.to_thread(_extract_one)

    async def check(self) -> Tuple[bool, List[str]]:
        """运行 moon test；返回 (是否全部通过, 失败用例列表[格式: '行号 "标题"'])"""
        if not await self.mbt_existed():
            return False, []

        def run_moon_test() -> Tuple[int, str]:
            try:
                r = subprocess.run(
                    [
                        "moon",
                        "test",
                        "--verbose",
                        "-p",
                        self.dir,
                        "-f",
                        f"{self.name}.mbt",
                    ],
                    capture_output=True,
                    text=True,
                    timeout=30,
                )
                return r.returncode, r.stdout + r.stderr
            except subprocess.TimeoutExpired:
                return 1, f"Error: moon test for {self.name} timed out."
            except FileNotFoundError:
                return (
                    1,
                    "Error: 'moon' command not found. Please ensure it is in your PATH.",
                )
            except Exception as e:
                return 1, f"Error running moon test: {e}"

        _, output = await asyncio.to_thread(run_moon_test)

        # 去 ANSI
        ansi_re = re.compile(r"\x1b\[[0-9;]*m")
        clean = ansi_re.sub("", output)

        # 捕获本 .mbt 的所有用例行与状态
        # 例: [moonbitlang/MiniMoonbit] test parser/parse_type_test.mbt:40 ("Complex Type Parsing") failed: ...
        pat = re.compile(
            rf'\[moonbitlang/MiniMoonbit\]\s+test\s+.*?/{re.escape(self.name)}\.mbt:(?P<line>\d+)\s*\("(?P<title>[^"]+)"\)\s*(?P<status>ok|failed:.*)',
            flags=re.MULTILINE,
        )

        matches = list(pat.finditer(clean))
        if not matches:
            return False, []

        fails: List[str] = []
        all_ok = True
        for m in matches:
            status = m.group("status")
            if not status.startswith("ok"):
                all_ok = False
                fails.append(f'{m.group("line")} "{m.group("title")}"')

        return all_ok, fails


def print_start() -> None:
    """打印开始信息"""
    print(
        "\n\x1b[1m\x1b[34m========================================================\x1b[0m",
    )
    print("\x1b[1m\x1b[32m🚀 欢迎来到 MiniMoonBit 挑战！\x1b[0m")
    print(
        "在这里，你将逐步完成一系列挑战，最终实现一个简化版的 MoonBit 语言编译器。",
    )
    print(
        "每个挑战都包含一个测试文件（.mbt），你需要通过这些测试来验证你的实现。",
    )
    # 黄色提示
    print(
        "\x1b[33m💡 准备好了吗？运行 'moon run watch' 时，系统会提示你需要完成的第一个任务！\x1b[0m",
    )
    print(
        "\x1b[1m\x1b[34m========================================================\x1b[0m",
    )


def print_conguratulation() -> None:
    """打印祝贺信息"""
    print(
        "\n\x1b[1m\x1b[32m========================================================\x1b[0m",
    )
    print(
        "\x1b[1m\x1b[32m🏆 恭喜！所有挑战均已通过！为你点赞！\x1b[0m",
    )
    print(
        "\x1b[33m✨ 下一步：你可以将你的 MiniMoonBit 项目整理，提交给 MGPIC 评测机，获得最终认证和丰厚奖励！\x1b[0m",
    )
    print(
        "也可以继续探索 MoonBit 语言的更多特性，尝试为你的编译器添加更多功能！",
    )
    print("祝你在编程的星辰大海中一切顺利！")
    print(
        "\x1b[1m\x1b[32m========================================================\x1b[0m",
    )


async def construct_challenges() -> List[Challenge]:
    """构建挑战列表，并进行文件检查"""
    challenges: List[Challenge] = []
    data_zip = Path("data.zip")

    if not data_zip.exists():
        print("\x1b[31m❌ [致命错误] data.zip 文件未找到！请检查项目根目录。\x1b[0m")
        return challenges

    def list_zip_contents() -> List[str]:
        try:
            with zipfile.ZipFile(data_zip, "r") as zf:
                return zf.namelist()
        except zipfile.BadZipFile:
            print(
                "\x1b[31m❌ [致命错误] data.zip 文件损坏或不是合法的 ZIP 文件！\x1b[0m"
            )
            return []

    file_list = await asyncio.to_thread(list_zip_contents)
    if not file_list:
        return challenges

    for name in challenge_names:
        mbt_name = f"{name}.mbt"
        if mbt_name not in file_list:
            print(f"\x1b[31m❌ [致命错误] data.zip 中缺少挑战文件：{mbt_name}！\x1b[0m")
            return challenges

    for name in challenge_names:
        if name.startswith("tokenize"):
            dir_name = "lexer"
        elif name.startswith("parse"):
            dir_name = "parser"
        elif name.startswith("typecheck"):
            dir_name = "typecheck"
        elif name.startswith("knf"):
            dir_name = "knf"
        elif name.startswith("interp"):
            dir_name = "interp"
        elif name.startswith("codegen"):
            dir_name = "codegen"
        else:
            print(f"\x1b[31m❌ [配置错误] 未知挑战类型：{name}\x1b[0m")
            raise SystemExit(1)

        challenges.append(Challenge(name=name, dir=dir_name))

    return challenges


async def main():
    """主逻辑函数，增加 moon check 检查"""

    # ----------------------------------------------------
    # 新增逻辑：运行 `moon check` 命令
    # ----------------------------------------------------
    def run_moon_check() -> int:
        try:
            # 使用 subprocess.run 运行 moon check
            result = subprocess.run(
                ["moon", "check"],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            return result.returncode
        except FileNotFoundError:
            # 如果 moon 命令找不到，也视为失败
            return 127
        except Exception:
            # 其他错误
            return 1

    # 在异步环境中运行同步命令
    check_return_code = await asyncio.to_thread(run_moon_check)

    if check_return_code != 0:
        print("\x1b[31mmoon check运行失败，请检查你的代码\x1b[0m")
        return
    # ----------------------------------------------------
    # 新增逻辑结束
    # ----------------------------------------------------

    challenges = await construct_challenges()
    if not challenges:
        return

    # 查找第一个未通过的挑战
    print("\n\x1b[1m\x1b[34m🔍 正在检查挑战进度...\x1b[0m")
    # 黄色警告
    print(
        "\x1b[33m⚠️ 注意：如果长时间未退出，请检查你的代码是否存在潜在的无限循环。\x1b[0m",
    )

    first_not_passed: Optional[Challenge] = None
    challenge_idx = -1
    for i, challenge in enumerate(challenges):
        passed, fails = await challenge.check()
        if not passed:
            first_not_passed = challenge
            first_fails = fails
            challenge_idx = i
            break

    if first_not_passed is None:
        print_conguratulation()
        return

    # 第一个未通过的挑战
    print(
        f"\n\x1b[1m\x1b[34m🎯 当前需要攻克的挑战：{first_not_passed.name}\x1b[0m",
    )

    if await first_not_passed.mbt_existed():
        detail = f"：失败用例 -> [{'; '.join(first_fails)}]" if first_fails else ""
        print(
            f"\x1b[31m💔 {first_not_passed.name}.mbt \x1b[1m测试未通过{detail}。",
        )
        print(
            f"\x1b[0m\x1b[33m 别灰心，在 {first_not_passed.dir} 目录下修改代码，加油！\x1b[0m",
        )
        return

    # 如果是第一个挑战且文件不存在，则打印启动信息
    if first_not_passed.name == challenge_names[0]:
        print_start()

    # 从第一个未通过的挑战开始激活
    challenge_view = challenges[challenge_idx:]
    for challenge in challenge_view:
        print(
            f"\n\x1b[34m✨ 为你激活下一项挑战：\x1b[1m{challenge.name}\x1b[0m",
        )
        print(
            f"\x1b[34m(位于 \x1b[36m{challenge.dir}/{challenge.name}.mbt\x1b[0m\x1b[34m) ...\x1b[0m",
        )
        await challenge.extract()
        passed, fails = await challenge.check()
        if passed:
            print(
                f"\x1b[32m🎉 \x1b[1m{challenge.name}\x1b[0m \x1b[32m也顺利通过了！干得漂亮！继续前进！\x1b[0m",
            )
            continue
        else:
            dir_name = challenge.dir
            print(
                f"\n\x1b[1m\x1b[33m🚧 下一项挑战已就位！请前往 \x1b[36m{dir_name}/{challenge.name}.mbt。\x1b[0m",
            )
            print("\x1b[33m祝你成功！\x1b[0m")
            return

    # 如果所有挑战都遍历并激活通过
    print_conguratulation()


if __name__ == "__main__":
    # 运行主异步函数
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\x1b[33m程序被用户中断。\x1b[0m")
    except SystemExit:
        # 处理 panic() 导致的退出
        pass
