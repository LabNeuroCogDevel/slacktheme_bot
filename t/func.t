#!/usr/bin/env perl
use strict; use warnings; use feature qq/say/;
use Test2::V0;
use lib 'lib';
use PickSetter qw/get_setter date_idx/;
use GiphyTheme;
# 20210412WF - init
# 20210705WF - test index_or_index_from_ymd

# indexing day of year
is(PickSetter::index_or_index_from_ymd('2021-07-05'), 131);
is(PickSetter::index_or_index_from_ymd('131 - july 4 (observed)'), 131);

#  integration tests on command line options
#  TODO: this test will fail after 2021
ok(get_setter(date_idx('2021-04-12')) =~ /missarm/);

my ($theme_file, $theme) = GiphyTheme::get_theme();
#print("$theme_file: $theme");
ok(-e $theme_file);
ok($theme !~ /^$/);

done_testing;
