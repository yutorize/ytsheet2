################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

sub palettePreset {
  my $type = shift;
  my $text;
  ## ＰＣ
  if(!$type){
    $text .= "2d6+{冒険者}+{器用}\n";
    $text .= "2d6+{冒険者}+{敏捷}\n";
    $text .= "2d6+{冒険者}+{筋力}\n";
    $text .= "2d6+{冒険者}+{知力}\n";
    $text .= "2d6+{魔物知識}\n" if $::pc{'monsterLore'};
    $text .= "2d6+{先制力}\n" if $::pc{'initiative'};
    $text .= "2d6+{スカウト技巧}\n" if $::pc{'packScoTec'};
    $text .= "2d6+{スカウト運動}\n" if $::pc{'packScoAgi'};
    $text .= "2d6+{スカウト観察}\n" if $::pc{'packScoObs'};
    $text .= "2d6+{レンジャー技巧}\n" if $::pc{'packRanTec'};
    $text .= "2d6+{レンジャー運動}\n" if $::pc{'packRanAgi'};
    $text .= "2d6+{レンジャー観察}\n" if $::pc{'packRanObs'};
    $text .= "2d6+{セージ知識}\n" if $::pc{'packSagKno'};
    $text .= "2d6+{バード知識}\n" if $::pc{'packBarKno'};
    $text .= "2d6+{ライダー運動}\n" if $::pc{'packRidAgi'};
    $text .= "2d6+{ライダー知識}\n" if $::pc{'packRidKno'};
    $text .= "2d6+{ライダー観察}\n" if $::pc{'packRidObs'};
    $text .= "2d6+{アルケミスト知識}\n" if $::pc{'packAlcKno'};
    $text .= "\n";
    $text .= "2d6+{生命抵抗}\n";
    $text .= "2d6+{精神抵抗}\n";
    $text .= "\n";

    foreach (
      ['Sor', '真語魔法'],
      ['Con', '操霊魔法'],
      ['Pri', '神聖魔法'],
      ['Mag', '魔動機術'],
      ['Fai', '妖精魔法'],
      ['Dem', '召異魔法'],
      ['Gri', '秘奥魔法'],
      ['Bar', '呪歌'],
      ['Alc', '賦術'],
      ['Mys', '占瞳'],
    ){
      next if !$::pc{'lv'.@$_[0]};
      $text .= "2d6+{@$_[1]}\n";
    }
    $text .= "\n";
    foreach (1 .. $::pc{'weaponNum'}){
      next if $::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Usage'}.$::pc{'weapon'.$_.'Reqd'}.
              $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.$::pc{'weapon'.$_.'Crit'}.
              $::pc{'weapon'.$_.'Dmg'}.$::pc{'weapon'.$_.'Own'}.$::pc{'weapon'.$_.'Note'}
              eq '';
      $text .= "2d6+{命中$_} 命中／$::pc{'weapon'.$_.'Name'}\n";
      $text .= "k{威力$_}[{C値$_}]+{追加D$_} ダメージ\n";
      $text .= "\n";
    }
    $text .= "2d6+{回避}\n";
    
    if(1){
      $text .= "\n";
      $text .= "\@HP:{HP}/{HP} MP:{MP}/{MP} 防護:{防護}\n";
    }
  }
  ## 魔物
  elsif($type eq 'm') {
    $text .= "2d6+{生命抵抗}\n";
    $text .= "2d6+{精神抵抗}\n";
    $text .= "\n";

    foreach (1 .. $::pc{'statusNum'}){
      $text .= "2d6+{命中$_} 命中／$::pc{'status'.$_.'Style'}\n" if $::pc{'status'.$_.'Accuracy'} ne '';
      $text .= "{ダメージ$_} ダメージ\n" if $::pc{'status'.$_.'Damage'} ne '';
      $text .= "2d6+{回避$_} 回避\n" if $::pc{'status'.$_.'Evasion'} ne '';
      $text .= "\n";
    }
    my $skills = $::pc{'skills'};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/<br>/\n/gi;
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+?)(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)[(（][0-9]+[）)]/$text .= "2d6+{$1}\n";/megi;
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+)[\/／]([0-9]+)[(（][0-9]+[）)]/$text .= "2d6+{$1}\n";/megi;
  }
  
  return $text;
}

