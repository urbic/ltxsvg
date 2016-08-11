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


Name:           ltxsvg
Version:        1.02
Release:        0
%define cpan_name %{name}
Summary:        Perform SVG rendering of the TeX formulae embedded within XML documents
License:        Zlib
Group:          Development/Libraries/Perl
Url:            https://github.com/urbic/ltxsvg
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  perl
BuildRequires:  perl-macros
BuildRequires:  perl(Cwd) >= 3.40
BuildRequires:  perl(Digest::MD5) >= 2.52
BuildRequires:  perl(Encode) >= 2.49
BuildRequires:  perl(File::Basename) >= 2.84
BuildRequires:  perl(IO::CaptureOutput) >= 1.1104
BuildRequires:  perl(IO::Handle) >= 1.34
BuildRequires:  perl(Module::Build) >= 0.380000
BuildRequires:  perl(Software::License) >= 0.103012
BuildRequires:  perl(XML::LibXML) >= 2.0019
BuildRequires:  texlive-pdftex
BuildRequires:  texlive-latex
BuildRequires:  texlive-stix
BuildRequires:  texlive-amsmath
BuildRequires:  texlive-dvisvgm
Requires:       perl(Cwd) >= 3.40
Requires:       perl(Digest::MD5) >= 2.52
Requires:       perl(Encode) >= 2.49
Requires:       perl(File::Basename) >= 2.84
Requires:       perl(IO::CaptureOutput) >= 1.1104
Requires:       perl(IO::Handle) >= 1.34
Requires:       perl(XML::LibXML) >= 2.0019
Requires:  texlive-pdftex
Requires:  texlive-latex
Requires:  texlive-stix
Requires:  texlive-amsmath
Requires:  texlive-dvisvgm
%{perl_requires}

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
%{__perl} Build.PL installdirs=vendor
./Build build flags=%{?_smp_mflags}

%check
./Build test

%install
./Build install destdir=%{buildroot} create_packlist=0
%perl_gen_filelist

%files -f %{name}.files
%defattr(-,root,root,755)
%doc LICENSE README

%changelog
