# ltxsvg

## Description

**ltxsvg** is intended to be used as preprocessor converting LaTeX formulae
embedded within XHTML file to SVG format. The preprocessed documents can be
browsed in any SVG-capable browser without use of tools such as **MathJax**.

The program looks for any occurrence of **<math>** or **<display>** elements
bound to the custom namespace **"https://github.com/urbic/ltxsvg"** in the
given XHTML document. The text content of these elements prepended with LaTeX
preamble is passed to **latex**. Then the DVI output from **latex** is passed
to **dvisvgm**. The SVG output of **dvisvgm** is wrapped into XHTML **<div>**
element, whose attributes serve to proper resize SVG content and to align it on
the baseline of the surrounding text. After all the resulting **<div>** wrapper
replaces the original **<math>** or **<display>** element.

The **<div>** wrappers are provided with **class** attributes, either
**"ltxsvg-math"** or **"ltx-display"**, which can serve to styling or scripting
purposes.

The text characters in the resulting SVG are rendered using SVG **<path>**
elements. Since the same characters are usually found many times within the
document, their repeated occurrences are replaced by **<use>** elements linked
to corresponding **<path>** elements.  This approach can significally reduce
the size of the resulting file.

The program performs some mangling on the **id** attributes in SVG elements to
prevent their collisions.
