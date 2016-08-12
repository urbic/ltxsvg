use inc::Module::Install;

# Define metadata
name			'ltxsvg';
version_from	'lib/LTXSVG.pm';
license			'Zlib/png';
abstract		<<__ABSTRACT__;
The command-line utility ltxsvg is intended to be used as preprocessor
converting TeX formulae embedded within XML file to SVG format. The program
uses an approach similar to one that implemented in MetaPost btex ... etex
construct. The ltxsvg uses TeX and dvisvgm to render the formulae.

The program looks for any occurrence of <math> or <display> elements bound to
the custom namespace "https://github.com/urbic/ltxsvg" in the given XML
document and replaces it with the SVG rendering. The text content of these
elements is interpreted as TeX formula.

The preprocessed XHTML and SVG documents can be browsed in any SVG-capable
browser without use of tools such as MathJax.
__ABSTRACT__

# Specific dependencies
requires		'perl'=>'5.18.2';
requires		'IO::Handle'=>'1.34';
requires		'XML::LibXML'=>'2.0019';
requires		'File::Basename'=>'2.84';
requires		'Digest::MD5'=>'2.52';
requires		'Cwd'=>'3.40';
requires		'Encode'=>'2.49';
requires		'Capture::Tiny'=>'0.44';

requires_external_bin	'dvisvgm';
requires_external_bin	'pdftex';

test_requires  'Test::More'  => '0.98';

#no_index       'directory'   => 'demos';
install_script	'bin/ltxsvg';

WriteAll;
