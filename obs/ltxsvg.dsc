Format: 1.0
Source: @NAME@
Version: @VERSION@-0
Binary: ltxsvg
Maintainer: Anton Shvetz <tz@sectorb.msk.ru>
Architecture: all
Build-Depends:
	debhelper (>= 9),
	perl-base (> 5.18.2),
	libmodule-install-perl (>= 1.14),
	libxml-libxml-perl (>= 2.0019),
	libcapture-tiny-perl (>= 0.25),
	liblockfile-simple-perl (>= 0.208),
	texlive-latex-base,
	texlive-latex-extra,
	texlive-fonts-extra,
	texlive-extra-utils
Debtransform-Tar: ltxsvg-1.5.0.tar.gz
Files: 
	00000000000000000000000000000000 0 @NAME@_@VERSION@.orig.tar.gz
	00000000000000000000000000000000 0 @NAME@_@VERSION@-0.diff.tar.gz