sub palettePresetRaw {
  my $type = shift;
  my $text;
  ## ＰＣ
  if(!$type){
    $text .= "2d6+$::pc{'level'}+$::pc{'bonusDex'} 冒険者＋器用\n";
    $text .= "2d6+$::pc{'level'}+$::pc{'bonusAgi'} 冒険者＋敏捷\n";
    $text .= "2d6+$::pc{'level'}+$::pc{'bonusStr'} 冒険者＋筋力\n";
    $text .= "2d6+$::pc{'level'}+$::pc{'bonusInt'} 冒険者＋知力\n";
    $text .= "2d6+$::pc{'monsterLore'} 魔物知識\n" if $::pc{'monsterLore'};
    $text .= "2d6+$::pc{'initiative'} 先制力\n" if $::pc{'initiative'};
    $text .= "2d6+$::pc{'packScoTec'} スカウト技巧\n" if $::pc{'packScoTec'};
    $text .= "2d6+$::pc{'packScoAgi'} スカウト運動\n" if $::pc{'packScoAgi'};
    $text .= "2d6+$::pc{'packScoObs'} スカウト観察\n" if $::pc{'packScoObs'};
    $text .= "2d6+$::pc{'packRanTec'} レンジャー技巧\n" if $::pc{'packRanTec'};
    $text .= "2d6+$::pc{'packRanAgi'} レンジャー運動\n" if $::pc{'packRanAgi'};
    $text .= "2d6+$::pc{'packRanObs'} レンジャー観察\n" if $::pc{'packRanObs'};
    $text .= "2d6+$::pc{'packSagKno'} セージ知識\n" if $::pc{'packSagKno'};
    $text .= "2d6+$::pc{'packBarKno'} バード知識\n" if $::pc{'packBarKno'};
    $text .= "2d6+$::pc{'packRidAgi'} ライダー運動\n" if $::pc{'packRidAgi'};
    $text .= "2d6+$::pc{'packRidKno'} ライダー知識\n" if $::pc{'packRidKno'};
    $text .= "2d6+$::pc{'packRidObs'} ライダー観察\n" if $::pc{'packRidObs'};
    $text .= "2d6+$::pc{'packAlcKno'} アルケミスト知識\n" if $::pc{'packAlcKno'};
    $text .= "\n";
    $text .= "2d6+$::pc{'vitResistTotal'} 生命抵抗力\n";
    $text .= "2d6+$::pc{'mndResistTotal'} 精神抵抗力\n";
    $text .= "\n";

    foreach (
      ['Sor', '真語魔法'],
      ['Con', '操霊魔法'],
      ['Pri', '神聖魔法'],
      ['Mag', '魔動機術'],
      ['Fai', '妖精魔法'],
      ['Dem', '召異魔法'],
      ['Gri', '秘奥魔法'],
      ['Bar', '呪歌'],
      ['Alc', '賦術'],
      ['Mys', '占瞳'],
    ){
      next if !$::pc{'lv'.@$_[0]};
      $text .= "2d6+$::pc{'magicPower'.@$_[0]} @$_[1]".(@$_[1] =~ /魔法/?'行使':'')."\n";
    }
    $text .= "\n";
    foreach (1 .. $::pc{'weaponNum'}){
      next if $::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Usage'}.$::pc{'weapon'.$_.'Reqd'}.
              $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.$::pc{'weapon'.$_.'Crit'}.
              $::pc{'weapon'.$_.'Dmg'}.$::pc{'weapon'.$_.'Own'}.$::pc{'weapon'.$_.'Note'}
              eq '';
      $text .= "2d6+$::pc{'weapon'.$_.'AccTotal'} 命中力／$::pc{'weapon'.$_.'Name'}\n";
      $text .= "k$::pc{'weapon'.$_.'Rate'}\[$::pc{'weapon'.$_.'Crit'}\]+$::pc{'weapon'.$_.'DmgTotal'} ダメージ\n";
      $text .= "\n";
    }
    $text .= "2d6+$::pc{'DefenseTotalAllEva'} 回避力\n";
    
    if(1){
      $text .= "\n";
      $text .= "\@HP:$::pc{'hpTotal'}/$::pc{'hpTotal'} MP:$::pc{'mpTotal'}/$::pc{'mpTotal'} 防護:$::pc{'DefenseTotalAllDef'}\n";
    }
  }
  ## 魔物
  elsif($type eq 'm') {
    $text .= "2d6+$::pc{'vitResist'} 生命抵抗力判定\n";
    $text .= "2d6+$::pc{'mndResist'} 精神抵抗力判定\n";
    $text .= "\n";

    foreach (1 .. $::pc{'statusNum'}){
      $text .= "2d6+$::pc{'status'.$_.'Style'} 命中力／$::pc{'status'.$_.'Style'}\n" if $::pc{'status'.$_.'Accuracy'} ne '';
      $text .= "$::pc{'status'.$_.'Damage'} ダメージ\n" if $::pc{'status'.$_.'Damage'} ne '';
      $text .= "2d6+$::pc{'status'.$_.'Evasion'} 回避力\n" if $::pc{'status'.$_.'Evasion'} ne '';
      $text .= "\n";
    }
    my $skills = $::pc{'skills'};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/<br>/\n/gi;
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+?)(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)[(（][0-9]+[）)]/$text .= "2d6+{$1}\n";/megi;
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+)[\/／]([0-9]+)[(（][0-9]+[）)]/$text .= "2d6+{$1}\n";/megi;
  }
  
  return $text;
}
1;