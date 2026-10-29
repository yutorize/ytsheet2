################## ユニット表示 ##################
use strict;
use utf8;
use open ":utf8";

### データ／テンプレート読込 #########################################################################
my ($pcRef, $SHEET) = setupViewBase(
  nameKeys => [qw/unitName/],
  unescapeLinesKeys => [qw/freeNote/],
  keepHeadings => 1,
  groups => \@set::groups_unit,
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

    $pc->{memberNum} = 5;
    foreach my $n (1..$pc->{memberNum}){
      $pc->{"member${n}Name"}   = noiseText(5,10);
      $pc->{"member${n}Belong"} = noiseText(3);
      $pc->{"member${n}Note"}   = noiseText(6,14);
      $pc->{"member${n}Leader"} = 0;
      $pc->{"member${n}Left"}   = 0;
    }
  }
  $pc->{orderNum} = 6;
  foreach my $n (1..$pc->{orderNum}){
    $pc->{"order${n}Name"}   = noiseText(4,8);
    $pc->{"order${n}Organization"} = noiseText(3);
    $pc->{"order${n}Timing"} = noiseText(3,6);
    $pc->{"order${n}Note"}   = noiseText(6,14);
  }

  $pc->{"companySize"} = noiseText(3,5);
  $pc->{"companySlot"} = noiseText(1);
  $pc->{"companySlotEx"} = noiseText(1);
  $pc->{"companySlotUsed"} = noiseText(1);
  $pc->{"companyExp"}  = noiseText(1);
  $pc->{"companyExpUsed"}  = noiseText(1);
  $pc->{"exteriorName"}   = noiseText(3,8);
  $pc->{"exteriorSaving"} = noiseText(1);
  $pc->{"exteriorExp"}    = noiseText(1);
  $pc->{"exteriorNote"}   = noiseText(6,20);
  $pc->{facilityNum} = 6;
  foreach my $n (1..$pc->{facilityNum}){
    $pc->{"facility${n}Name"} = noiseText(4,10);
    $pc->{"facility${n}Exp"}  = noiseText(1);
    $pc->{"facility${n}Slot"} = noiseText(1);
    $pc->{"facility${n}Note"} = noiseText(6,14);
  }
}

### 種別 --------------------------------------------------
$SHEET->param('is'.ucfirst($pc{sheetSubType}) => 1);

### メンバー --------------------------------------------------
my @members;
{
  my @fields = qw/Name Belong Note Leader Left/;
  foreach my $n (1 .. $pc{memberNum}){
    next unless existsRow "member$n", @fields;
    my %print;
    $print{uc $_} = $pc{"member${n}$_"} for @fields;

    my $url = $pc{"member${n}URL"};
    if($print{NAME} && $url =~ m{^https?://}i){
      $print{NAME} =~ s{</?a\b[^>]*>}{}gi;
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
