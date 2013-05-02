#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use autodie;

use Test::More;

use_ok('WebService::Moodscope');

my $test = WebService::Moodscope->new(
    url => 'http://example.com/',
);

isa_ok($test, 'WebService::Moodscope');

done_testing();
