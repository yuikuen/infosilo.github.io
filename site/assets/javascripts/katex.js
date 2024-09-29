// 使用 renderMathInElement 函数来渲染页面中的数学公式
// 作用是在页面中查找符合指定分隔符规则的数学公式，并使用 MathJax 或类似的工具来渲染这些公式
document$.subscribe(({ body }) => { 
    renderMathInElement(body, {
      delimiters: [
        // 使用 $ 符号作为内联数学公式的起始和结束分隔符，并将其显示为块级公式
        { left: "$$",  right: "$$",  display: true },
        // 使用 $ 符号作为内联数学公式的起始和结束分隔符，并将其显示为行内公式。
        { left: "$",   right: "$",   display: false },
        // 使用 \( \) 作为内联数学公式的起始和结束分隔符，并将其显示为行内公式。
        { left: "\\(", right: "\\)", display: false },
        // 使用 \[ \] 作为块级数学公式的起始和结束分隔符，并将其显示为块级公式。
        { left: "\\[", right: "\\]", display: true }
      ],
    })
  })
