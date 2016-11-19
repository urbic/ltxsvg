#
# spec file for package ltxsvg
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:			@NAME@
Version:		@VERSION@
Release:		0
Summary:		Perform SVG rendering of the TeX formulae embedded within XML documents
License:		Zlib
Group:			Development/Libraries/Perl
Url:			https://github.com/urbic/ltxsvg
Source0:		%{name}-%{version}.tar.gz
BuildArch:		noarch
BuildRoot:		%{_tmppath}/%{name}-%{version}-build
BuildRequires:	perl >= 5.18.2
BuildRequires:	perl(Capture::Tiny) >= 0.36
BuildRequires:	perl(Cwd) >= 3.40
BuildRequires:	perl(Digest::MD5) >= 2.52
BuildRequires:	perl(Encode) >= 2.49
BuildRequires:	perl(File::Basename) >= 2.84
BuildRequires:	perl(File::Path) >= 2.09
BuildRequires:	perl(File::Copy) >= 2.26
BuildRequires:	perl(IO::Handle) >= 1.34
BuildRequires:	perl(LockFile::Simple) >= 0.208
BuildRequires:	perl(Module::Install) >= 1.16
BuildRequires:	perl(Test::More) >= 0.98
BuildRequires:	perl(XML::LibXML) >= 2.0019
BuildRequires:	perl-macros
BuildRequires:	texlive-amsmath
BuildRequires:	texlive-dvisvgm
BuildRequires:	texlive-latex
BuildRequires:	texlive-pdftex
BuildRequires:	texlive-stix >= 2014
Requires:		perl >= 5.18.2
Requires:		perl(Capture::Tiny) >= 0.36
Requires:		perl(Cwd) >= 3.40
Requires:		perl(Digest::MD5) >= 2.52
Requires:		perl(Encode) >= 2.49
Requires:		perl(File::Basename) >= 2.84
Requires:		perl(File::Path) >= 2.09
Requires:		perl(File::Copy) >= 2.26
Requires:		perl(IO::Handle) >= 1.34
Requires:		perl(LockFile::Simple) >= 0.208
Requires:		perl(XML::LibXML) >= 2.0019
Requires:		texlive-amsmath
Requires:		texlive-dvisvgm
Requires:		texlive-latex
Requires:		texlive-pdftex
Requires:		texlive-stix >= 2014
%if 0%{?fedora}
BuildRequires:	ghostscript-core
BuildRequires:	perl >= 5.18.2
BuildRequires:	perl-generators
BuildRequires:	texlive-collection-latex
Requires:		ghostscript-core
Requires:		perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:		texlive-collection-latex
%else
%{perl_requires}
%endif

%description
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

%prep
%setup -q
find . -type f -print0 | xargs -0 chmod 644

%build
PERL5_CPANPLUS_IS_RUNNING=1 %{__perl} Makefile.PL INSTALLDIRS=vendor NO_PACKLIST=1 NO_PERLLOCAL=1
%{__make} %{?_smp_mflags}

%check
%{__make} test

%if 0%{?fedora}
%install
%{__make} install DESTDIR=%{buildroot}

%files
%defattr(-,root,root,755)
%doc LICENSE README
%{_bindir}/*
%{perl_vendorlib}/*
%{_mandir}/man1/*
%{_mandir}/man3/*
%else
%install
%perl_make_install
%perl_process_packlist
%perl_gen_filelist

%files -f %{name}.files
%defattr(-,root,root,755)
%doc LICENSE README
%endif

%changelog
