package LTXSVG;

use strict;
use IO::Handle;
use File::Spec;
use File::Temp;
use File::Basename;
use XML::LibXML;
use feature 'state';

our $VERSION='0.0.4';

use constant
	{
		NS_XHTML=>'http://www.w3.org/1999/xhtml',
		NS_SVG=>'http://www.w3.org/2000/svg',
		NS_XLINK=>'http://www.w3.org/1999/xlink',
		NS_L2S=>'https://github.com/urbic/ltxsvg',
		UNITS=>{pt=>.1, in=>7.2, pc=>1.2, cm=>2.83464566929134, mm=>.283464566929134, px=>.075},
		PREAMBLE=><<'__TEX__',
%&latex
\documentclass{article}
\usepackage[russian]{babel}
\usepackage[utf8]{inputenc}
\usepackage{stix}
\usepackage{amsmath}
__TEX__
		LATEX=>'pdftex',
		DVISVGM=>'dvisvgm',
	};

sub new(%)
{
	my $class=shift;
	my $self={@_};
	$self->{preamble}//=PREAMBLE;
	$self->{latex}//=LATEX;
	$self->{dvisvgm}//=DVISVGM;
	$self->{scale}=1;

	if(defined $self->{fontSize})
	{
		if($self->{fontSize}=~m/^(.+?)(in|p[tcx]|[cm]m)$/)
		{
			$self->{scale}=$1*UNITS->{$2};
		}
		else
		{
			die "LTXSVG::new: Improper fontSize parameter!\n";
		}
	}

	return bless $self, $class;
}

sub makeSVG($$)
{
	my $self=shift;
	my $tex=shift;
	my $display=shift//0;

	my ($file, $texName)=File::Temp::tempfile('ltxsvg-XXXXX', SUFFIX=>'.tex');
	$file->binmode(':utf8');
	my $baseName=File::Basename::basename($texName, '.tex');

	$file->print($self->{preamble}.<<'__TEX__');
\makeatletter
\gdef\svgshipout#1{\shipout\hbox{\setbox\z@=\hbox{#1}\dimen\z@=\ht\z@\advance\dimen\z@\dp\z@
\dimen\@ne=\ht\z@\dimen\tw@=\dp\z@\setbox\z@=\hbox{\box\z@\vrule width\@ne sp
\ifnum\dimen\z@>\z@ height\dimen\@ne depth\dimen\tw@\else height\@ne sp depth\z@\fi}\ht\z@=\z@\dp\z@=\z@\box\z@}}
\makeatother
\begin{document}%%
__TEX__

	$file->print("\\svgshipout{\$".($display? "\\displaystyle ": '')."$tex\$}\n");
	
	$file->print(<<'__TEX__');
\end{document}
__TEX__

	system "$self->{latex} --parse-first-line --interaction=batchmode \"$baseName\" >".File::Spec->devnull
		and die "Error during LaTeXing. See $baseName.log for explanation";
	system $self->{dvisvgm}, "-Z$self->{scale}", '-v0', '--no-fonts', $baseName;
	
	my $svgDoc=XML::LibXML->load_xml(location=>"$baseName.svg");

	unlink "$baseName$_" for qw/.log .aux .tex .dvi .svg/;
	#unlink "$baseName$_" for qw/.log .aux .tex .dvi/;

	_unicalizeIds($svgDoc);

	return $svgDoc;
}

sub _unicalizeIds
{
	my $doc=shift;
	my $rootElement=$doc->documentElement;
	my @idNodes=$rootElement->getElementsByTagNameNS(NS_SVG, '*');
	my %replacements;
	for my $e(@idNodes)
	{
		my $id=$e->getAttribute('id');
		next unless $id;
		$replacements{$id}=_generateId();
		$e->setAttribute('id', $replacements{$id});
	}
	for my $e(@idNodes)
	{
		my $href=$e->getAttributeNS(NS_XLINK, 'href');
		next unless $href;
		for my $oldId(keys %replacements)
		{
			$e->setAttributeNS(NS_XLINK, 'href', "#$replacements{$oldId}")
				if $href eq "#$oldId";
		}
	}
}

sub _generateId
{
	state $n=0;
	$n++;
	return "ltxsvg-$n";
}

return 1;
