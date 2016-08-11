package LTXSVG;

use strict;
use IO::Handle;
use File::Basename;
use Cwd;
use XML::LibXML;
use Digest::MD5;
use Encode;
use IO::CaptureOutput;
use feature 'state';

our $VERSION='1.02';

use constant
	{
		NS_XHTML=>'http://www.w3.org/1999/xhtml',
		NS_SVG=>'http://www.w3.org/2000/svg',
		NS_XLINK=>'http://www.w3.org/1999/xlink',
		NS_L2S=>'https://github.com/urbic/ltxsvg',
		PREAMBLE=><<'__TEX__',
%&latex
\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage{stix}
\usepackage{amsmath}
\begin{document}
__TEX__
#		TEX_SUPPORT=><<'__TEX__',
#\makeatletter
#\gdef\ltxsvgshipout#1{\shipout\hbox{\setbox\z@=\hbox{#1}\dimen\z@=\ht\z@\advance\dimen\z@\dp\z@
#\dimen\@ne=\ht\z@\dimen\tw@=\dp\z@\setbox\z@=\hbox{\box\z@
#%\vrule width\@ne sp\ifnum\dimen\z@>\z@ height\dimen\@ne depth\dimen\tw@\else height\@ne sp depth\z@\fi
#}\ht\z@=\z@\dp\z@=\z@\box\z@}}
#\makeatother
#__TEX__
		TEX_SUPPORT=><<'__TEX__',
\catcode`\@11\relax
\gdef\ltxsvgshipout#1{\shipout\hbox{\setbox\z@=\hbox{#1}\dimen\z@=\ht\z@\advance\dimen\z@\dp\z@
\setbox\z@=\hbox{\box\z@}\ht\z@=\z@\dp\z@=\z@\box\z@}}
\catcode`\@12\relax
__TEX__
		TEX=>'pdftex',
		DVISVGM=>'dvisvgm',
		SQRT2=>sqrt 2,
		CACHE_DIR=>($ENV{HOME}//$ENV{LOGDIR}//'.').'/.ltxsvg-cache',
	};

sub new(%)
{
	my $class=shift;
	my $self={@_};
	$self->{preamble}//=PREAMBLE;
	$self->{tex}//=TEX;
	$self->{dvisvgm}//=DVISVGM;
	$self->{scale}//=1;
	return bless $self, $class;
}

sub makeSVG($;%)
{
	my $self=shift;
	my $tex=shift;
	my %opts=@_;
	my $display=$opts{display}//'inline';

	my $texCode=$self->{preamble}.TEX_SUPPORT."\\ltxsvgshipout{\$"
			.($display eq 'block'? '\displaystyle ': '')."$tex\$}\n\\end{document}\n";
	my $baseName=Digest::MD5::md5_hex(Encode::encode_utf8($texCode));

	my $cwd=getcwd;
	mkdir CACHE_DIR or die "Can not create cache directory “".CACHE_DIR."”: $!\n"
		if !-d CACHE_DIR;
	chdir CACHE_DIR or die "Can not change to cache directory “".CACHE_DIR."”: $!\n";

	my $needToCache=0;
	unless(-f "$baseName.tex" and -f "$baseName.svg")
	{
		$needToCache=1;
	}
	else
	{
		open my $file, '<:utf8', "$baseName.tex";
		read $file, my $cachedTeXCode, -s $file;
		$needToCache=($cachedTeXCode ne $texCode);
	}

	if($needToCache)
	{
		open my $file, '>:utf8', "$baseName.tex";
		$file->print($texCode);
	
		my ($texOut, $texError, $texSuccess)=IO::CaptureOutput::capture_exec
				(
					$self->{tex},
					'--output-format=dvi',
					'--interaction=batchmode',
					'--parse-first-line',
					$baseName
				);

		unless($texSuccess)
		{
			warn "Error during TeX run: $texError\n";
			open my $texLog, '<', "$baseName.log";
			while(<$texLog>)
			{
				print "TeX error> $_";# if s/^! //;
			}
			warn 'See '.CACHE_DIR."/$baseName.log for details.\n";
		}

		my (undef, $dvisvgmError, $dvisvgmSuccess)=IO::CaptureOutput::capture_exec
				(
					$self->{dvisvgm},
					'-v0',
					'-n',
					$baseName
				);
		if($texSuccess)
		{
			unlink "$baseName$_" for qw/.log .aux .dvi/;
		}
		warn "Error during dvisvgm run: $dvisvgmError\n" unless $dvisvgmSuccess;
	}

	my $svgDoc=XML::LibXML->load_xml(location=>"$baseName.svg");

	chdir $cwd;

	#unlink "$baseName$_" for qw/.log .aux .tex .dvi .svg/;
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

sub _optimizePaths($)
{
	my $doc=shift;
	my %pathHash;
	my %pathIdReplacements;

	for my $path(@{$doc->documentElement->getElementsByTagNameNS(NS_SVG, 'path')})
	{
		if(exists $pathHash{$path->getAttribute('d')})
		{
			$pathIdReplacements{$path->getAttribute('id')}=$pathHash{$path->getAttribute('d')};
			my $parent=$path->parentNode;
			$parent->removeChild($path);
			for(@{$parent->childNodes})
			{
				if($_->nodeType==XML::LibXML::XML_TEXT_NODE and $_->textContent=~m/^\s+$/)
				{
					$parent->removeChild($_);
				}
			}
			if($parent->localName eq 'defs' and 0==@{$parent->childNodes})
			{
				$parent->parentNode->removeChild($parent);
			}
		}
		else
		{
			$pathHash{$path->getAttribute('d')}=$path->getAttribute('id');
		}
	}

	for my $use(@{$doc->documentElement->getElementsByTagNameNS(NS_SVG, 'use')})
	{
		my $href=$use->getAttributeNS(NS_XLINK, 'href');
		next unless $href=~s/^#//;
		if(exists $pathIdReplacements{$href})
		{
			$use->setAttributeNS(NS_XLINK, 'href', "#$pathIdReplacements{$href}");
		}
		for(qw/x y/)
		{
			my $att=$use->getAttribute($_);
			$use->removeAttribute($_) if defined $att and $att eq '0';
		}
	}
}

sub processFile($;$)
{
	my $self=shift;
	my $inputName=shift;
	my $outputName=shift;
	my $doc=XML::LibXML->load_xml(location=>$inputName);
	$self->processDocument($doc);

	if(defined $outputName)
	{
		$doc->toFile($outputName);
	}
	else
	{
		$doc->toFH(*STDOUT);
	}
}

sub processDocument($)
{
	my $self=shift;
	my $doc=shift;
	$doc->documentElement->removeAttribute('xmlns:ltx');
	for my $math(@{$doc->getElementsByTagNameNS(NS_L2S, 'math')},
			@{$doc->getElementsByTagNameNS(NS_L2S, 'display')})
	{
		my %opts=(display=>($math->localName eq 'display')? 'block': 'inline');
		for(qw/x y placement gap/)
		{
			$opts{$_}=$math->getAttribute($_) if $math->getAttribute($_);
		}
		my $svgDoc=$self->makeSVG($math->textContent, %opts);
		my $wrapped;
		if($math->parentNode->getNamespaceURI eq NS_XHTML)
		{
			$wrapped=$self->wrapForXHTML($svgDoc, %opts);
		}
		elsif($math->parentNode->getNamespaceURI eq NS_SVG)
		{
			$wrapped=$self->wrapForSVG($svgDoc, %opts);
		}
		else
		{
			$wrapped=$svgDoc->documentElement;
			$wrapped->setAttribute($_, $wrapped->getAttribute($_)*$self->{scale})
				for qw/width height/;
		}

		if($math==$math->ownerDocument->documentElement)
		{
			$math->ownerDocument->setDocumentElement($wrapped);
		}
		else
		{
			$math->replaceNode($wrapped);
		}
	}
	_optimizePaths($doc);
}

sub wrapForXHTML($;%)
{
	my $self=shift;
	my $svgDoc=shift;
	my %opts=@_;
	my $display=$opts{display}//'inline';

	my @viewBox=split /\s+/, $svgDoc->documentElement->getAttribute('viewBox');
	#my $hOffset=0; # -$viewBox[0];
	my $vOffset=($viewBox[3]+$viewBox[1])*$self->{scale}*.1;

	my $divElement=XML::LibXML::Element->new('div');
	$divElement->setNamespace(NS_XHTML, '', 1);
	my $svgRoot=$svgDoc->documentElement;
	$svgRoot->setAttribute('width', sprintf('%.5fem', $viewBox[2]*$self->{scale}*.1));
	$svgRoot->setAttribute('height', sprintf('%.5fem', $viewBox[3]*$self->{scale}*.1));
	$divElement->appendChild($svgRoot);

	my %css=($display eq 'block')?
		(
			'display'=>'block',
			'margin-top'=>sprintf('%.5fem', 1.2*$self->{scale}),
			'margin-bottom'=>sprintf('%.5fem', 1.2*$self->{scale}),
			'text-align'=>'center',
		):
		(
			'display'=>'inline-block',
			'position'=>'relative',
			'bottom'=>sprintf('%.5fem', -$vOffset),
			'margin-top'=>sprintf('%.5fem', -$vOffset),
			'margin-bottom'=>sprintf('%.5fem', $vOffset),
		);
	my $css;
	$css.="$_: $css{$_}; " for sort keys %css;
	chop $css;

	$divElement->setAttribute('style', $css);
	$divElement->setAttribute('class', 'ltxsvg-'.($display? 'display': 'math'));

	return $divElement;
}

sub wrapForSVG($;%)
{
	my $self=shift;
	my $svgDoc=shift;
	my %opts=@_;
	my $display=$opts{display}//'inline';

	my @viewBox=split /\s+/, $svgDoc->documentElement->getAttribute('viewBox');
	my $width=$viewBox[2]*$self->{scale};
	my $height=$viewBox[3]*$self->{scale};

	my $svgRoot=$svgDoc->documentElement;
	$svgRoot->setAttribute('width', $width);
	$svgRoot->setAttribute('height', $height);

	#$svgRoot->setNodeName('g');
	if($opts{placement})
	{
		my $gap=($opts{gap}//3)*$self->{scale};
		my ($x, $y);
		if($opts{placement} eq 'bottom')
		{
			($x, $y)=($opts{x}-$width/2, $opts{y}+$gap);
		}
		elsif($opts{placement} eq 'top')
		{
			($x, $y)=($opts{x}-$width/2, $opts{y}-$height-$gap);
		}
		elsif($opts{placement} eq 'left')
		{
			($x, $y)=($opts{x}-$width-$gap, $opts{y}-$height/2);
		}
		elsif($opts{placement} eq 'right')
		{
			($x, $y)=($opts{x}+$gap, $opts{y}-$height/2);
		}
		elsif($opts{placement} eq 'topRight')
		{
			($x, $y)=($opts{x}+$gap/SQRT2, $opts{y}-$height-$gap/SQRT2);
		}
		elsif($opts{placement} eq 'topLeft')
		{
			($x, $y)=($opts{x}-$width-$gap/SQRT2, $opts{y}-$height-$gap/SQRT2);
		}
		elsif($opts{placement} eq 'bottomLeft')
		{
			($x, $y)=($opts{x}-$width-$gap/SQRT2, $opts{y}+$gap/SQRT2);
		}
		elsif($opts{placement} eq 'bottomRight')
		{
			($x, $y)=($opts{x}+$gap/SQRT2, $opts{y}+$gap/SQRT2);
		}
		elsif($opts{placement} eq 'center')
		{
			($x, $y)=($opts{x}-$width/2, $opts{y}-$height/2);
		}
		else
		{
			($x, $y)=@opts{qw/x y/};
		}
		$svgRoot->setAttribute('x', $x);
		$svgRoot->setAttribute('y', $y);
	}
	return $svgRoot;
}

sub clearCache()
{
	unlink glob(CACHE_DIR."/*$_") for qw/.log .aux .tex .dvi .svg/;
}

sub _generateId
{
	state $n=0;
	return 'ltxsvg-'.++$n;
}

return 1;

__END__

=pod

=head1 NAME

LTXSVG - convert LaTeX formulae to SVG documents

=head1 SYNOPSIS

	use LTXSVG;

	my $ltxsvg=LTXSVG->new;
	my $svgdom=$ltxsvg->makeSVG('\frac{\pi^2}6=\sum_{k=1}^\infty k^{-2}', display=>'block');
	print $svgdom->toString;

=head1 DESCRIPTION

The B<LTXSVG> package allows to convert LaTeX formulae to SVG images.

B<LTXSVG> converter creates a TeX source document for each formula, translates
it to DVI format and converts the resulting DVI document to SVG format by
dvisvgm(1) program.

=head1 API

=over

=item LTXSVG-E<gt>B<new>(I<%options>)

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
	\begin{document}

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

=item I<$ltxsvg>-E<gt>B<makeSVG>(I<$formula>, [I<%options>])

Returns an L<XML::LibXML::Document(3pm)> object containing the SVG rendering of
the given I<$formula>. The I<%options> hash contains the options controlling
the rendering, valid options are:

=over

=item B<dislpay>

When true, the formula is rendered as display block.

=item B<x>, B<y> (SVG context)

The coordinates of the formula reference point.

=item B<placement> (SVG context)

This attribute specifies the reference point position in the rendered formula.
Valid values are:

=over

=item B<"right">

in the middle of the left edge.

=item B<"topRight">

in the lower left corner.

=item B<"top">

in the middle of the upper edge.

=item B<"topLeft">

in the lower right corner.

=item B<"left">

in the middle of the right edge.

=item B<"bottomLeft">

in the upper right corner.

=item B<"bottom">

in the middle of the upper edge.

=item B<"bottomRight">

in the upper left corner.

=back

=item B<gap> (SVG context)

The additional gap between the formula and the reference point. The default
value is B<"3">.

=item I<$ltxsvg>-E<gt>B<processDocument>(I<$document>)

Takes an L<XML::LibXML::Document(3pm)> instance and replaces all the
occurrences of formulae with their SVG renderings.

=item I<$ltxsvg>-E<gt>B<processFile>(I<$in>, [I<$out>])



=item I<$ltxsvg>-E<gt>B<clearCache>

Clears the cache directory.

=back

=back

=head1 FILES

=over

=item B<~/.ltxsvg-cache>

The cache directory.

=back

=head1 SEE ALSO

L<latex(1)>, L<dvisvgm(1)>, L<ltxsvg(1)>.

Project site: L<https://github.com/urbic/ltxsvg>.

=head1 LICENSE

zlib/png.

=head1 AUTHOR

Anton Shvetz, L<mailto:tz@sectorb.msk.ru>.

=cut
