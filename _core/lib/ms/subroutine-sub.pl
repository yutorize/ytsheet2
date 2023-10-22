use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-KIZ #################################################################################

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  delete $pc{updateMessage};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

### バージョンアップデート・クラン --------------------------------------------------
sub data_update_clan {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  delete $pc{updateMessage};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($ver < 1.24002){
    if($pc{magi1Name} eq 'スクランブル！' && $pc{magi1Cond} eq '7～12'){
      $pc{magi1Cond} = '8～12'
    }
  }
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

1;