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
# 20210412WF - use themes/* for suggestsions (merged lib and theme)
# 20211224WF - exit if holiday on pick (@|random) too
# 20220115WF - holiday for @|random sends holiday message instead of just exiting
# 20230922WF - force old SSL protocol (b/c debian12 bookworm has strict SSL?)
# Cannot create SSL connection: SSL connect attempt failed error:0A000152:SSL routines::unsafe legacy renegotiation disable
# https://www.perlmonks.org/?node_id=11151136
use IO::Socket::SSL;
my $context = new IO::Socket::SSL::SSL_Context(
  SSL_version => 'tlsv12',
  SSL_verify_mode => Net::SSLeay::VERIFY_NONE(),
  );
IO::Socket::SSL::set_default_context($context);
use LWP::UserAgent;

package main;
use Data::Dumper;
use JSON::PP; # 'message' error checking
use FindBin;
chdir $FindBin::Bin; # auth info and themes are all in the script directory
use lib $FindBin::Bin . '/lib';
use Slack;      # object with ->msg()
use GiphyTheme; # giphy_text
use PickSetter qw/holiday_offset date_idx is_holiday get_setter/;

sub pick_person($setter){
   my $giphy_txt = GiphyTheme::giphy_text();
   # my $edit_note = ". Set tomorrow's theme on <https://github.com/LabNeuroCogDevel/slacktheme_bot/edit/master/manual-theme.txt|github>";
   my $slack = Slack->new;
   my $resp = $slack->msg("<$setter> sets the theme next!", 'random');
   $resp = $slack->msg("It's your turn to set the theme next. Here's some insperation: $giphy_txt", $setter);
   return $resp
}


sub send_msg($send_to, $message){
   my $slack = Slack->new;
   my $resp = $slack->msg($message, $send_to);
   print STDERR "ERROR: message sending failed $send_to! ". Dumper($resp)."\n" if JSON::PP->new->encode($resp->{ok}) ne "true";
   return $resp;
}

sub send_theme($send_to){
   my $giphy_txt = GiphyTheme::giphy_text();
   # my $edit_note = ". Set tomorrow's theme on <https://github.com/LabNeuroCogDevel/slacktheme_bot/edit/master/manual-theme.txt|github>";
   return send_msg($send_to, "$giphy_txt");
}
sub exit_holiday() {
   return if not is_holiday();
   say "holiday!";
   exit;
}

unless(caller){
  my $cmd = $#ARGV>=0?$ARGV[0]:"";
  if($cmd eq "pick") {
     exit_holiday();
     my $setter = "@".get_setter();
     pick_person($setter);
  }elsif ($cmd =~ m/^who$/ ){
    say '@'.get_setter();
  } elsif($cmd =~ m/^@|random/){
     if(is_holiday()){
        say "holiday!";
        send_msg($cmd, "Today is a holiday!");
        exit;
     }
     send_theme($cmd);
  } elsif($cmd =~ m/^message/){
     die "need a person and message: bot.pl message \@will 'hello'" if $#ARGV!=2;
     my $send_to = $ARGV[1];
     my $message = $ARGV[2];
     send_msg($send_to, $message)
  } elsif($cmd =~ m/^[-\d]+$/) {
     my $doy = date_idx($cmd);
     my $offset = holiday_offset($doy);
     say get_setter($doy), " # idx=$doy, offset=$offset, holdiday? ", is_holiday($doy);
  } elsif($cmd =~ /^test$/) {
     # run 'prove' (all t/*.t)
     exit system("prove");
  } else {
     say "USAGE:
   ./bot.pl pick         pick a setter, send them a message. tell random about it
   ./bot.pl who          say todays setter (e.g. DRYRUN)
   ./bot.pl 2020-10-03   setter on Oct 3rd 2020
   ./bot.pl YYYY-MM-DD   setter on date, also gives index and holiday status
   ./bot.pl \@will        send a random theme to \@will
   ./bot.pl random       send a random theme to the random channel
   ./bot.pl test         run 'prove' on t/* test files (see ./bot.pl who; ./bot.pl \@will)
  ";
  }
}
