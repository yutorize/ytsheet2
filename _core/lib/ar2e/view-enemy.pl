################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_class;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'Arianrhod2Enemy',
  nameKeys          => [qw/enemyName/],
  unescapeLinesKeys => [qw/skills description/],
  unescapeSkipRe    => qr/^image|URL$/,
  groups            => \@set::groups_enemy,
  updateSub => \&upgradeEnemyData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{enemyName} = noiseText(6,14);
    $pc->{group} = $pc->{areaTags} = $pc->{tags} = '';

    $pc->{description} = '';
    foreach(1..int(rand 5)+4){
      $pc->{description} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }

  $pc->{isMob} = 0;

  $pc->{taxon}   = noiseText(2,10);
  $pc->{race}    = '';
  $pc->{element} = noiseText(1);
  $pc->{level}   = noiseText(1,3);
  $pc->{identifyTarget} = noiseText(1);
  
  foreach my $key (qw/Str Dex Agi Int Sen Mnd Luk/) {
    $pc->{"stt${key}Base"} = noiseText(1);
    $pc->{"stt$key"} = noiseText(1);
  }
  $pc->{dodge} = noiseText(1);
  $pc->{armorP} = noiseText(1);
  $pc->{armorM} = noiseText(1);
  $pc->{hp} = noiseText(1,2);
  $pc->{mp} = noiseText(1,2);
  $pc->{initiative} = noiseText(1);
  $pc->{mobility} = noiseText(1);

  $pc->{attackNum} = 1;
  foreach my $n (1..$pc->{attackNum}){
    $pc->{"attack${n}Name"} = noiseText(5,12);
    $pc->{"attack${n}Acc"}     = noiseText(1);
    $pc->{"attack${n}AccDice"} = noiseText(1);
    $pc->{"attack${n}Dmg"}     = noiseText(1);
    $pc->{"attack${n}DmgDice"} = noiseText(1);
    $pc->{"attack${n}Type"}    = noiseText(2);
    $pc->{"attack${n}DmgType"} = noiseText(2,4);
    $pc->{"attack${n}Range"} = noiseText(2,3);
  }

  $pc->{skills} = '';
  foreach(1..int(rand 5)+4){
    $pc->{skills} .= '　'.noiseText(18,40)."<br>";
  }

  $pc->{lootNum} = 3;
  foreach my $n (1..$pc->{lootNum}){
    $pc->{"loot${n}Num"}  = noiseText(1).'～'.noiseText(1);
    $pc->{"loot${n}Item"} = noiseText(5,14);
  }

  $pc->{skills} = '';
  foreach(1..int(rand 5)+4){
    $pc->{skills} .= '　'.noiseText(5,20)."<br>";
  }

  $pc->{historyNum} = 0;
  $pc->{historyExpTotal} = noiseText(1,3);
}

### 攻撃 --------------------------------------------------
{
  my @row;
  my @fields = qw/Name Acc AccDice Dmg DmgDice Type DmgType Range/;
  foreach my $n (1..$pc{attackNum}){
    next if (!existsRow "attack${n}", @fields);
    my %print = fieldsToHash("attack${n}", @fields);
    push(@row, \%print);
  }
  $SHEET->param(Attacks => \@row);
}

### ドロップ品 --------------------------------------------------
{
  my @row;
  my @fields = qw/Num Item/;
  foreach my $n (1..$pc{lootNum}){
    next if (!existsRow "loot${n}", @fields);
    my %print = fieldsToHash("loot${n}", @fields);
    push(@row, \%print);
  }
  $SHEET->param(Loot => \@row);
}

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags(
  "分類：$pc{taxon}" . ($pc{race}?"（$pc{race}）":'')
  . "　属性：$pc{element}"
  . "　レベル:$pc{level}" . ($pc{isMob}?"（モブ）":'')
));

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
