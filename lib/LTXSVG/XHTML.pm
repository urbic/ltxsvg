package LTXSVG::XHTML;

use base qw/LTXSVG/;

sub convertDocument($)
{
	my $self=shift;
	my $xhtmlDoc=shift;
	for my $math(@{$xhtmlDoc->documentElement->getElementsByTagNameNS(LTXSVG::NS_L2S, 'math')},
			@{$xhtmlDoc->documentElement->getElementsByTagNameNS(LTXSVG::NS_L2S, 'display')})
	{
		my $display=($math->localName eq 'display');
		$math->replaceNode($self->makeWrappedSVG($math->textContent, $display));
	}
	_optimizePaths($xhtmlDoc);
}

sub convertFile($;$)
{
	my $self=shift;
	my $inputName=shift;
	my $outputName=shift;
	my $xhtmlDoc=XML::LibXML->load_xml(location=>$inputName);
	$self->convertDocument($xhtmlDoc);

	if(defined $outputName)
	{
		$xhtmlDoc->toFile($outputName);
	}
	else
	{
		$xhtmlDoc->toFH(STDOUT);
	}
}

sub _optimizePaths($)
{
	my $xhtmlDoc=shift;
	my %pathHash;
	my %pathIdReplacements;

	for my $path(@{$xhtmlDoc->documentElement->getElementsByTagNameNS(LTXSVG::NS_SVG, 'path')})
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

	for my $use(@{$xhtmlDoc->documentElement->getElementsByTagNameNS(LTXSVG::NS_SVG, 'use')})
	{
		my $href=$use->getAttributeNS(LTXSVG::NS_XLINK, 'href');
		next unless $href=~s/^#//;
		if(exists $pathIdReplacements{$href})
		{
			$use->setAttributeNS(LTXSVG::NS_XLINK, 'href', "#$pathIdReplacements{$href}");
		}
		for(qw/x y/)
		{
			my $att=$use->getAttribute($_);
			$use->removeAttribute($_) if defined $att and $att eq '0';
		}
	}
}

sub makeWrappedSVG
{
	my $self=shift;
	my $tex=shift;
	my $display=shift//0;

	my $svgDoc=$self->makeSVG($tex, $display);

	my @viewBox=split /\s+/, $svgDoc->documentElement->getAttribute('viewBox');
	my $hOffset=0; # -$viewBox[0];
	my $vOffset=($viewBox[3]+$viewBox[1])*$self->{scale}*.1;
	my $marginTop=-$vOffset;

	my $divElement=XML::LibXML::Element->new('div');
	$divElement->setNamespace(LTXSVG::NS_XHTML, '', 1);
	my $svgRoot=$svgDoc->documentElement;
	$svgRoot->setAttribute('width', ($viewBox[2]*.1).'em');
	$svgRoot->setAttribute('height', ($viewBox[3]*.1).'em');
	$divElement->appendChild($svgRoot);
	my $css;
	if($display)
	{
		my $displayMargin=1.2*$self->{scale};
		$css=<<__CSS__;
display: block;
margin-top: ${displayMargin}em;
margin-bottom: ${displayMargin}em;
text-align: center;
__CSS__
	}
	else
	{
		$css=<<__CSS__;
display: inline-block;
position: relative;
bottom: ${marginTop}em;
margin-top: ${marginTop}em;
margin-bottom: ${vOffset}em;
__CSS__
	}
	$divElement->setAttribute('style', join ' ', split /\n/, $css);
	$divElement->setAttribute('class', 'ltxsvg-'.($display? 'display': 'math'));

	return $divElement;
}

return 1;
