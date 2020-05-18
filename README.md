# Docker with a custom, almost-full TeXLive distribution & custom tools

Serves a lot of needs surrounding LaTeX file generation.
For the rationale behind the used packages, see
[here](https://collaborating.tuhh.de/cap7863/latex-git-cookbook/-/blob/master/README.md#docker).

This Docker image is based on a custom TeXLive installer using their `install-tl` tool,
instead of Debian's `texlive-full`.
This affords us the latest packages directly from the source, and is the
recommended/proper way of installing TeXLive.
Further, the installation can be adjusted better; for example, over 2GB of unneeded PDF
documentation files is saved this way.

## Custom Tools

The auxiliary tools are:

- Java Runtime Environment for `bib2gls`
- `gnuplot`
- `inkscape`
- `pandoc` with the [Eisvogel template](https://github.com/Wandmalfarbe/pandoc-latex-template)

---
>>>>>>> 6827b89... Rework entire Dockerfile

[On Dockerhub.](https://cloud.docker.com/u/alexpovel/repository/docker/alexpovel/latex)

___

Originally created to use `lualatex` in conjunction with `bib2gls` using `latexmk` as illustrated
[here](https://tex.stackexchange.com/a/401979/120853) and employed
[here](https://github.com/alexpovel/thesis_template).
