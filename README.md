# ltxsvg

## Synopsis

**`ltxsvg`** `[` _`option…`_ `]` _`input_file`_

## Description

**ltxsvg** is intended to be used as preprocessor converting LaTeX formulae
embedded within XHTML file to SVG format. The preprocessed documents can be
browsed in any SVG-capable browser without use of tools such as
**[MathJax](http://mathjax.org)**.

The program looks for any occurrence of `<math>` or `<display>` elements bound
to the custom namespace `"https://github.com/urbic/ltxsvg"` in the given XHTML
document. The text content of these elements prepended with LaTeX preamble is
passed to **latex**. Then the DVI output from **latex** is passed to
**dvisvgm**. The SVG output of **dvisvgm** is wrapped into XHTML `<div>`
element, whose attributes serve to properly scale SVG content and to align it on
the baseline of the surrounding text. After all the resulting `<div>` wrapper
replaces the original `<math>` or `<display>` element.

The `<div>` wrappers are provided with `class` attributes, either
`"ltxsvg-math"` or `"ltxsvg-display"`, which can serve for styling or scripting
purposes.

The text characters in the resulting SVG are rendered using SVG `<path>`
elements. Since the same characters are usually found many times within the
document, their repeated occurrences are replaced by `<use>` elements linked to
corresponding `<path>` elements.  This approach can significally reduce the
size of the resulting file.

The program performs some mangling on the `id` attributes in SVG elements to
prevent their collisions.

## Options

* **`-o`**, **`--output-file`** _`output_file`_

The name of the output file. With no _`output_file`_ or when _`output_file`_ is
`-` the result is redirected to the standard output.

* **`-p`**, **`--preamble-file`** _`preamble_file`_

The name of the file containing the LaTeX preamble. When not given, the
following preamble is assumed:

```latex
%&latex
\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage{stix}
\usepackage{amsmath}
\usepackage{xcolor}
\begin{document}
```

* **`-s`**, **`--scale`** _`factor`_

Scale the SVG formulae by the given _`factor`_.

* _`input_file`_

The name of the input file.

