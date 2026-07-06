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
    { 'HP' => $pc{sttHpTotal}.'/'.$pc{sttHpTotal} },
    { 'MP' => $pc{sttMpTotal}.'/'.$pc{sttMpTotal} },
    { '天運' => $pc{sttFateTotal}.'/'.($pc{sttFateTotal}+3) },
    { '行動値' => $pc{sttInitTotal} },
    { '移動力' => $pc{sttMoveTotal} },
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
  ''  => '「設定・メモ」「履歴（自由記入）」',
  'c' => '「設定・メモ」「履歴（自由記入）」',
);

### バージョンアップデート --------------------------------------------------
sub upgradeData {
  my $data = $_[0];
  my $type = $_[1];
  if   ($type eq 'c'){ return upgradeCountryData($data) }
  else               { return upgradeCharaData($data) }
}
sub upgradeCharaData {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};

  #if($ver < 1.24003){
  #}

  $pc{lasttimever} = $pc{ver};
  $pc{ver} = $main::ver;
  return %pc;
}
sub upgradeCountryData {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};

  #if($ver < 1.24003){
  #}

  $pc{lasttimever} = $pc{ver};
  $pc{ver} = $main::ver;
  return %pc;
}

1;
