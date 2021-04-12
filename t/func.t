#!/usr/bin/env perl
use strict; use warnings; use feature qq/say/;
use Test2::V0;
use lib 'lib';
use PickSetter qw/get_setter date_idx/;
use GiphyTheme;
# 20210412WF - init
#  integration tests on command line options
ok(get_setter(date_idx('2021-04-12')) =~ /missarm/);

my ($theme_file, $theme) = GiphyTheme::get_theme();
#print("$theme_file: $theme");
ok(-e $theme_file);
ok($theme !~ /^$/);

done_testing;
