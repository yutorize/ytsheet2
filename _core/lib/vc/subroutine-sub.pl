use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-AR ##################################################################################

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};
  
  if($ver < 1.24003){
    $pc{staminaMax} += 5;
    $pc{staminaHalf} = int($pc{staminaMax} / 2);
  }

  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

1;