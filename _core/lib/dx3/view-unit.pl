################## ユニット表示 ##################
use strict;
use utf8;
use open ":utf8";

### データ／テンプレート読込 #########################################################################
my ($pcRef, $SHEET) = setupViewBase(
  nameKeys => [qw/unitName/],
  unescapeLinesKeys => [qw/freeNote/],
  keepHeadings => 1,
  updateSub => \&upgradeUnitData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  if($forbidden ne 'battle'){
    $pc->{unitName} = noiseText(6,14);
    $pc->{unitNameRuby} = $pc->{tags} = $pc->{freeNote} = '';
    $pc->{memberNum} = 0;
  }
  $pc->{orderNum} = 0;
}

### 種別 --------------------------------------------------
$SHEET->param('is'.ucfirst($pc{sheetSubType}) => 1);

### メンバー --------------------------------------------------
my @members;
{
  my @fields = qw/Name Belong Timing Note Leader Left/;
  foreach my $n (1 .. $pc{memberNum}){
    next unless existsRow "member$n", @fields;
    my %print;
    $print{uc $_} = $pc{"member${n}$_"} for @fields;

    my $url = $pc{"member${n}URL"};
    if($print{NAME} && $url =~ m{^https?://}i){
      $print{NAME} = qq|<a href="$url">$print{NAME}</a>|;
    }
    push @members, \%print;
  }
  $SHEET->param(Members => \@members);
}

### ユニットオーダー --------------------------------------------------
{
  my @rows;
  my @fields = qw/Name Organization Timing Note/;
  foreach my $n (1 .. $pc{orderNum}){
    next unless existsRow "order$n", 'Name','Organization','Timing','Note';
    my %print;
    $print{uc $_} = $pc{"order${n}$_"} for @fields;
    $print{TIMING} = renderTiming($print{TIMING});
    push @rows, \%print;
  }
  $SHEET->param(Orders => \@rows);
}
sub renderTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(オート|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  return $text;
}

### カンパニー規模 --------------------------------------------------
{
  my %companySize2Name = (
    1 => 'パーソナル',
    2 => 'ごく小規模',
    3 => '小規模',
    4 => '中規模',
    5 => '大規模',
    6 => '超大規模',
  );
  $SHEET->param(companySize => $companySize2Name{$pc{companySize}} // $pc{companySize});
}
### カンパニー追加施設 --------------------------------------------------
{
  my @rows;
  my @fields = qw/Name Exp Slot Note/;
  foreach my $n (1 .. $pc{facilityNum}){
    next unless existsRow "facility$n", @fields;
    my %print;
    $print{uc $_} = $pc{"facility${n}$_"} for @fields;
    push @rows, \%print;
  }
  $SHEET->param(Facilities => \@rows);
}

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "メンバー:".join('／', map { $_->{NAME} } @members));

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
