use strict; use warnings; use feature qw/say signatures/;
no warnings qw/experimental::signatures/;
package PickSetter;
use File::Slurp;
use Time::Piece;

use Exporter; 
our @EXPORT_OK=qw/date_idx holiday_offset is_holiday get_setter/;
our @ISA = qw(Exporter);

sub date_idx {
   # index days of the year skipping weekends
   # weirdness around weekends: sat reports same as thursday, sun same as friday
   my $ymd = shift;
   my $dt = $ymd?Time::Piece->strptime($ymd,"%Y-%m-%d"):Time::Piece->new();
   return($dt->yday - $dt->week*2);
}

sub index_or_index_from_ymd($i_or_ymd) {
   # match yyyy-mm-dd and get year index OR
   # clear any non-numeric values and assume it's already a day of year index
   # used to read in $holiday_fname in holidays()
   return $i_or_ymd =~ /^\d{4}-\d{2}-\d{2}/ ? date_idx($&) : $i_or_ymd =~ s/[^0-9].*//rg;
}

sub holidays($holiday_fname="holiday_doy.txt"){
  return () if not -s $holiday_fname;
  my @holidays = grep {/^\d/} map {index_or_index_from_ymd($_)} read_file($holiday_fname, chomp=>1);
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

sub get_setter($doy=date_idx(), $everyone=[read_file('ids.txt', chomp=>1)]){
  my $offset = holiday_offset($doy);
  my @everyone = @$everyone;
  my $setter = $everyone[($doy - $offset) % ($#everyone+1)];
  return $setter;
}

1;
