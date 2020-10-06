# Docker with custom, almost-full TeXLive distributions & custom tools

Serves a lot of needs surrounding LaTeX file generation.
For the rationale behind the installed Debian packages, see [below](#custom-tools).

This Dockerfile is based on a custom TeXLive installer using their
[`install-tl` tool](https://www.tug.org/texlive/doc/install-tl.html),
instead of
[Debian's `texlive-full`](https://packages.debian.org/search?searchon=names&keywords=texlive-full).
Other, smaller `texlive-` collections would be
[available](https://packages.debian.org/search?suite=default&section=all&arch=any&searchon=names&keywords=texlive),
but TeXLive cannot install missing packages on-the-fly,
[unlike MiKTeX](https://miktex.org/howto/miktex-console/).
Therefore, images should come with all desirable packages in place; installing them after
the fact in running containers using [`tlmgr`](https://www.tug.org/texlive/tlmgr.html)
is the wrong approach.

---

Using ["vanilla" TeXLive](https://www.tug.org/texlive/debian.html)
affords us the latest packages directly from the source, while the official
Debian package might lag behind a bit.
This is often not relevant, but has bitten me several times while working with the
latest packages.

Also, the installation can be adjusted better.
For example, *multiple GBs* of space are saved by omitting unneeded PDF documentation files.

The `install-tl` tool is configured via [`texlive.profile`](texlive.profile), see also
the [documentation](https://www.tug.org/texlive/doc/install-tl.html#PROFILES).
This enables unattended, pre-configured installs, as required for a Docker installation.

## Historic Builds

LaTeX is a slow world, and many documents/templates in circulation still rely on
outdated practices or packages.
This can be a huge hassle.
Maintaining an old LaTeX distribution next to a current one on the same host is
not fun.
For this, Docker is the perfect tool.

This image can be built (`docker build`) with different build `ARG`s, and the build
process will figure out the proper way to handle installation.
There is a [script](texlive.sh) to handle getting and installing TeXLive from the
proper location ([current](https://www.tug.org/texlive/acquire-netinstall.html) or
[archive](ftp://tug.org/historic/systems/texlive/)).
Refer to the [Dockerfile](Dockerfile) for the required `ARG`s (all `ARG` without a default).

Note that for a *specific* TeXLive version to be picked, it needs to be present in their
[archives](ftp://tug.org/historic/systems/texlive/).
The *current* TeXLive is not present there (it's not historic), but is available under
the `latest` Docker tag.

To build an array of different versions automatically, DockerHub provides
[advanced options](https://docs.docker.com/docker-hub/builds/advanced/) in the form of
hooks, e.g. a [build hook](hooks/build).
These are bash scripts that override the default DockerHub build process.
At build time, DockerHub provides
[environment variables](https://docs.docker.com/docker-hub/builds/advanced/#environment-variables-for-building-and-testing)
which can be used in the build hook to forward these into the Dockerfile build process.
As such, by just specifying the image *tags* on DockerHub, we can build corresponding
images automatically, see also
[here](https://web.archive.org/web/20201005132636/https://dev.to/samuelea/automate-your-builds-on-docker-hub-by-writing-a-build-hook-script-13fp).

The approximate [matching of Debian to TeXLive versions](https://www.tug.org/texlive/debian.html)
is (see also [here](https://www.debian.org/releases/) and [here](https://www.debian.org/distrib/archive).):

| Debian Codename | Debian Version | TeXLive Version |
| --------------- | :------------: | :-------------: |
| bullseye        |       11       |      2020       |
| buster          |       10       |      2018       |
| stretch         |       9        |      2016       |
| jessie          |       8        |      2014       |
| wheezy          |       7        |      2012       |
| squeeze         |      6.0       |      2009       |
| lenny           |      5.0       |     unknown     |
| etch            |      4.0       |     unknown     |
| sarge           |      3.1       |     unknown     |
| woody           |      3.0       |     unknown     |
| potato          |      2.2       |     unknown     |
| slink           |      2.1       |     unknown     |
| hamm            |      2.0       |     unknown     |

This is only how the official Debian package is shipped.
These versions can be, to a narrow extend, freely mixed.
Using `install-tl`, older versions of TeXLive can be installed on modern Debian versions.

### Issues

Using [*obsolete* Debian releases](https://www.debian.org/releases/) comes with a long
list of headaches.
As such, Debian versions do not reach too far back.
It does not seem worth the effort.
Instead, it seems much easier to install older TeXLive versions onto reasonably recent
Debians.

Issues I ran into are:

- `apt-get update` will fail if the original Debian repository is dead (Debian 6/TeXLive 2014):

  ```plaintext
  W: Failed to fetch http://httpredir.debian.org/debian/dists/squeeze/main/binary-amd64/Packages.gz  404  Not Found
  W: Failed to fetch http://httpredir.debian.org/debian/dists/squeeze-updates/main/binary-amd64/Packages.gz  404  Not Found
  W: Failed to fetch http://httpredir.debian.org/debian/dists/squeeze-lts/main/binary-amd64/Packages.gz  404  Not Found
  E: Some index files failed to download, they have been ignored, or old ones used instead.
  ```

  As such, there needs to be a [dynamic way to update `/etc/apt/sources.list`](adjust_sources_list.sh)
  if the Debian version to be used in an archived one, see also
  [here](https://www.prado.lt/using-old-debian-versions-in-your-sources-list).
- `RUN wget` (or `curl` etc.) via `HTTPS` will fail for older releases, e.g. GitHub
  rejected the connection due to the outdated TLS version of the old release (Debian 6/TeXLive 2015):

  ```text
  Connecting to github.com|140.82.121.4|:443... connected.
  OpenSSL: error:1407742E:SSL routines:SSL23_GET_SERVER_HELLO:tlsv1 alert protocol version
  ```

- Downloading older releases requires using the [Debian archives](http://archive.debian.org/debian/).
  This works fine, however a warning is issued (Debian 6/TeXLive 2014):

  ```plaintext
  W: GPG error: http://archive.debian.org squeeze Release: The following signatures were invalid: KEYEXPIRED 1520281423 KEYEXPIRED 1501892461
  ```

  Probably related to this, the installation then fails:

  ```plaintext
  WARNING: The following packages cannot be authenticated!
    libgdbm3 libssl0.9.8 wget libdb4.7 perl-modules perl openssl ca-certificates
  E: There are problems and -y was used without --force-yes
  ```

  According to `man apt-get`, `--force-yes` is both deprecated and absolutely not
  recommended.
  The correct course here is to `--allow-unauthenticated`, however this would also
  affect the build process for modern versions, where authentication *did not* fail.
  The official Debian archives are probably trustworthy, but this is still an issue.
- A more obscure issue is (Debian 7/TeXLive 2011):

  ```plaintext
  The following packages have unmet dependencies:
    perl : Depends: perl-base (= 5.14.2-21+deb7u3) but 5.14.2-21+deb7u6 is to be installed
  E: Unable to correct problems, you have held broken packages.
  ```

  While the error message itself is crystal-clear, debugging this is probably a nightmare.
- Tools like `pandoc`, which was released in [2006](https://pandoc.org/releases.html),
  limit the earliest possible Debian version as long as the tool's installation is part
  of the Dockerfile.
  In this example, 2006 should in any case be early enough (if not, update your LaTeX
  file to work with more recent versions, that is probably decidedly work).

## Custom Tools

The auxiliary tools are:

- A *Java Runtime Environment* for [`bib2gls`](https://ctan.org/pkg/bib2gls) from the
  [`glossaries-extra` package](https://www.ctan.org/pkg/glossaries-extra).

  `bib2gls` takes in `*.bib` files with glossary, symbol, index and other definitions
  and applies sorting, filtering etc.
  For this, it requires Java.
- [`inkscape`](https://inkscape.org/) (the CLI, not the GUI) because the
  [`svg`](https://ctan.org/pkg/svg) package needs it.

  Using that package, required PDFs and PDF_TEXs are only generated at build-time
  (on the server or locally) and treated as a cache.
  As such, they can be discarded freely and are regenerated in the next compilation run,
  using `svg`, which calls `inkscape`.

  The `svg` package gets rid of all the PDF/PDF_TEX intermediate junk and lets us
  deal with the true source -- `*.svg` files -- directly.

  Being an external tool, `svg`/`inkscape` also requires the `--shell-escape` option to
  `lualatex` and friends for writing outside files.
- `gnuplot` for `contour gnuplot` commands for `addplot3` in `pgfplots`.
  So essentially, an external add-on for the magnificent `pgfplots` package.
  It also requires `--shell-escape`.
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
  *Eisvogel* uses it to fill the document with info, *e.g.* the PDF header and
  footer.

  `pandoc` is not required for LaTeX work, but is convenient to have at the ready for
  various conversion jobs.

## On DockerHub

Refer to this repository's homepage link for a link to the DockerHub repository for this
Dockerfile.
There, you will find the available tags and also under which name the image is available.
