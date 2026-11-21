################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み #############################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'SwordWorld2Enemy',
  unescapeLinesKeys => ['description'],
  unescapeLinesRe => qr/^(?:item[0-9]+_)?effects$/,
  nameSub => sub {
    my ($pc) = @_;
    $pc->{titleName} = itemSheetName($pc);
    $pc->{encodedNameLetter} = $pc->{pageTitle} // '';
    foreach my $num (1 .. itemDataCount($pc)){
      my $prefix = itemDataPrefix($num);
      $pc->{encodedNameLetter} .= $pc->{"${prefix}itemName"}.$pc->{"${prefix}itemNameRuby"};
    }
  },
  updateSub => \&upgradeItemData,
);
our %pc = %{ $pcRef };
$SHEET->param(modeZero => $::SW2_0 ? 1 : 0);

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  if($forbidden ne 'battle'){
    $pc->{tags} = '';
    $pc->{pageTitle} = '';
  }
  
  foreach my $num (1 .. itemDataCount($pc)){
    my $prefix = itemDataPrefix($num);
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
my @items = map { renderItemData(itemDataPrefix($_)) } 1 .. itemDataCount(\%pc);
$SHEET->param(Items => \@items);
if(@items > 1){
  $SHEET->param(multipleItems => 1);
  $SHEET->param(itemPageTitle => renderCharacterName(itemSheetName(\%pc)));
}

sub renderItemData {
  my ($prefix) = @_;
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
    PRICE        => $price,
    ICON         => unescapeTags($icon),
    CATEGORY     => $category,
    REPUTATION   => $pc{"${prefix}reputation"},
    SHAPE        => $pc{"${prefix}shape"},
    AGE          => $pc{"${prefix}age"},
    SUMMARY      => $pc{"${prefix}summary"},
    EFFECTS      => renderItemEffects($pc{"${prefix}effects"}),
    HEAD_EFFECTS => $pc{"head_${prefix}effects"},
    WeaponData   => $pc{forbiddenMode} ? [] : renderItemWeapons($prefix),
    ArmourData   => $pc{forbiddenMode} ? [] : renderItemArmours($prefix),
  };
}

### 武器 --------------------------------------------------
sub renderItemWeapons {
  my ($prefix) = @_;
  my @weapons;
  my $isRanged = $pc{"${prefix}category"} =~ /投擲|ボウ|クロスボウ|ガン/;
  foreach my $num (1 .. $pc{"${prefix}weaponNum"}){
    my $row = "${prefix}weapon$num";
    next if !existsRow $row,'Usage','Reqd','Acc','Rate','Crit','Dmg','Note';
    push(@weapons, {
      USAGE => $pc{"${row}Usage"},
      REQD  => $pc{"${row}Reqd"},
      ACC   => $pc{"${row}Acc"} // '―',
      RATE  => $pc{"${row}Rate"},
      CRIT  => $pc{"${row}Crit"},
      DMG   => $pc{"${row}Dmg"} // '―',
      RANGE => $isRanged ? $pc{"${row}Range"} : undef,
      NOTE  => $pc{"${row}Note"},
    });
  }
  return \@weapons;
}

### 防具 --------------------------------------------------
sub renderItemArmours {
  my ($prefix) = @_;
  my @armours;
  foreach my $num (1 .. $pc{"${prefix}armourNum"}){
    my $row = "${prefix}armour$num";
    next if !existsRow $row,'Usage','Reqd','Eva','Def','Note';
    push(@armours, {
      USAGE => $pc{"${row}Usage"},
      REQD  => $pc{"${row}Reqd"},
      EVA   => $pc{"${row}Eva"} // '―',
      DEF   => $pc{"${row}Def"} // 0,
      NOTE  => $pc{"${row}Note"},
    });
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
