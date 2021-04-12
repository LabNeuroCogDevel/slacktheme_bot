#!/usr/bin/env perl
use strict; use warnings; use feature qq/say/;
use lib 'lib';
use Test2::V0;
use GiphyTheme;
# 20210412WF - init
ok(GiphyTheme::get_giphy("testme") =~ /http/);
done_testing;
