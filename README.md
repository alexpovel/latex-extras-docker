# Docker with a custom, almost-full TeXLive distribution & custom tools

Serves a lot of needs surrounding LaTeX file generation.
For the rationale behind the used packages, see below.

This Docker image is based on a custom TeXLive installer using their `install-tl` tool,
instead of Debian's `texlive-full`.
This affords us the latest packages directly from the source, and is the
recommended/proper way of installing TeXLive.
Further, the installation can be adjusted better; for example, over 2GB of unneeded PDF
documentation files is saved this way.
`install-tl` is configured via [`texlive.profile`](texlive.profile).

## Custom Tools

The auxiliary tools are:

- Java Runtime Environment (`default-jre-headless`) for `bib2gls` from the
  `glossaries-extra` [package](https://www.ctan.org/pkg/glossaries-extra?lang=de).

  `bib2gls` takes in `*.bib` files with glossary, symbol, index and other definitions
  and applies sorting, filtering etc.
  For this, it requires Java.
- `inkscape` because the [`svg`](https://ctan.org/pkg/svg) package needs it.

  Using that package, the required PDFs and PDF_TEXs are only generated at build-time
  on the server, and afterwards discarded.
  If you work locally, they will be kept in `images/vectors/svk-inkscape/`, so that they
  do not have to be regenerated each time.
  This is somewhat important since PDFs are binary and should not occur in git
  repositories.
  Git can only accept PDFs as single blobs and cannot diff them properly.
  If git cannot efficiently store only the *changes* between two versions of a file,
  like it can with text-based ones, the repository might absolutely explode in size.
  It works, but should be avoided.

  The `svg` package gets rid of all the PDF/PDF_TEX intermediate junk and lets us
  deal with the true source, the `*.svg` files directly.
- `gnuplot` for `contour gnuplot` commands for `addplot3` in `pgfplots`.
  So essentially, an external add-on for the magnificent `pgfplots` package.
  Being an external tool, `gnuplot` also requires `shell-escape`.
- `pandoc` as a very flexible, convenient markup conversion tool.

  For example, it can convert Markdown (like this very [README](README.md)) to PDF
  via LaTeX:

  ```bash
  pandoc README.md -o README.pdf
  ```

  The default output is usable, but not very pretty.
  This is where *templates* come into play.
  A very tidy and well-made such template is
  [*Eisvogel*](https://github.com/Wandmalfarbe/pandoc-latex-template).
  Its installation is not via a package, so it has to be downloaded specifically.
  For this, additional requirements are:

  - `curl` to look for the URL to the most recent release,
  - `wget` to download the found archive,
  - `librsvg2-bin` for the `rsvg-convert` tool.
    This is used by `pandoc` to convert SVGs when embedding them into the new PDF.

  Note that `pandoc` and its *Eisvogel* template draw
  [metadata from the YAML header](https://pandoc.org/MANUAL.html#metadata-variables),
  for example:

  ```yaml
  ---
  title: "Title"
  author: [Author]
  date: "YYYY-MM-DD"
  subject: "Subject"
  keywords: [Keyword1, Keyword2]
  lang: "en"
  ...
  ```

  among other metadata variables.
  This info is detected and *not* rendered by many Markdown rendering engines.
  *Eisvogel* uses it to fill the document with info, *e.g.* the PDF header and
  footer.

  `pandoc` is not required for LaTeX work, but is convenient to have at the ready for
  various conversion jobs.

## DockerHub

This repository is
[linked to Dockerhub.](https://cloud.docker.com/u/alexpovel/repository/docker/alexpovel/latex)
Access the image as

```text
alexpovel/latex
```

___

Originally created to use `lualatex` in conjunction with `bib2gls` using `latexmk` as illustrated
[here](https://tex.stackexchange.com/a/401979/120853) and employed
[here](https://github.com/alexpovel/thesis_template).
