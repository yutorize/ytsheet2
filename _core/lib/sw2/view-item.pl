################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み #############################################################################
my $records = itemRecordList();
my $itemNumber;
(my $pcRef, my $SHEET) = setupViewBase(
  unescapeLinesKeys => ['description'],
  unescapeLinesRe => qr/^(?:item[0-9]+_)?effects$/,
  nameSub => sub {
    my ($pc) = @_;
    # 全体が非公開の場合は、番号の有効・無効から件数が分からないようにする。
    if(defined $::in{item} && !($pc->{forbiddenMode} && $pc->{forbidden} eq 'all')){
      my ($item, $message) = selectItemData($pc, $::in{item});
      error($message) if !$item;
      %$pc = %$item;
      $itemNumber = $::in{item};
    }
    $pc->{titleName} = itemSheetName($pc);
    $pc->{encodedNameLetter} = $pc->{pageTitle} // '';
    foreach my $prefix ($records->prefixes($pc)){
      $pc->{encodedNameLetter} .= $pc->{"${prefix}itemName"}.$pc->{"${prefix}itemNameRuby"};
    }
  },
  updateSub => \&upgradeItemData,
);
our %pc = %{ $pcRef };

$SHEET->param(
  modeZero => $::SW2_0 ? 1 : 0,
  itemNumber => $itemNumber,
);
setRecordViewParams($SHEET, $records->key, $itemNumber, $pc{itemName});

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  if($forbidden ne 'battle'){
    $pc->{tags} = '';
    $pc->{pageTitle} = '';
  }
  
  foreach my $prefix ($records->prefixes($pc)){
    $pc->{"${prefix}itemName"}   = noiseText(6,14) if $forbidden ne 'battle';
    $pc->{"${prefix}price"}      = noiseText(1,8);
    $pc->{"${prefix}reputation"} = noiseText(2,3);
    $pc->{"${prefix}shape"}      = noiseText(8,20);
    $pc->{"${prefix}category"}   = noiseText(2,8);
    $pc->{"${prefix}age"}        = noiseText(2,6);
    $pc->{"${prefix}summary"}    = noiseText(8,28);

    my $effects = '';
    foreach(1..int(rand 4)+1){
      $effects .= noiseText(6,18)."<br>";
      $effects .= '　'.noiseText(18,40)."<br>";
      $effects .= '　'.noiseText(18,40)."<br>" if(int rand 2);
      $effects .= "<br>";
    }
    $pc->{"${prefix}effects"} = $effects;
    delete $pc->{"head_${prefix}effects"};
  }
}

### アイテムデータ --------------------------------------------------
my @numbers = $records->order(\%pc);
my $multipleItems = @numbers > 1;
my $singleViewQuery;

if($multipleItems){
  $SHEET->param(multipleItems => 1);
  $SHEET->param(itemPageTitle => renderCharacterName(itemSheetName(\%pc)));

  $singleViewQuery = recordSheetURL() if !$pc{modeDownload};
}
my @items = map {
  my $number = $multipleItems ? $numbers[$_] : undef;
  renderItemData($records->prefix($_ + 1), $number, $singleViewQuery);
} 0 .. $#numbers;
$SHEET->param(Items => \@items);

sub renderItemData {
  my ($prefix, $number, $query) = @_;
  my $price = $pc{"${prefix}price"};
  $price = commify($price) if $price =~ /\d{4,}/;
  my $category = $pc{"${prefix}category"} =~ s/((?:\G|>)[^<]*?)[ 　]/$1<hr>/gr;
  my $icon;
  if($pc{"${prefix}iconMagic"  }){ $icon .= '[魔]' }
  if($pc{"${prefix}iconLocal"  }){ $icon .= '[特]' }
  if($pc{"${prefix}iconSchool" }){ $icon .= '[流]' }
  if($pc{"${prefix}iconSchoolA"}){ $icon .= '[ア]' }
  if($pc{"${prefix}iconSchoolT"}){ $icon .= '[テ]' }

  return {
    NAME         => renderCharacterName($pc{"${prefix}itemName"}, $pc{"${prefix}itemNameRuby"}),
    TOC_NAME     => (removeTags removeRuby ($pc{"${prefix}itemName"} // '')),
    PRICE        => $price,
    ICON         => unescapeTags($icon),
    CATEGORY     => $category,
    fieldsToHash($prefix, qw/reputation shape age summary/),
    EFFECTS      => renderItemEffects($pc{"${prefix}effects"}),
    HEAD_EFFECTS => $pc{"head_${prefix}effects"},
    WeaponData   => $pc{forbiddenMode} ? [] : renderItemWeapons($prefix),
    ArmourData   => $pc{forbiddenMode} ? [] : renderItemArmours($prefix),
    NUMBER       => $number,
    SINGLE_VIEW_URL => defined($query) ? "$query&item=$number" : undef,
  };
}

### 武器 --------------------------------------------------
sub renderItemWeapons {
  my ($prefix) = @_;
  my @weapons;
  my @fields = qw/Usage Reqd Acc Rate Crit Dmg Note/;
  my $isRanged = $pc{"${prefix}category"} =~ /投擲|ボウ|クロスボウ|ガン/;
  foreach my $num (1 .. $pc{"${prefix}weaponNum"}){
    my $row = "${prefix}weapon$num";
    next if !existsRow($row, @fields);
    my %weapon = fieldsToHash($row, @fields);
    $weapon{ACC} //= '―';
    $weapon{DMG} //= '―';
    $weapon{RANGE} = $isRanged ? $pc{"${row}Range"} : undef;
    push(@weapons, \%weapon);
  }
  return \@weapons;
}

### 防具 --------------------------------------------------
sub renderItemArmours {
  my ($prefix) = @_;
  my @armours;
  my @fields = qw/Usage Reqd Eva Def Note/;
  foreach my $num (1 .. $pc{"${prefix}armourNum"}){
    my $row = "${prefix}armour$num";
    next if !existsRow($row, @fields);
    my %armour = fieldsToHash($row, @fields);
    $armour{EVA} //= '―';
    $armour{DEF} //= 0;
    push(@armours, \%armour);
  }
  return \@armours;
}

### 効果 --------------------------------------------------
sub renderItemEffects {
  my ($effects) = @_;
  $effects =~ s/<br>/\n/gi;
  $effects =~ s#(<p>|</p>|</details>)#$1\n#gi;
  $effects =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
  $effects = checkSkillName($effects);
  $effects =~ s/^((?:<i class="s-icon [a-z0]+?">.+?<\/i>)+.*?)(　|$)/<\/p><h5>$1<\/h5><p>$2/gim;
  $effects =~ s/\n+<\/p>/<\/p>/gi;
  $effects =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
  $effects = "<p>$effects</p>";
  $effects =~ s#(</p>|</details>)\n#$1#gi;
  $effects =~ s/<p><\/p>//gi;
  $effects =~ s#<h2>(.+?)</h2>#</dd><dt>$1</dt><dd class="box">#gi;
  $effects =~ s/\n/<br>/gi;
  return $effects;
}

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "カテゴリ:$items[0]{CATEGORY}　形状:$pc{shape}　製作時期:$pc{age}　概要:$pc{summary}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
