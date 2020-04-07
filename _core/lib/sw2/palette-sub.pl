################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

sub palettePreset {
  my $type = shift;
  my $text;
  ## ＰＣ
  if(!$type){
    $text .= "2d6+{冒険者}+{器用} 冒険者＋器用\n";
    $text .= "2d6+{冒険者}+{敏捷} 冒険者＋敏捷\n";
    $text .= "2d6+{冒険者}+{筋力} 冒険者＋筋力\n";
    $text .= "2d6+{冒険者}+{知力} 冒険者＋知力\n";
    $text .= "2d6+{魔物知識} 魔物知識\n" if $::pc{'monsterLore'};
    $text .= "2d6+{先制力} 先制力\n" if $::pc{'initiative'};
    $text .= "2d6+{スカウト技巧} スカウト技巧\n" if $::pc{'packScoTec'};
    $text .= "2d6+{スカウト運動} スカウト運動\n" if $::pc{'packScoAgi'};
    $text .= "2d6+{スカウト観察} スカウト観察\n" if $::pc{'packScoObs'};
    $text .= "2d6+{レンジャー技巧} レンジャー技巧\n" if $::pc{'packRanTec'};
    $text .= "2d6+{レンジャー運動} レンジャー運動\n" if $::pc{'packRanAgi'};
    $text .= "2d6+{レンジャー観察} レンジャー観察\n" if $::pc{'packRanObs'};
    $text .= "2d6+{セージ知識} セージ知識\n" if $::pc{'packSagKno'};
    $text .= "2d6+{バード知識} バード知識\n" if $::pc{'packBarKno'};
    $text .= "2d6+{ライダー運動} ライダー運動\n" if $::pc{'packRidAgi'};
    $text .= "2d6+{ライダー知識} ライダー知識\n" if $::pc{'packRidKno'};
    $text .= "2d6+{ライダー観察} ライダー観察\n" if $::pc{'packRidObs'};
    $text .= "2d6+{アルケミスト知識} アルケミスト知識\n" if $::pc{'packAlcKno'};
    $text .= "\n";
    $text .= "2d6+{生命抵抗} 生命抵抗力\n";
    $text .= "2d6+{精神抵抗} 精神抵抗力\n";
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
      $text .= "2d6+{@$_[1]} @$_[1]".(@$_[1] =~ /魔法/?'行使':'')."\n";
    }
    $text .= "\n";
    foreach (1 .. $::pc{'weaponNum'}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
      $text .= "2d6+{命中$_} 命中力／$::pc{'weapon'.$_.'Name'}\n";
      $text .= "k{威力$_}\[{C値$_}\]+{追加D$_} ダメージ\n";
      $text .= "\n";
    }
    $text .= "2d6+{回避} 回避力\n";
    
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
      $text .= "2d6+{命中$_} 命中力／$::pc{'status'.$_.'Style'}\n" if $::pc{'status'.$_.'Accuracy'} ne '';
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
  my $text = palettePreset($type);
  my %property;
  $_ =~ s|^//(.*?)=(.*?)$|$property{$1} = $2;|egi foreach paletteProperties($type);
  $text =~ s|\{$_\}|$property{$_}|g foreach keys %property;
  
  return $text;
}

