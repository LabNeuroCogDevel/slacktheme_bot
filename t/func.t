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

my $cur_day = date_idx();
ok($cur_day >= 0);
ok($cur_day <= 365); # leap year
ok(get_setter(date_idx('2000-01-01'), ['a','b']) =~ /a/);
ok(get_setter(date_idx('2000-01-02'), ['a','b']) =~ /b/);
my $cur_setter = get_setter();
ok($cur_setter =~ /^\S+$/);

my ($theme_file, $theme) = GiphyTheme::get_theme();
#print("$theme_file: $theme");
ok(-e $theme_file);
ok($theme !~ /^$/);

done_testing;
