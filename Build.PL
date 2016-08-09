#!/usr/bin/perl
use Module::Build;

Module::Build->new
	(
		dist_name=>'LTXSVG',
		dist_version_from=>'lib/LTXSVG.pm',
		dist_author=>'Anton Shvetz <tz@sectorb.msk.ru>',
		abstract_from=>'lib/LTXSVG.pm',
		#release_status=>'unstable',
		license=>'Zlib',
		create_license=>1,
		create_readme=>1,
		requires=>
			{
				'perl'=>'5.18.2',
				'IO::Handle'=>'1.34',
				'XML::LibXML'=>'2.0019',
				'File::Spec'=>'3.40',
				'File::Temp'=>'0.23',
				'File::Basename'=>'2.84',
				'Digest::MD5'=>'2.52',
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
