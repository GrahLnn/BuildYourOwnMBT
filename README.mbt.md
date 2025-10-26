# 🚀 Build Your Own MoonBit

## 注：

- 10.26: 全部篇章已开放，本项目将会长期维护，11月13日MGPIC比赛结束后，将会公布所有答案。

## 🌟 欢迎来到编译器的魔法世界！

你是否对编译器——连接人类语言和机器指令的“黑匣子”充满了好奇？**Build Your Own MoonBit** 是一个专为编程爱好者、学生和所有渴望深入理解编译器原理的人设计的**全程互动式教程**。

本项目旨在为你提供一个**完整、系统、循序渐进**的实践系列，让你无需复杂的环境配置，即可从零开始，一步一步搭建出一个功能完备的 MiniMoonBit 编译器。这不是一套枯燥的理论课件，而是一场**以挑战驱动的编程冒险！**

-----

## 💡 你将学到什么？（编译器的核心流程）

通过本项目，你将亲手实现现代编译器的核心组件，掌握编译器开发的“六脉神剑”：

1.  **Lexer 词法分析器 (Scanner)：**

      * 将源代码文本分解为有意义的Token，这是编译器理解代码的第一步。

2.  **Parser 语法分析器：**

      * 将词素流组织成抽象语法树（AST），理解代码的结构和层次关系。

3.  **Type Checker 类型检查：**

      * 对 AST 进行静态语义分析，确保代码的逻辑和类型系统是健全和正确的。

4.  **KNF 转换 (Kernel Normal Form)：**

      * 将高级语言的结构转化为编译器内部统一、简化的中间表示形式，为后续的代码生成做准备。

5.  **LLVM 代码生成：**

      * 利用业界标准的 LLVM 后端，将你的代码转化为高性能的机器可执行代码。

-----

## 🛠️ 如何开始你的编译器构建之旅？

本项目使用 **MoonBit** 语言和工具链进行开发。请确保你的环境已准备就绪。

### 步骤 1：准备 MoonBit 环境

你需要先安装 MoonBit 命令行工具（CLI）。

  * **Linux/Mac 用户：**
    ```bash
    curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
    ```
  * **Windows 用户 (使用 PowerShell)：**
    ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex
    ```
  * **VSCode 用户：** 推荐在 VSCode 插件市场搜索并安装 **MoonBit** 插件，获得最佳开发体验。

### 步骤 2：获取并运行项目

1.  **Fork 本项目：** 点击页面右上角的 `Fork` 按钮，将项目派生到你自己的 GitHub 仓库下。
2.  **Clone 到本地：**
    ```bash
    git clone [你自己的仓库地址]
    cd BuildYourOwnMoonbit
    ```
3.  **启动引导程序：** 运行以下命令，**`watch` 目录下的引导程序**将启动，它会逐一解锁挑战，引导你完成整个编译流程。
    ```bash
    moon run watch
    ```

    如果您使用windows，可以使用`python3 watch.py`来代替`moon run watch`。

> **小贴士：** 运行 `moon run watch` 后，请仔细阅读终端的提示信息，它会告诉你当前要完成的挑战、代码应该修改的位置以及如何检查你的答案是否正确！

-----

## 🎁 闯关赢大奖！

当你成功完成所有的编程挑战后，你所构建的 MiniMoonBit 编译器不仅仅是一个学习成果！

本项目与 **MGPIC** 的\*\*“编译赛道”\*\*紧密结合！

  * **将你的代码整理完善后，提交给 MGPIC 的评测机。**
  * **你将有机会根据你的完成度和质量，获得比赛的正式分数和丰厚奖励！**

🚀 赶快运行一下 `moon run watch`，开启你的编译器开发英雄之旅吧！

