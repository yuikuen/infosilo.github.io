// 配置 MathJax,在网页中显示数学公式的工具库
window.MathJax = {
    tex: {
      // 指定内联数学公式的开始和结束分隔符为\\(和\\)
      inlineMath: [["\\(", "\\)"]],
      // 指定展示（块级）数学公式的开始和结束分隔符为\\[和\\]
      displayMath: [["\\[", "\\]"]],
      processEscapes: true,
      processEnvironments: true
    },
    options: {
      ignoreHtmlClass: ".*|",
      processHtmlClass: "arithmatex"
    }
  };
  
  document$.subscribe(() => { 
    MathJax.typesetPromise()
  })
