use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-BLP #################################################################################

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{'ver'};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($ver < 1.13002){
    ($pc{'characterName'},$pc{'characterNameRuby'}) = split(':', $pc{'characterName'});
    ($pc{'aka'},$pc{'akaRuby'}) = split(':', $pc{'aka'});
  }
  $pc{'ver'} = $main::ver;
  $pc{'lasttimever'} = $ver;
  return %pc;
}

1;