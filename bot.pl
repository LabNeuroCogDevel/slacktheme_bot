#!/usr/bin/env perl
use strict; use warnings; use feature qw/say signatures/;
no warnings qw/experimental::signatures/;
#
# * get a gipphy theme url
# * pick a user's name from a list based on the day
# * send messages to slack user and/or channel
#
# default:
#   send theme to user
#   send user to random
# see cron
#   00 17 * * 1,2,3,4,5 bot.pl default
# 
# depends on system running `shuf`, `curl`, and `jq`
#
# posts json to https://slack.com/api/chat.postMessage to send message
# WebService::Slack::WebApi is a heavy depend to run auth and send message

# 20200925WF - init. send a giphy to 'random'
# 20200929WF - send a reminder to a person for them to set a theme.
# 20201007WF - handle different arguments
# 20210219WF - library




package main;
use Data::Dumper;
use File::Slurp;
use FindBin;
use Time::Piece;
use JSON::PP;
use FindBin; use lib $FindBin::Bin . '/lib';
use Slack;
use GiphyTheme;
# auth info and themes are all in the script directory
chdir $FindBin::Bin;

sub date_idx {
   # index days of the year skipping weekends
   # weirdness around weekends: sat reports same as thursday, sun same as friday
   my $ymd = shift;
   my $dt = $ymd?Time::Piece->strptime($ymd,"%Y-%m-%d"):Time::Piece->new();
   return($dt->yday - $dt->week*2);
}

sub holidays($holiday_fname="holiday_doy.txt"){
  return () if not -s $holiday_fname;
  my @holidays = grep {/^\d/} map {s/[^0-9].*//g;$_} read_file($holiday_fname, chomp=>1);
}

sub is_holiday($date_idx=date_idx()){
   my @h = holidays();
   for my $h (@h){
      return 1 if $h == $date_idx;
   }
   return 0;
}

sub holiday_offset($doy){
  my $offset=0;
  my @holiday_doy = holidays();
  ++$offset while($offset <= $#holiday_doy and $doy >= $holiday_doy[$offset]);
  return($offset)
}

sub get_setter($doy=date_idx()){
  my $offset = holiday_offset($doy);
  my @everyone = read_file('ids.txt', chomp=>1);
  my $setter = $everyone[($doy - $offset) % ($#everyone+1)];
  return $setter;
}

sub pick_person($setter){
   my $giphy_txt = GiphyTheme::giphy_text();
   # my $edit_note = ". Set tomorrow's theme on <https://github.com/LabNeuroCogDevel/slacktheme_bot/edit/master/manual-theme.txt|github>";
   my $slack = Slack->new;
   my $resp = $slack->msg("<$setter> sets the theme next!", 'random');
   $resp = $slack->msg("It's your turn to set the theme next. Here's some insperation: $giphy_txt", $setter);
   return $resp
}
sub send_theme($send_to){
   my $giphy_txt = GiphyTheme::giphy_text();
   # my $edit_note = ". Set tomorrow's theme on <https://github.com/LabNeuroCogDevel/slacktheme_bot/edit/master/manual-theme.txt|github>";
   my $slack = Slack->new;
   my $resp = $slack->msg("$giphy_txt", $send_to);
   return $resp
}

unless(caller){
  my $cmd = $#ARGV>=0?$ARGV[0]:"";
  if($cmd eq "pick") {
     if(is_holiday()){
        say "holiday!";
        exit;
     }
     my $setter = "@".get_setter();
     pick_person($setter);
  }elsif ($cmd =~ m/who/ ){
    say '@'.get_setter();
  } elsif($cmd =~ m/^@|random/){
     send_theme($cmd);
  } elsif($cmd =~ m/^message/){
     die "need a person and message: bot.pl message \@will 'hello'" if $#ARGV!=2;
     my $send_to = $ARGV[1];
     my $message = $ARGV[2];
     my $slack = Slack->new;
     my $resp = $slack->msg($message, $send_to);
     print STDERR "ERROR\n" if JSON::PP->new->encode($resp->{ok}) ne "true";
  } elsif($cmd =~ m/^[-\d]+$/) {
     my $doy = date_idx($cmd);
     my $offset = holiday_offset($doy);
     say get_setter($doy), " # idx=$doy, offset=$offset, holdiday? ", is_holiday($doy);
  } else {
     say "USAGE:
   ./bot.pl pick         pick a setter, send them a message. tell random about it
   ./bot.pl who          say todays setter (e.g. DRYRUN)
   ./bot.pl 2020-10-03   setter on Oct 3rd 2020
   ./bot.pl YYYY-MM-DD   setter on date, also gives index and holiday status
   ./bot.pl \@will        send a random theme to \@will
   ./bot.pl random       send a random theme to the random channel
  ";
  }
}
