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
  my ($theme_file, $theme_text);
  if($is_manual){
     $theme_file = $man_fname;
     $theme_text = qx(shuf -n 1 $theme_file);
  }else{
     my $theme_file_text = qx(find themes/ -type f | xargs grep '\\s'|shuf -n 1);
     ($theme_file, $theme_text) = split /:/, $theme_file_text;
  }
  chomp($theme_file, $theme_text);
  $theme_file="<https://github.com/LabNeuroCogDevel/slacktheme_bot/blob/master/$theme_file|`$theme_file`>";
  return($theme_file, $theme_text);
}

sub get_giphy($theme){
  chomp(my $giphy_key = read_file('.giphy'));
  my $giphy_search = "https://api.giphy.com/v1/gifs/search?api_key=".
                     "$giphy_key&q=".
                     uri_escape($theme).
                     "&offset=0&limit=10";
  chomp(my $img_url = qx/
     curl -sSkqL "$giphy_search" |
     jq -r '.data[] |
            select(.images.original.size|tonumber| . <= 1000000)|
            select(.images.original.url| match("gif";"i"))|
            .images.original.url' |
     shuf -n1/);
  return $img_url;
}
sub slack_text($img_url, $theme, $prefix="") {
  # prefix previously like "today's theme: "
  my $have_img = $img_url =~ m/http/;
  my $txt = $have_img?"$prefix<$img_url|$theme>": "no giphy for theme *$theme*! :scream:";
  return($txt)
}

sub giphy_text() {
   my ($file, $theme) = get_theme();
   my $img_url = get_giphy($theme);
   return slack_text($img_url, $theme, "from $file: ");
}

1;
