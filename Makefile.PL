use inc::Module::Install;

# Define metadata
name			'ltxsvg';
version_from	'lib/LTXSVG.pm';
license			'Zlib/png';

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

#test_requires  'Test::More'  => '0.42';
#recommends     'Text::CSV_XS'=> '0.50';
#no_index       'directory'   => 'demos';
install_script	'bin/ltxsvg';

WriteAll;
