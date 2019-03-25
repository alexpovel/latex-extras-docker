# Docker with full TeXLive distribution and Java

Originally created to use `lualatex` in conjunction with `bib2gls` using `latexmk` as illustrated [here](https://tex.stackexchange.com/a/401979/120853).
Next to the solution shown there, add `$pdf_mode = 4;` into `latexmkrc` to use `lualatex` for all calls of `latexmk`.

`bib2gls` requires Java.

## Some thoughts

  - [`texlive-full` will usually prompt for Geographic Area](https://stackoverflow.com/q/52108289). Employ `ENV DEBIAN_FRONTEND noninteractive` to suppress dialog creation, to which we are unable to respond in a Docker building process (which is why it fails). It is discouraged from in the [FAQ](https://docs.docker.com/engine/faq/).
  - Went back from `FROM ubuntu:latest` to a specific version for long-term compatibility concerns.
  - [Keep Layers at a low count](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/), therefore summarize into one/few `RUN` commands.
  - Use development branch of OS to access latest versions of `latexmk`. E.g., `ubuntu:bionic` has an old version of it that would not work properly.

Based on:
  - https://github.com/blang/latex-docker
  - https://github.com/aergus/dockerfiles
  - https://github.com/Daxten/java-latex-docker
  - https://gordonlesti.com/building-a-latex-docker-image/
