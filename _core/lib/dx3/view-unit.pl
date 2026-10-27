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

### メンバー --------------------------------------------------
my @members;
foreach my $num (1 .. $pc{memberNum}){
  next unless existsRow "member$num", 'Name','Belong','Note','Leader','URL';
  my $name = $pc{"member${num}Name"};
  my $url = $pc{"member${num}URL"};
  if($name && $url =~ m{^https?://}i){
    $name =~ s{</?a\b[^>]*>}{}gi;
    $name = qq|<a href="$url">$name</a>|;
  }
  push @members, {
    NAME => $name,
    BELONG => $pc{"member${num}Belong"},
    NOTE => $pc{"member${num}Note"},
    LEADER => $pc{"member${num}Leader"},
  };
}
$SHEET->param(Members => \@members);

### ユニットオーダー --------------------------------------------------
my @orders;
foreach my $num (1 .. $pc{orderNum}){
  next unless existsRow "order$num", 'Name','Organization','Timing','Note','Ref';
  push @orders, {
    NAME => $pc{"order${num}Name"},
    ORGANIZATION => $pc{"order${num}Organization"},
    TIMING => $pc{"order${num}Timing"},
    NOTE => $pc{"order${num}Note"},
    REF => $pc{"order${num}Ref"},
  };
}
$SHEET->param(Orders => \@orders);

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "GM:$pc{playerName}　メンバー:".join('／', map { $_->{NAME} } @members));

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
