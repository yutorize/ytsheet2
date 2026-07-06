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
    { 'HP' => $pc{hpTotal}.'/'.$pc{hpTotal} },
    { 'MP' => $pc{mpTotal}.'/'.$pc{mpTotal} },
    { 'フェイト' => $pc{fateTotal}.'/'.$pc{fateTotal} },
    { '行動値' => $pc{battleTotalIni} }
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

### テキスト整形ルール --------------------------------------------------
## 複数行対応覧
our %multilineTargets = (
  ''  => '「容姿・経歴・その他メモ」「履歴（自由記入）」「携帯品・所持品」「収支履歴」',
);

### バージョンアップデート --------------------------------------------------
sub upgradeCharaData {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};
  
  if($ver < 1.24024){
    if($pc{money} =~ /^(?:自動|auto)$/i){ $pc{moneyAuto} = 1; $pc{money} = commify $pc{moneyTotal}; }
  }
  if($ver < 2){
    $pc{skillNum}      //= $pc{skillsNum};
    $pc{geisNum}       //= $pc{geisesNum};
    $pc{connectionNum} //= $pc{connectionsNum};
  }

  $pc{lasttimever} = $pc{ver};
  $pc{ver} = $main::ver;
  return %pc;
}

1;
