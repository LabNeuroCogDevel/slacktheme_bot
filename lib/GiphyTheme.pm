use strict; use warnings; no warnings qw/experimental/; use feature qw/say signatures/;
package GiphyTheme;
use File::Slurp;
use URI::Escape;

sub get_theme(){
  # get random line from random file in themes/
  # unless manual-theme.txt has been modified recently
  # then use that

  #system('git pull'); # update maybe
  my $man_fname = "manual-theme.txt";
  my $is_manual = ( -s $man_fname and -M $man_fname < 1);
  my $theme_file = $is_manual ?
     $man_fname :
     qx(find themes/ -type f | shuf -n 1);
  my $theme_note = qx(shuf -n 1 $theme_file);
  chomp($theme_file, $theme_note);
  return($theme_file, $theme_note);
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
   return slack_text($img_url, $theme, "from `$note`: ");
}

1;
