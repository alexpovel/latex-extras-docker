# Docker with full TeXLive distribution and Java

Originally created to use `lualatex` in conjunction with `bib2gls` using `latexmk` as illustrated [here](https://tex.stackexchange.com/a/401979/120853).
Next to the solution shown there, add `$pdf_mode = 4;` into `latexmkrc` to use `lualatex` for all call of `latexmk`.

`bib2gls` requires Java.
