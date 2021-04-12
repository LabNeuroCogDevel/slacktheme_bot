use strict; use warnings; no warnings qw/experimental/; use feature qw/say signatures/;
package GiphyTheme;
use File::Slurp;
use URI::Escape;

sub get_theme(){
   #system('git pull'); # update maybe
  my $man_fname = "manual-theme.txt";
  my $is_manual = ( -s $man_fname and -M $man_fname < 1);
  
  my $theme = $is_manual ? qx/sed 1q $man_fname/ : qx/shuf -n 1 theme_list.txt/;
  my $theme_note = $is_manual ? "manual" : "automatic";
  chomp($theme);
  return($theme_note, $theme);
}

sub get_giphy($theme){
  chomp(my $giphy_key = read_file('.giphy'));
  my $giphy_search = "https://api.giphy.com/v1/gifs/search?api_key=".
                     "$giphy_key&q=".
                     uri_escape($theme).
                     "&offset=0&limit=10";
  chomp(my $img_url = qx/
     curl -qL "$giphy_search" |
     jq -r '.data[] |
            select(.images.original.size|tonumber| . <= 1000000)|
            select(.images.original.url| match("gif";"i"))|
            .images.original.url' |
     shuf -n1/);
  return $img_url;
}
sub slack_text($img_url, $theme, $prefix="") {
  # prefix previously like "today's note theme: "
  my $have_img = $img_url =~ m/http/;
  my $txt = $have_img?"$prefix<$img_url|$theme>": "no giphy for *$theme*! :scream:";
  return($txt)
}

sub giphy_text() {
   my ($note, $theme) = get_theme();
   my $img_url = get_giphy($theme);
   return slack_text($img_url, $theme);
}


package Slack;
use WebService::Slack::WebApi;
use File::Slurp;
sub slack_login() {
   chomp(my $slack_token = read_file('.oauth'));
   my $slack = WebService::Slack::WebApi->new(token => $slack_token) or die "no slack! $!";
   return($slack);
}

use Class::Tiny { auth => sub {slack_login} };
sub msg($self, $txt, $to="random") {
    # to can be a person (e.g. @name) or channel (e.g. random)
    # posting message to specified channel and getting message description
    my $posted_message = $self->auth->chat->post_message(
         channel  => $to,
         text     => "$txt",
         link_names=>1,
    );
    return($posted_message);
}

1;
