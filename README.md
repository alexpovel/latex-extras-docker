# Docker image with a full TeXLive distribution (texlive-full), Java and InkScape

[On Dockerhub.](https://cloud.docker.com/u/alexpovel/repository/docker/alexpovel/javalatex)

___

Originally created to use `lualatex` in conjunction with `bib2gls` using `latexmk` as illustrated [here](https://tex.stackexchange.com/a/401979/120853) and employed [here](https://github.com/alexpovel/thesis_template).

Next to the solution shown there, add `$pdf_mode = 4;` into `latexmkrc` to use `lualatex` for all calls of `latexmk`.
Also using `shell-escape` (see [here](#svg-graphics)), the `.latexmkrc` file could look like

```perl
# PERL latexmk config file

# Mode 4 uses lualatex for all calls of 'latexmk'
$pdf_mode = 4;

# We require --shell-escape (execution of code outside of latex) for the 'svg' package.
# It converts raw SVG files to the PDF+PDF_TEX combo using InkScape
$lualatex = "lualatex --shell-escape";

# Grabbed from latexmk CTAN distribution:
# Implementing glossary with bib2gls and glossaries-extra, with the
#  log file (.glg) analyzed to get dependence on a .bib file.
# !!! ONLY WORKS WITH VERSION 4.54 or higher of latexmk

# Push new file endings into list holding those files
# that are kept and later used again (like idx, bbl, ...):
push @generated_exts, 'glstex', 'glg';

# Add custom dependency.
# latexmk checks whether a file with ending as given in the 2nd
# argument exists ('toextension'). If yes, check if file with
# ending as in first argument ('fromextension') exists. If yes,
# run subroutine as given in fourth argument.
# Third argument is whether file MUST exist. If 0, no action taken.
add_cus_dep('aux', 'glstex', 0, 'run_bib2gls');

# PERL subroutine. $_[0] is the argument (filename in this case).
# File from author from here: https://tex.stackexchange.com/a/401979/120853
sub run_bib2gls {
    if ( $silent ) {
	#	my $ret = system "bib2gls --silent --group '$_[0]'"; # Original version, probably for Linux
        my $ret = system "bib2gls --silent --group $_[0]"; # Runs in PowerShell
    } else {
	#	my $ret = system "bib2gls --group '$_[0]'"; # Original version, probably for Linux
        my $ret = system "bib2gls --group $_[0]"; # Runs in PowerShell
    };
    
    my ($base, $path) = fileparse( $_[0] );
    if ($path && -e "$base.glstex") {
        rename "$base.glstex", "$path$base.glstex";
    }

    # Analyze log file.
    local *LOG;
    $LOG = "$_[0].glg";
    if (!$ret && -e $LOG) {
        open LOG, "<$LOG";
	while (<LOG>) {
            if (/^Reading (.*\.bib)\s$/) {
		rdb_ensure_file( $rule, $1 );
	    }
	}
	close LOG;
    }
    return $ret;
}
```

`bib2gls` requires Java.

## SVG graphics

Including SVG files using (`lua`)`latex` is not very straightforward.
Using the [`svg`](https://ctan.org/pkg/svg?lang=en) package, the workflow is somewhat automated.
We keep just the original SVG files as the single source of truth, and leave the generation of the `pdf` and accompanying `pdf_tex` file to the package.
It calls InkScape for converting the `svg` to `pdf` (or another format of choice), and if the `svg` contains text to be included as LaTeX, a sidecar `pdf_tex` file is generated (the default behaviour).
To call InkScape, it requires outside access, aka `--shell-escape`.
Once those files are generated, they can be treated as temporary junk and are always easily regenerated.

After years of experimentation, this seems like the best workflow.
The only laborious manual task left is placement of annotations onto the generated PDF files (generated automatically by [`svg`](https://ctan.org/pkg/svg?lang=en) from the SVG source files).

This seems like the best deal: no text is left in the SVG files themselves.
Placing and debugging text in SVG files using the InkScape -> PDF+PDF_TEX route is very annoying.
This is because while InkScape offers text alignment operations (left, center, right) that translate into the embedded PDF_TEX, the font cannot be known a priori while working on the SVG.
Neither font size (most importantly its height), nor any other font property can be assumed.
This also makes functions like "Resize page to drawing or selection" futile if text is part of the outer elements of a drawing.

Wanting to change any text later on results in having to start InkScape instead of just doing it in the TeX source.
The alternative is to place macros (`\newcommand`) everywhere inside the original SVG where content should later be placed.
These macros serve as labels, but are ugly, annoying, and remove the usability of the plain, original SVG file (since we would first need to know what each macro stands for).

Using the `svg` package to generate plain, text-less PDFs and only later adding any text/annotation in the TeX source itself seems the best of both worlds.

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
