package LTXSVG;

use strict;
use IO::Handle;
use File::Spec;
use File::Temp;
use File::Basename;
use XML::LibXML;
use feature 'state';

our $VERSION=v0.0.5;

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

__END__

=pod

=head1 NAME

LTXSVG - convert LaTeX formulae to SVG documents

=head1 SYNOPSIS

	use LTXSVG;

	my $ltxsvg=LTXSVG->new;
	my $svgdom=$ltxsvg->makeSVG('\frac{\pi^2}6=\sum_{k=1}^\infty k^{-2}');
	print $svgdom->toString;

=head1 DESCRIPTION

The B<LTXSVG> package allows to convert LaTeX formulae to SVG images.

B<LTXSVG> converter creates a TeX source document for each formula, translates
it to DVI format and converts the resulting DVI document to SVG format by
dvisvgm(1) program.

=head1 API

=over

=item LTXSVG-E<gt>new(I<%options>)

Returns a new LaTeX to SVG converter. This method takes a hash containing the
configuration options. Valid options are:

=over

=item B<preamble>

The LaTeX preamble i.E<nbsp>e. the stuff preceding "\begin{document}" command,
The default value is

	%&latex
	\documentclass{article}
	\usepackage[utf8]{inputenc}
	\usepackage{stix}
	\usepackage{amsmath}

If the first line in preamble starts with "%&" characters, the rest of the line
is used as the name of the format.

=item B<fontSize>

The font size, the default value is "10pt". The font size specification
consists of a positive integer or floating point number and a unit (without any
whitespace in between). Valid units are "in" (inch), "pt" (point), "cm"
(centimeter), "mm" (millimeter), "pc" (pica), "px" (pixel).

=item B<latex>

The L<latex(1)> invocation command, "pdftex" by default.

=item B<dvisvgm>

The L<dvisvgm(1)> invocation command, "dvisvgm" by default.

=back

=item I<$ltxsvg>-E<gt>makeSVG(I<$formula>, [I<$display>])

Returns an L<XML::LibXML::Document(3pm)> object containing the representation
of the SVG document.

=back

=head1 SEE ALSO

L<latex(1)>, L<dvisvgm(1)>.

=head1 LICENSE

zlib/png.

=head1 AUTHOR

B<LTXSVG> was written by Anton Shvetz E<lt>tz@sectorb.msk.ruE<gt>.

=cut
