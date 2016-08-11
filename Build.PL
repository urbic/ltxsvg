#!/usr/bin/perl
use Module::Build;

Module::Build->new
	(
		dist_name=>'ltxsvg',
		dist_version_from=>'lib/LTXSVG.pm',
		dist_author=>'Anton Shvetz <tz@sectorb.msk.ru>',
		dist_abstract=><<__ABSTRACT__,
The command-line utility ltxsvg is intended to be used as preprocessor
converting TeX formulae embedded within XML file to SVG format. The program
uses an approach similar to one that implemented in MetaPost btex … etex
construct. The ltxsvg uses TeX and dvisvgm to render the formulae.

The program looks for any occurrence of <math> or <display> elements bound to
the custom namespace "https://github.com/urbic/ltxsvg" in the given XML
document and replaces it with the SVG rendering. The text content of these
elements is interpreted as TeX formula.

The preprocessed XHTML and SVG documents can be browsed in any SVG-capable
browser without use of tools such as MathJax.
__ABSTRACT__
		license=>'Zlib',
		create_license=>1,
		create_readme=>0,
		requires=>
			{
				'perl'=>'5.18.2',
				'IO::Handle'=>'1.34',
				'XML::LibXML'=>'2.0019',
				'File::Basename'=>'2.84',
				'Digest::MD5'=>'2.52',
				'Cwd'=>'3.40',
				'Encode'=>'2.49',
				'IO::CaptureOutput'=>'1.1104',
			},
		build_requires=>
			{
			},
		configure_requires=>
			{
				'Software::License'=>'0.103012',
				'Module::Build'=>'0.38',
			},
	)
	->create_build_script;
