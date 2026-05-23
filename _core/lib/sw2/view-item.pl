################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み #############################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'SwordWorld2Enemy',
  unescapeLinesKeys => [qw/effects description/],
  nameKeys => [qw/itemName/],
  updateSub => \&data_update_item,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{itemName}   = noiseText(6,14);
    $pc->{tags} = '';
  }
  
  $pc->{price}      = noiseText(1,8);
  $pc->{reputation} = noiseText(2,3);
  $pc->{shape}      = noiseText(8,20);
  $pc->{category}   = noiseText(2,8);
  $pc->{age}        = noiseText(2,6);
  $pc->{summary}    = noiseText(8,28);
  
  $pc->{effects} = '';
  foreach(1..int(rand 4)+1){
    $pc->{effects} .= noiseText(6,18)."<br>";
    $pc->{effects} .= '　'.noiseText(18,40)."<br>";
    $pc->{effects} .= '　'.noiseText(18,40)."<br>" if(int rand 2);
    $pc->{effects} .= "<br>";
  }
}

### 価格 --------------------------------------------------
$SHEET->param(price => commify $pc{price}) if $pc{price} =~ /\d{4,}/;

### 魔法の武器アイコン --------------------------------------------------
{
  my $icon;
  if($pc{iconMagic  }){ $icon .= '[魔]' }
  if($pc{iconLocal  }){ $icon .= '[特]' }
  if($pc{iconSchool }){ $icon .= '[流]' }
  if($pc{iconSchoolA}){ $icon .= '[ア]' }
  if($pc{iconSchoolT}){ $icon .= '[テ]' }
  $SHEET->param(icon => unescapeTags $icon);
}

### カテゴリ --------------------------------------------------
$pc{category} =~ s/((?:\G|>)[^<]*?)[ 　]/$1<hr>/g;
$SHEET->param(category => $pc{category});

### 武器 --------------------------------------------------
my @weapons;
foreach (1 .. $pc{weaponNum}){
  next if !existsRow "weapon$_",'Usage','Reqd','Acc','Rate','Crit','Dmg','Note';
  push(@weapons, {
    USAGE => $pc{'weapon'.$_.'Usage'},
    REQD  => $pc{'weapon'.$_.'Reqd'},
    ACC   => $pc{'weapon'.$_.'Acc'} // '―',
    RATE  => $pc{'weapon'.$_.'Rate'},
    CRIT  => $pc{'weapon'.$_.'Crit'},
    DMG   => $pc{'weapon'.$_.'Dmg'} // '―',
    RANGE => $pc{category} =~ /投擲|ボウ|クロスボウ|ガン/ ? $pc{'weapon'.$_.'Range'} : undef,
    NOTE  => $pc{'weapon'.$_.'Note'},
  } );
}
$SHEET->param(WeaponData => \@weapons) if !$pc{forbiddenMode};

### 防具 --------------------------------------------------
my @armours;
foreach (1 .. $pc{armourNum}){
  next if !existsRow "armour$_",'Usage','Reqd','Eva','Def','Note';
  push(@armours, {
    USAGE => $pc{'armour'.$_.'Usage'},
    REQD  => $pc{'armour'.$_.'Reqd'},
    EVA   => $pc{'armour'.$_.'Eva'} // '―',
    DEF   => $pc{'armour'.$_.'Def'} // 0,
    NOTE  => $pc{'armour'.$_.'Note'},
  } );
}
$SHEET->param(ArmourData => \@armours) if !$pc{forbiddenMode};

### 効果 --------------------------------------------------
$pc{effects} =~ s/<br>/\n/gi;
$pc{effects} =~ s#(<p>|</p>|</details>)#$1\n#gi;
$pc{effects} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
$pc{effects} = checkSkillName($pc{effects});
$pc{effects} =~ s/^((?:<i class="s-icon [a-z0]+?">.+?<\/i>)+.*?)(　|$)/<\/p><h5>$1<\/h5><p>$2/gim;
$pc{effects} =~ s/\n+<\/p>/<\/p>/gi;
$pc{effects} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
$pc{effects} = "<p>$pc{effects}</p>";
$pc{effects} =~ s#(</p>|</details>)\n#$1#gi;
$pc{effects} =~ s/<p><\/p>//gi;
$pc{effects} =~ s#<h2>(.+?)</h2>#</dd><dt>$1</dt><dd class="box">#gi;
$pc{effects} =~ s/\n/<br>/gi;
$SHEET->param(effects => $pc{effects});

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "カテゴリ:$pc{category}　形状:$pc{shape}　製作時期:$pc{age}　概要:$pc{summary}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
