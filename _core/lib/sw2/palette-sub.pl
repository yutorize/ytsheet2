################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

sub palettePreset {
  my $type = shift;
  my $tool = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{'YTC'} = 1; }
  elsif($tool eq 'bcdice'){ $bot{'BCD'} = 1; }
  ## ＰＣ
  if(!$type){
    # 基本判定
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
    
    # 魔法
    my %pows = (
      'Sor' => [10,20],
      'Con' => [ 0],
      'Pri' => [10],
      'Mag' => [],
      'Fai' => [10],
      'Dru' => [],
      'Dem' => [10,20],
      'Gri' => [10,20],
      'Bar' => [10],
    );
    my %heals = (
      'Con' => [ 0],
      'Pri' => [10],
      'Gri' => [20],
      'Bar' => [ 0,10,20],
    );
    if($::pc{'lvSor'} >=  5){ push(@{$pows{'Sor'}}, 30) }
    if($::pc{'lvSor'} >=  8){ push(@{$pows{'Sor'}}, 40) }
    if($::pc{'lvSor'} >= 11){ push(@{$pows{'Sor'}}, 50) }
    if($::pc{'lvSor'} >= 14){ push(@{$pows{'Sor'}}, 60) }
    if($::pc{'lvSor'} >= 15){ push(@{$pows{'Sor'}},100) }
    if($::pc{'lvCon'} >=  8){ push(@{$pows{'Con'}}, 20) }
    if($::pc{'lvCon'} >=  9){ push(@{$pows{'Con'}}, 30) }
    if($::pc{'lvCon'} >= 15){ push(@{$pows{'Con'}}, 60) }
    if($::pc{'lvPri'} >=  5){ push(@{$pows{'Pri'}}, 20) }
    if($::pc{'lvPri'} >=  9){ push(@{$pows{'Pri'}}, 30) }
    if($::pc{'lvFai'} >=  5){ push(@{$pows{'Fai'}}, 20) }
    if($::pc{'lvFai'} >= 10){ push(@{$pows{'Fai'}}, 40) }
    if($::pc{'lvFai'} >= 11){ push(@{$pows{'Fai'}}, 50) }
    if($::pc{'lvFai'} >= 14){ push(@{$pows{'Fai'}}, 60) }
    if($::pc{'lvMag'} >=  5){ push(@{$pows{'Mag'}}, 30) }
    if($::pc{'lvMag'} >= 15){ push(@{$pows{'Mag'}}, 90) }
    if($::pc{'lvDem'} >=  5){ push(@{$pows{'Dem'}}, 30); push(@{$pows{'Dem'}}, 40); push(@{$pows{'Dem'}}, 50) }
    if($::pc{'lvGri'} >=  4){ push(@{$pows{'Gri'}}, 30) }
    if($::pc{'lvGri'} >=  7){ push(@{$pows{'Gri'}}, 40); push(@{$pows{'Gri'}}, 50) }
    if($::pc{'lvGri'} >= 10){ push(@{$pows{'Gri'}}, 60) }
    if($::pc{'lvGri'} >= 13){ push(@{$pows{'Gri'}}, 80); push(@{$pows{'Gri'}},100) }
    if($::pc{'lvBar'} >=  5){ push(@{$pows{'Bar'}}, 20) }
    if($::pc{'lvBar'} >= 10){ push(@{$pows{'Bar'}}, 30) }
    
    if($::pc{'lvCon'} >= 11){ push(@{$heals{'Con'}}, 30) }
    if($::pc{'lvPri'} >=  5){ push(@{$heals{'Pri'}}, 30) }
    if($::pc{'lvPri'} >= 10){ push(@{$heals{'Pri'}}, 50) }
    if($::pc{'lvPri'} >= 13){ push(@{$heals{'Pri'}}, 70) }
    if($::pc{'lvGri'} >=  7){ push(@{$heals{'Gri'}}, 40) }
    if($::pc{'lvGri'} >= 13){ push(@{$heals{'Gri'}},100) }
    if($::pc{'lvBar'} >=  5){ push(@{$heals{'Bar'}}, 30) }
    if($::pc{'lvBar'} >= 10){ push(@{$heals{'Bar'}}, 40) }
    $text .= "※CAST:行使ボーナス mDMG:魔法ダメージボーナス\n";
    $text .= "//CAST=".($::pc{'magicCastAdd'}||0)."\n";
    $text .= "//mDMG=".($::pc{'magicDamageAdd'}||0)."\n";
    foreach (
      ['Sor', '真語魔法'],
      ['Con', '操霊魔法'],
      ['Pri', '神聖魔法'],
      ['Mag', '魔動機術'],
      ['Fai', '妖精魔法'],
      ['Dru', '森羅魔法'],
      ['Dem', '召異魔法'],
      ['Gri', '秘奥魔法'],
      ['Bar', '呪歌'],
      ['Alc', '賦術'],
      ['Mys', '占瞳'],
    ){
      my ($id, $name) = @$_;
      next if !$::pc{'lv'.$id};
      
      $text .= "2d6+{@$_[1]}".($::pc{'magicCastAdd'.$id}?"+$::pc{'magicCastAdd'.$id}":'');
      if   ($name =~ /魔/){ $text .= "+{CAST} ${name}行使\n"; }
      elsif($name =~ /歌/){ $text .= " 呪歌演奏\n"; }
      else                { $text .= " ${name}\n"; }
      
      foreach my $pow (@{$pows{$id}}) {
        $text .= "k${pow}[10]+{$name}".($::pc{'magicDamageAdd'.$id}?"+$::pc{'magicDamageAdd'.$id}":'').($name =~ /魔/?"+{mDMG}":'')." ダメージ\n";
        $text .= "k${pow}+{$name}//"  .($::pc{'magicDamageAdd'.$id}?"+$::pc{'magicDamageAdd'.$id}":'').($name =~ /魔/?"+{mDMG}":'')." 半減\n" if ($bot{'YTC'});
        $text .= "hk${pow}+{$name} 半減\n" if ($bot{'BCD'});
      }
      foreach my $pow (@{$heals{$id}}) {
        $text .= "k${pow}+{@$_[1]} 回復量\n"
      }
      $text .= "\n";
    }
    
    # 攻撃
    $text .= "※ACC:命中力ボーナス DMG:ダメージボーナス\n";
    $text .= "//ACC=0\n";
    $text .= "//DMG=0\n";
    
    foreach (1 .. $::pc{'weaponNum'}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      
      $::pc{'weapon'.$_.'Crit'} =~ s/[⑦➆]/7/;
      $::pc{'weapon'.$_.'Crit'} =~ s/[⑧➇]/8/;
      $::pc{'weapon'.$_.'Crit'} =~ s/[⑨➈]/9/;
      $::pc{'weapon'.$_.'Crit'} =~ s/[⑩➉]/10/;
      $::pc{'weapon'.$_.'Crit'} =~ s/[⑪]/11/;
      $::pc{'weapon'.$_.'Crit'} =~ s/[⑫]/12/;
      $::pc{'weapon'.$_.'Crit'} =~ s/[⑬]/13/;
      
      $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
      $text .= "2d6+{命中$_}+{ACC}";
      $text .= " 命中力／$::pc{'weapon'.$_.'Name'}\n";
      
      $text .= "k{威力$_}\[{C値$_}\]+{追加D$_}+{DMG}";
      if($::pc{'weapon'.$_.'Name'} =~ /首切/ || $::pc{'weapon'.$_.'Note'} =~ /首切/){
        $text .= $bot{'YTC'} ? '首切' : $bot{'BCD'} ? 'r5' : '';
      }
      $text .= " ダメージ\n";
      $text .= "\n";
    }
    # 回避
    $text .= "2d6+{回避} 回避力\n";
    
    #
    if($bot{'YTC'}) {
      $text .= "\n\@HP:{HP}/{HP} MP:{MP}/{MP} 防護:{防護}\n";
    }
  }
  ## 魔物
  elsif($type eq 'm') {
    $text .= "2d6+{生命抵抗} 生命抵抗力\n";
    $text .= "2d6+{精神抵抗} 精神抵抗力\n";
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
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+?)(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)[(（][0-9]+[）)]/$text .= "2d6+{$1} $1\n";/megi;
    $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+)[\/／]([0-9]+)[(（][0-9]+[）)]/$text .= "2d6+{$1} $1\n";/megi;
  }
  
  return $text;
}

sub palettePresetRaw {
  my $type = shift;
  my $tool = shift;
  my $text = palettePreset($type,$tool);
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
      ['Dru', '森羅魔法'],
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