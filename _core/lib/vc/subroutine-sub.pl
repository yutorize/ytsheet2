use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-AR ##################################################################################

### ユニットステータス出力 --------------------------------------------------
sub createUnitStatus {
  my %pc = %{$_[0]};
  my @unitStatus = (
    { 'HP' => $pc{hpMax}.'/'.$pc{hpMax} },
    { 'スタミナ' => $pc{staminaMax}.'/'.$pc{staminaMax} },
    { '回避値' => $pc{battleTotalEva} },
    { '物防値' => $pc{battleTotalDef} },
    { '魔防値' => $pc{battleTotalMdf} },
  );
  
  foreach my $key (split ',', $pc{unitStatusNotOutput}){
    @unitStatus = grep { !exists $_->{$key} } @unitStatus;
  }

  foreach my $num (1..$pc{unitStatusNum}){
    next if !$pc{"unitStatus${num}Label"};
    push(@unitStatus, { $pc{"unitStatus${num}Label"} => $pc{"unitStatus${num}Value"} });
  }

  return \@unitStatus;
}

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