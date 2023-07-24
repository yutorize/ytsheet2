use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-GS ##################################################################################
my %abilityToName = (
  Str => '体力',
  Psy => '魂魄',
  Tec => '技量',
  Int => '知力',
  Foc => '集中',
  Edu => '持久',
  Ref => '反射',
);
sub abilityToName {
  my $text = shift;
  $text =~ s/$_/$abilityToName{$_}/i foreach (keys %abilityToName);
  return $text;
}
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

1;