sub paletteProperties {
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
    push @propaties, "//器用=$::pc{'bonusDex'}";
    push @propaties, "//敏捷=$::pc{'bonusAgi'}";
    push @propaties, "//筋力=$::pc{'bonusStr'}";
    push @propaties, "//生命=$::pc{'bonusVit'}";
    push @propaties, "//知力=$::pc{'bonusInt'}";
    push @propaties, "//精神=$::pc{'bonusMnd'}";
    push @propaties, "//DEX=$::pc{'bonusDex'}";
    push @propaties, "//AGI=$::pc{'bonusAgi'}";
    push @propaties, "//STR=$::pc{'bonusStr'}";
    push @propaties, "//VIT=$::pc{'bonusVit'}";
    push @propaties, "//INT=$::pc{'bonusInt'}";
    push @propaties, "//MND=$::pc{'bonusMnd'}";
    push @propaties, '';
    push @propaties, "//生命抵抗=$::pc{'vitResistTotal'}";
    push @propaties, "//精神抵抗=$::pc{'mndResistTotal'}";
    push @propaties, "//HP=$::pc{'hpTotal'}";
    push @propaties, "//MP=$::pc{'mpTotal'}";
    push @propaties, '';
    push @propaties, "//冒険者=$::pc{'level'}";
    push @propaties, "//LV=$::pc{'level'}";
    foreach (
      ['Fig','ファイター'],
      ['Gra','グラップラー'],
      ['Fen','フェンサー'],
      ['Sho','シューター'],
      ['Sor','ソーサラー'],
      ['Con','コンジャラー'],
      ['Pri','プリースト'],
      ['Fai','フェアリーテイマー'],
      ['Mag','マギテック'],
      ['Sco','スカウト'],
      ['Ran','レンジャー'],
      ['Sag','セージ'],
      ['Enh','エンハンサー'],
      ['Bar','バード'],
      ['Rid','ライダー'],
      ['Alc','アルケミスト'],
      ['War','ウォーリーダー'],
      ['Mys','ミスティック'],
      ['Dem','デーモンルーラー'],
      ['Phy','フィジカルマスター'],
      ['Gri','グリモワール'],
      ['Ari','アリストクラシー'],
      ['Art','アーティザン'],
    ){
      next if !$::pc{'lv'.@$_[0]};
      push @propaties, "//@$_[1]=$::pc{'lv'.@$_[0]}";
      push @propaties, "//".uc(@$_[0])."=$::pc{'lv'.@$_[0]}";
    }
    push @propaties, '';
    push @propaties, "//魔物知識=$::pc{'monsterLore'}" if $::pc{'monsterLore'};
    push @propaties, "//先制力=$::pc{'initiative'}" if $::pc{'initiative'};
    push @propaties, "//スカウト技巧=$::pc{'packScoTec'}" if $::pc{'packScoTec'};
    push @propaties, "//スカウト運動=$::pc{'packScoAgi'}" if $::pc{'packScoAgi'};
    push @propaties, "//スカウト観察=$::pc{'packScoObs'}" if $::pc{'packScoObs'};
    push @propaties, "//レンジャー技巧=$::pc{'packRanTec'}" if $::pc{'packRanTec'};
    push @propaties, "//レンジャー運動=$::pc{'packRanAgi'}" if $::pc{'packRanAgi'};
    push @propaties, "//レンジャー観察=$::pc{'packRanObs'}" if $::pc{'packRanObs'};
    push @propaties, "//セージ知識=$::pc{'packSagKno'}" if $::pc{'packSagKno'};
    push @propaties, "//バード知識=$::pc{'packBarKno'}" if $::pc{'packBarKno'};
    push @propaties, "//ライダー運動=$::pc{'packRidAgi'}" if $::pc{'packRidAgi'};
    push @propaties, "//ライダー知識=$::pc{'packRidKno'}" if $::pc{'packRidKno'};
    push @propaties, "//ライダー観察=$::pc{'packRidObs'}" if $::pc{'packRidObs'};
    push @propaties, "//アルケミスト知識=$::pc{'packAlcKno'}" if $::pc{'packAlcKno'};
    push @propaties, '';
    
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
      push @propaties, "//@$_[1]=$::pc{'magicPower'.@$_[0]}";
    }
    push @propaties, '';
  
  foreach (1 .. $::pc{'weaponNum'}){
    next if $::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Usage'}.$::pc{'weapon'.$_.'Reqd'}.
            $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.$::pc{'weapon'.$_.'Crit'}.
            $::pc{'weapon'.$_.'Dmg'}.$::pc{'weapon'.$_.'Own'}.$::pc{'weapon'.$_.'Note'}
            eq '';
    $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
    push @propaties, "//武器$_=$::pc{'weapon'.$_.'Name'}";
    push @propaties, "//命中$_=$::pc{'weapon'.$_.'AccTotal'}";
    push @propaties, "//威力$_=$::pc{'weapon'.$_.'Rate'}";
    push @propaties, "//C値$_=$::pc{'weapon'.$_.'Crit'}";
    push @propaties, "//追加D$_=$::pc{'weapon'.$_.'DmgTotal'}";
    push @propaties, '';
  }
    
    push @propaties, "//回避=$::pc{'defenseTotalAllEva'}";
    push @propaties, "//防護=$::pc{'defenseTotalAllDef'}";
  }
  ## 魔物
  elsif($type eq 'm') {
    push @propaties, "//LV=$::pc{'lv'}";
    push @propaties, '';
    push @propaties, "//生命抵抗=$::pc{'vitResist'}";
    push @propaties, "//精神抵抗=$::pc{'mndResist'}";
    
    push @propaties, '';
    foreach (1 .. $::pc{'statusNum'}){
      push @propaties, "//部位$_=$::pc{'status'.$_.'Style'}";
      push @propaties, "//命中$_=$::pc{'status'.$_.'Accuracy'}" if $::pc{'status'.$_.'Accuracy'} ne '';
      push @propaties, "//ダメージ$_=$::pc{'status'.$_.'Damage'}" if $::pc{'status'.$_.'Damage'} ne '';
      push @propaties, "//回避$_=$::pc{'status'.$_.'Evasion'}" if $::pc{'status'.$_.'Evasion'} ne '';
      push @propaties, '';
    }
    my $skills = $::pc{'skills'};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+?)(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)[(（][0-9]+[）)]/push @propaties, "\/\/$1=$2";/megi;
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+)[\/／]([0-9]+)[(（][0-9]+[）)]/push @propaties, "\/\/$1=$2";/megi;
  }
  
  return @propaties;
}

sub palettePropertiesUsedOnly {
  my $type = shift;
  my $palette = shift;
  my %used;
  my @propaties;
  foreach (paletteProperties($type)){
    if($_ =~ "^//(.+?)="){
      if($palette =~ /\{($1)\}/){ push @propaties, $_ }
    }
    elsif(!$_){
      push @propaties, '';
    }
  }
  return @propaties;
}

1;