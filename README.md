# ltxsvg

**ltxsvg** is intended to be used as preprocessor converting TeX formulae
embedded within XML file to SVG format. The program uses an approach similar to
one that implemented in **MetaPost**. **ltxsvg** uses **TeX** and **dvisvgm**
to render the formulae.

The program looks for any occurrence of `<math>` or `<display>` elements bound
to the custom namespace `"https://github.com/urbic/ltxsvg"` in the given XML
document and replaces it with the SVG rendering.

The preprocessed XHTML and SVG documents can be browsed in any SVG-capable
browser without use of tools such as [MathJax](http://mathjax.org).

## Features

- Special handling of the formulae in XHTML documents which allows to align
  rendered formulae on the baseline and adjust its size to fit the size of the
  surrounding text.

- Special handling of the formulae in SVG documents which allows to place the
  rendered formulae to the specified position. It is also possible to attach
  the rendering at the specified point as well as does the label command in
  **MetaPost**.

- Optimization intended to reduce the size of the resuling file and to
  accelerate its rendering in browser window.

- Caching the rendered formulae.

## License

[zlib/png](LICENSE).

## Author

[Anton Shvetz](mailto:tz@sectorb.msk.ru?subject=ltxsvg)
