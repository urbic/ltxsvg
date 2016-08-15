# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Obvious.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More; # tests => 5;
BEGIN { use_ok('LTXSVG') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(my $ltxsvg=LTXSVG->new(clearCache=>1), 'LTXSVG::new');
ok($ltxsvg->makeSVG('\frac12'), 'LTXSVG::makeSVG/latex/math');
ok($ltxsvg->makeSVG('\frac12', display=>'block'), 'LTXSVG::makeSVG/latex/display');

done_testing;
