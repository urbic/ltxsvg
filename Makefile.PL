use inc::Module::Install;

# Define metadata
name			'ltxsvg';
version_from	'lib/LTXSVG.pm';
author			'Anton Shvetz, <mailto:tz@sectorb.msk.ru?subject=ltxsvg>';
license			'Zlib/png';
homepage		'https://github.com/urbic/ltxsvg';
repository		'https://github.com/urbic/ltxsvg.git';
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
requires		'Capture::Tiny'=>'0.36';
requires		'Cwd'=>'3.40';
requires		'Digest::MD5'=>'2.52';
requires		'Encode'=>'2.49';
requires		'File::Basename'=>'2.84';
requires		'File::Copy'=>'2.26';
requires		'File::Path'=>'2.09';
requires		'IO::Handle'=>'1.34';
requires		'LockFile::Simple'=>'0.208';
requires		'XML::LibXML'=>'2.0019';

requires_external_bin	'dvisvgm';
requires_external_bin	'pdftex';

test_requires  'Test::More'=>'0.98';

install_script	'bin/ltxsvg';

makemaker_args	dist=>{ COMPRESS=>'gzip --best --force'};

postamble <<'__MAKEFILE__';
OBSBUILDDIR=blib/obs
OBSPACKAGENAME=$(NAME)
OBSPROJECTNAME=home:concyclic
OBSBUILDARCH=x86_64
#OBSBUILDREPO=Debian_8.0
#OBSBUILDSPEC=$(NAME)$.$(if $(findstring Debian,$(OBSBUILDREPO)),dsc)
#OBSBUILDSPEC=$(NAME).$(if $(findstring Debian,Debian),dsc,spec)
OBSBUILDSPEC=$(NAME).$(if $(filter Debian_% Ubuntu_%,$(OBSBUILDREPO)),dsc,spec)

$(OBSBUILDDIR):
	osc checkout -o $@ $(OBSPROJECTNAME) $(OBSPACKAGENAME)

obs_build: all dist $(OBSBUILDDIR)
	echo .$(if $(filter Debian Ubuntu,$(OBSBUILDREPO)),dsc,spec)
	cp obs/* $(DISTVNAME).tar$(SUFFIX) $(OBSBUILDDIR)
	$(PERL) -i -npe 's/\@NAME\@/$(NAME)/g; s/\@VERSION\@/$(VERSION)/g' $(OBSBUILDDIR)/{$(NAME).{spec,dsc},debian.control}
	cd $(OBSBUILDDIR) && osc build $(OBSBUILDREPO) $(OBSBUILDARCH) $(OBSBUILDSPEC)
__MAKEFILE__

WriteAll;
