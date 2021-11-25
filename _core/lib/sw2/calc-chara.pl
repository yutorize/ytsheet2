################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;
require $set::data_races;
require $set::data_items;

sub data_calc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{'ver'}){
    %pc = data_update_chara(\%pc);
  }
  
  ### 技能 --------------------------------------------------
  my @class_a; my @class_b; my $lv_caster_total;
  foreach my $class (@data::class_names){
    my $id = $data::class{$class}{'id'};
    
    ## 冒険者レベル算出
    $pc{'level'} = $pc{'lv'.$id} if ($pc{'level'} < $pc{'lv'.$id});
    
    ## 魔法使い最大/合計レベル算出
    $pc{'lvCaster'} = $pc{'lv'.$id} if ($pc{'lvCaster'} < $pc{'lv'.$id} && $data::class{$class}{'magic'}{'jName'});
    $lv_caster_total += $pc{'lv'.$id} if $data::class{$class}{'magic'}{'jName'};
  }

  ### スカレンセジ最大レベル算出 --------------------------------------------------
  my $smax = max($pc{'lvSco'},$pc{'lvRan'},$pc{'lvSag'});

  ### ウィザードレベル算出 --------------------------------------------------
  $pc{'lvWiz'} = max($pc{'lvSor'},$pc{'lvCon'}) if ($pc{'lvSor'} && $pc{'lvCon'});

  ### 経験点／名誉点／ガメル計算 --------------------------------------------------
  ## 履歴から 
  $pc{'moneyTotal'}   = 0;
  $pc{'depositTotal'} = 0;
  $pc{'debtTotal'}    = 0;
  $pc{'expTotal'}   = s_eval($pc{"history0Exp"});
  $pc{'moneyTotal'} = s_eval($pc{"history0Money"});
  $pc{'honor'}         = s_eval($pc{"history0Honor"});
  $pc{'honorBarbaros'} = s_eval($pc{"history0HonorB"});
  $pc{'honorDragon'}   = s_eval($pc{"history0HonorD"});
  foreach my $i (1 .. $pc{'historyNum'}){
    $pc{'expTotal'} += s_eval($pc{"history${i}Exp"});
    $pc{'moneyTotal'} += s_eval($pc{"history${i}Money"});
    
    if   ($pc{"history${i}HonorType"} eq 'barbaros'){ $pc{'honorBarbaros'} += s_eval($pc{"history${i}Honor"}); }
    elsif($pc{"history${i}HonorType"} eq 'dragon'  ){ $pc{'honorDragon'}   += s_eval($pc{"history${i}Honor"}); }
    else {
      $pc{'honor'} += s_eval($pc{"history${i}Honor"});
    }
  }
  $pc{'historyExpTotal'} = $pc{'expTotal'};
  $pc{'historyMoneyTotal'} = $pc{'moneyTotal'};
  $pc{'historyHonorTotal'} = $pc{'honor'};
  ## 収支履歴計算
  my $cashbook = $pc{"cashbook"};
  $cashbook =~ s/::((?:[\+\-\*\/]?[0-9,]+)+)/$pc{'moneyTotal'} += s_eval($1)/eg;
  $cashbook =~ s/:>((?:[\+\-\*\/]?[0-9,]+)+)/$pc{'depositTotal'} += s_eval($1)/eg;
  $cashbook =~ s/:<((?:[\+\-\*\/]?[0-9,]+)+)/$pc{'debtTotal'} += s_eval($1)/eg;
  $pc{'moneyTotal'} += $pc{'debtTotal'} - $pc{'depositTotal'};

  ## 名誉点2.0
  if($::SW2_0){
    ## 消失
    foreach (1 .. $pc{'dishonorItemsNum'}){
      $pc{'dishonor'} += $pc{'dishonorItem'.$_.'Pt'};
    }
    $pc{'honor'} -= $pc{'dishonor'};
    $pc{'honorMax'} = $pc{'honor'};
    $pc{'honorBarbarosMax'} = $pc{'honorBarbaros'};
    $pc{'honorDragonMax'}   = $pc{'honorDragon'};
    ## 消費
    foreach (1 .. $pc{'honorItemsNum'}){
      if   ($pc{"honorItem${_}PtType"} eq 'barbaros'){ $pc{'honorBarbaros'} -= $pc{'honorItem'.$_.'Pt'}; }
      elsif($pc{"honorItem${_}PtType"} eq 'dragon'  ){ $pc{'honorDragon'}   -= $pc{'honorItem'.$_.'Pt'}; }
      else { $pc{'honor'} -= $pc{'honorItem'.$_.'Pt'}; }
    }
    foreach (1 .. $pc{'mysticArtsNum'}){
      if   ($pc{"mysticArts${_}PtType"} eq 'barbaros'){ $pc{'honorBarbaros'} -= $pc{'mysticArts'.$_.'Pt'}; }
      elsif($pc{"mysticArts${_}PtType"} eq 'dragon'  ){ $pc{'honorDragon'}   -= $pc{'mysticArts'.$_.'Pt'}; }
      else { $pc{'honor'} -= $pc{'mysticArts'.$_.'Pt'}; }
    }
  }
  ## 名誉点2.5
  else {
    foreach (1 .. $pc{'honorItemsNum'}){
      $pc{'honor'} -= $pc{'honorItem'.$_.'Pt'};
    }
    foreach (@set::adventurer_rank){
      my ($name, $num, undef) = @$_;
      $pc{'honor'} -= $num if ($pc{'rank'} eq $name);
    }
    foreach (1 .. $pc{'mysticArtsNum'}){
      $pc{'honor'} -= $pc{'mysticArts'.$_.'Pt'};
    }
    foreach (1 .. $pc{'dishonorItemsNum'}){
      $pc{'dishonor'} += $pc{'dishonorItem'.$_.'Pt'};
    }
    $pc{'honor'}    -= $pc{'honorOffset'};
    $pc{'dishonor'} -= $pc{'honorOffset'};
  }

  ## 経験点消費
  my @expA = ( 0, 1000, 2000, 3500, 5000, 7000, 9500, 12500, 16500, 21500, 27500, 35000, 44000, 54500, 66500, 80000, 95000, 125000 );
  my @expB = ( 0,  500, 1500, 2500, 4000, 5500, 7500, 10000, 13000, 17000, 22000, 28000, 35500, 44500, 55000, 67000, 80500, 105500 );
  my @expS = ( 0, 3000, 6000, 9000, 12000, 16000, 20000, 24000, 28000, 33000, 38000, 43000, 48000, 54000, 60000, 66000, 72000, 79000, 86000, 93000, 100000 );
  $pc{'expRest'} = $pc{'expTotal'};
  foreach (@data::class_names){
    if    ($data::class{$_}{'expTable'} eq 'A'){ $pc{'expRest'} -= $expA[$pc{'lv'.$data::class{$_}{'id'}}]; }
    elsif ($data::class{$_}{'expTable'} eq 'B'){ $pc{'expRest'} -= $expB[$pc{'lv'.$data::class{$_}{'id'}}]; }
  }
  
  ### 求道者 --------------------------------------------------
  $pc{'expRest'} -= $expS[$pc{'lvSeeker'}];
  if($pc{'lvSeeker'}){
    $pc{'lvMonster'} = $pc{'level'};
    $pc{'lvMonster'} += $expS[$pc{'lvSeeker'}] >= 90001 ? 7 :
                        $expS[$pc{'lvSeeker'}] >= 70001 ? 6 :
                        $expS[$pc{'lvSeeker'}] >= 50001 ? 5 :
                        $expS[$pc{'lvSeeker'}] >= 40001 ? 4 :
                        $expS[$pc{'lvSeeker'}] >= 30001 ? 3 :
                        $expS[$pc{'lvSeeker'}] >= 20001 ? 2 :
                        $expS[$pc{'lvSeeker'}] >= 10001 ? 1 : 0;
  }
  $pc{'sttSeekerGrow'} = $pc{'lvSeeker'} >= 17 ? 30
                       : $pc{'lvSeeker'} >= 13 ? 24
                       : $pc{'lvSeeker'} >=  9 ? 18
                       : $pc{'lvSeeker'} >=  5 ? 12
                       : $pc{'lvSeeker'} >=  1 ?  6
                       : 0;
  $pc{'defenseSeeker'} = $pc{'lvSeeker'} >= 18 ? 10
                       : $pc{'lvSeeker'} >= 14 ?  8
                       : $pc{'lvSeeker'} >= 10 ?  6
                       : $pc{'lvSeeker'} >=  6 ?  4
                       : $pc{'lvSeeker'} >=  2 ?  2
                       : 0;
  if($pc{'lvSeeker'}){
    foreach (1..5) {
      last if ($_ == 1 && $pc{'lvSeeker'} < 3);
      last if ($_ == 2 && $pc{'lvSeeker'} < 7);
      last if ($_ == 3 && $pc{'lvSeeker'} < 11);
      last if ($_ == 4 && $pc{'lvSeeker'} < 15);
      last if ($_ == 5 && $pc{'lvSeeker'} < 19);
      $pc{'buildupAddFeats'     }++ if $pc{'seekerBuildup'.$_} eq '戦闘特技';
      $pc{'buildupAddSorcery'   }++ if $pc{'seekerBuildup'.$_} eq '真語魔法';
      $pc{'buildupAddConjury'   }++ if $pc{'seekerBuildup'.$_} eq '操霊魔法';
      $pc{'buildupAddWizardry'  }++ if $pc{'seekerBuildup'.$_} eq '深智魔法';
      $pc{'buildupAddHolypray'  }++ if $pc{'seekerBuildup'.$_} eq '神聖魔法';
      $pc{'buildupAddFairyism'  }++ if $pc{'seekerBuildup'.$_} eq '妖精魔法';
      $pc{'buildupAddMagitech'  }++ if $pc{'seekerBuildup'.$_} eq '魔動機術';
      $pc{'buildupAddDemonology'}++ if $pc{'seekerBuildup'.$_} eq '召異魔法';
      $pc{'buildupAddGramarye'  }++ if $pc{'seekerBuildup'.$_} eq '秘奥魔法';
      $pc{'buildupAddEnhance'   }++ if $pc{'seekerBuildup'.$_} eq '練技';
      $pc{'buildupAddSong'      }++ if $pc{'seekerBuildup'.$_} eq '呪歌';
      $pc{'buildupAddRiding'    }++ if $pc{'seekerBuildup'.$_} eq '騎芸';
      $pc{'buildupAddAlchemy'   }++ if $pc{'seekerBuildup'.$_} eq '賦術';
      $pc{'buildupAddCommand'   }++ if $pc{'seekerBuildup'.$_} eq '鼓咆';
      $pc{'buildupAddDivination'}++ if $pc{'seekerBuildup'.$_} eq '占瞳';
      $pc{'buildupAddPotential' }++ if $pc{'seekerBuildup'.$_} eq '魔装';
      $pc{'buildupAddSeal'      }++ if $pc{'seekerBuildup'.$_} eq '呪印';
      $pc{'buildupAddDignity'   }++ if $pc{'seekerBuildup'.$_} eq '貴格';
    }
    foreach (1..5) {
      last if ($_ == 1 && $pc{'lvSeeker'} < 4);
      last if ($_ == 2 && $pc{'lvSeeker'} < 8);
      last if ($_ == 3 && $pc{'lvSeeker'} < 12);
      last if ($_ == 4 && $pc{'lvSeeker'} < 16);
      last if ($_ == 5 && $pc{'lvSeeker'} < 20);
         if($pc{'seekerAbility'.$_} eq 'ＨＰ、ＭＰ上昇'){ $pc{'seekerAbilityHpMp'}   = 10; }
      elsif($pc{'seekerAbility'.$_} eq '抵抗力上昇'    ){ $pc{'seekerAbilityResist'} =  3; }
      elsif($pc{'seekerAbility'.$_} eq '魔力上昇'      ){ $pc{'seekerAbilityMagic'}  =  3; }
      elsif($pc{'seekerAbility'.$_} eq '種族特徴の獲得、強化'){ $pc{'seekerAbilityRaceA'} = 1; }
    }
  }
  ### 種族特徴 --------------------------------------------------
  $pc{'raceAbility'} = $data::race_ability{$pc{'race'}};
  if($pc{'level'} >= 6){
    if(ref($data::race_ability_lv6{$pc{'race'}}) eq 'ARRAY'){
      $pc{'raceAbility'} .= $pc{'raceAbilityLv6'};
    }
    else { $pc{'raceAbility'} .= $data::race_ability_lv6{$pc{'race'}}; }
  }
  if($pc{'level'} >= 11){
    if(ref($data::race_ability_lv11{$pc{'race'}}) eq 'ARRAY'){
      if($pc{'raceAbility'} =~ /$pc{'raceAbilityLv11'}/){
        (my $text = $pc{'raceAbilityLv11'}) =~ s/］/＋］/;
        $pc{'raceAbility'} =~ s/$pc{'raceAbilityLv11'}/$text/;
      } else {
        $pc{'raceAbility'} .= $pc{'raceAbilityLv11'};
      }
    }
    else { $pc{'raceAbility'} .= $data::race_ability_lv11{$pc{'race'}}; }
  }
  if($pc{'level'} >= 16){
    $pc{'raceAbility'} = '［剣の託宣／運命凌駕］' . $pc{'raceAbility'};
    if(ref($data::race_ability_lv16{$pc{'race'}}) eq 'ARRAY'){
      if($pc{'raceAbility'} =~ /$pc{'raceAbilityLv16'}/){
        (my $text = $pc{'raceAbilityLv16'}) =~ s/］/＋］/;
        $pc{'raceAbility'} =~ s/$pc{'raceAbilityLv16'}/$text/;
      } else {
        $pc{'raceAbility'} .= $pc{'raceAbilityLv16'};
      }
    }
    else {  $pc{'raceAbility'} .= $data::race_ability_lv16{$pc{'race'}}; }
  }
  elsif($pc{'seekerAbilityRaceA'}){
    if(ref($data::race_ability_lv16{$pc{'race'}}) eq 'ARRAY'){
      if($pc{'raceAbility'} =~ /$pc{'raceAbilityLv16'}/){
        (my $text = $pc{'raceAbilityLv16'}) =~ s/］/＋］/;
        $pc{'raceAbility'} =~ s/$pc{'raceAbilityLv16'}/$text/;
      } else {
        $pc{'raceAbility'} .= $pc{'raceAbilityLv16'};
      }
    }
    else { $pc{'raceAbility'} = $pc{'raceAbility'} . $data::race_ability_lv16{$pc{'race'}}; }
  }
  ### 種族チェック --------------------------------------------------
  if($pc{'race'} eq 'リルドラケン'){
    $pc{'raceAbilityDef'} = 1;
  }
  elsif($pc{'race'} eq 'シャドウ'){
    $pc{'raceAbilityMndResist'} = 4;
    if($pc{'level'} >= 11){
      $pc{'raceAbilityMndResist'} += 2;
    }
  }
  elsif($pc{'race'} eq 'フロウライト'){
    $pc{'raceAbilityDef'} = 2;
    $pc{'raceAbilityMp'} = 15;
    if($pc{'level'} >= 6){
      $pc{'raceAbilityDef'} += 1;
      $pc{'raceAbilityMp'} += 15;
    }
    if($pc{'level'} >= 11){
      $pc{'raceAbilityDef'} += 1;
      $pc{'raceAbilityMp'} += 15;
    }
    if($pc{'level'} >= 16){
      $pc{'raceAbilityDef'} += 2;
      $pc{'raceAbilityMp'} += 30;
    }
  }
  elsif($pc{'race'} eq 'ダークトロール'){
    $pc{'raceAbilityDef'} = 1;
    if($pc{'level'} >= 16){
      $pc{'raceAbilityDef'} += 2;
    }
  }
  elsif($pc{'race'} eq 'ドレイク（ナイト）'){
    if($pc{'level'} >= 16){
      $pc{'raceAbility'} =~ s/［竜化］/［剣の託宣／復活竜化］/;
    }
  }
  elsif($pc{'race'} eq 'バジリスク'){
    if($pc{'level'} >= 16){
      $pc{'raceAbility'} =~ s/［魔物化］/［剣の託宣／復活魔物化］/;
    }
  }

  ### 能力値計算  --------------------------------------------------
  ## 成長
  $pc{'sttHistGrowA'} = $pc{'sttHistGrowB'} = $pc{'sttHistGrowC'} = $pc{'sttHistGrowD'} = $pc{'sttHistGrowE'} = $pc{'sttHistGrowF'} = 0;
  for (my $i = 1; $i <= $pc{'historyNum'}; $i++) {
    my $grow = $pc{"history${i}Grow"};
    $grow =~ s/器(?:用度?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttHistGrowA'} += $1; ''/ge;
    $grow =~ s/敏(?:捷度?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttHistGrowB'} += $1; ''/ge;
    $grow =~ s/筋(?:力)?(?:×|\*)?([0-9]{1,3})/$pc{'sttHistGrowC'} += $1; ''/ge;
    $grow =~ s/生(?:命力?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttHistGrowD'} += $1; ''/ge;
    $grow =~ s/知(?:力)?(?:×|\*)?([0-9]{1,3})/$pc{'sttHistGrowE'} += $1; ''/ge;
    $grow =~ s/精(?:神力?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttHistGrowF'} += $1; ''/ge;
    $pc{'sttHistGrowA'} += ($grow =~ s/器/器/g);
    $pc{'sttHistGrowB'} += ($grow =~ s/敏/敏/g);
    $pc{'sttHistGrowC'} += ($grow =~ s/筋/筋/g);
    $pc{'sttHistGrowD'} += ($grow =~ s/生/生/g);
    $pc{'sttHistGrowE'} += ($grow =~ s/知/知/g);
    $pc{'sttHistGrowF'} += ($grow =~ s/精/精/g);
  }
  $pc{'historyGrowTotal'} = $pc{'sttPreGrowA'}  + $pc{'sttPreGrowB'}  + $pc{'sttPreGrowC'}  + $pc{'sttPreGrowD'}  + $pc{'sttPreGrowE'}  + $pc{'sttPreGrowF'}
                          + $pc{'sttHistGrowA'} + $pc{'sttHistGrowB'} + $pc{'sttHistGrowC'} + $pc{'sttHistGrowD'} + $pc{'sttHistGrowE'} + $pc{'sttHistGrowF'};

  $pc{'sttGrowA'} = $pc{'sttPreGrowA'} + $pc{'sttHistGrowA'} + $pc{'sttSeekerGrow'};
  $pc{'sttGrowB'} = $pc{'sttPreGrowB'} + $pc{'sttHistGrowB'} + $pc{'sttSeekerGrow'};
  $pc{'sttGrowC'} = $pc{'sttPreGrowC'} + $pc{'sttHistGrowC'} + $pc{'sttSeekerGrow'};
  $pc{'sttGrowD'} = $pc{'sttPreGrowD'} + $pc{'sttHistGrowD'} + $pc{'sttSeekerGrow'};
  $pc{'sttGrowE'} = $pc{'sttPreGrowE'} + $pc{'sttHistGrowE'} + $pc{'sttSeekerGrow'};
  $pc{'sttGrowF'} = $pc{'sttPreGrowF'} + $pc{'sttHistGrowF'} + $pc{'sttSeekerGrow'};


  ## 能力値算出
  $pc{'sttDex'} = $pc{'sttBaseTec'} + $pc{'sttBaseA'} + $pc{'sttGrowA'};
  $pc{'sttAgi'} = $pc{'sttBaseTec'} + $pc{'sttBaseB'} + $pc{'sttGrowB'};
  $pc{'sttStr'} = $pc{'sttBasePhy'} + $pc{'sttBaseC'} + $pc{'sttGrowC'};
  $pc{'sttVit'} = $pc{'sttBasePhy'} + $pc{'sttBaseD'} + $pc{'sttGrowD'};
  $pc{'sttInt'} = $pc{'sttBaseSpi'} + $pc{'sttBaseE'} + $pc{'sttGrowE'};
  $pc{'sttMnd'} = $pc{'sttBaseSpi'} + $pc{'sttBaseF'} + $pc{'sttGrowF'};
    # ウィークリング補正
    $pc{'sttAgi'} += 3 if $pc{'race'} eq 'ウィークリング（ガルーダ）';
    $pc{'sttMnd'} += 3 if $pc{'race'} eq 'ウィークリング（タンノズ）';
    $pc{'sttStr'} += 3 if $pc{'race'} eq 'ウィークリング（ミノタウロス）';
    $pc{'sttInt'} += 3 if $pc{'race'} eq 'ウィークリング（バジリスク）';
    $pc{'sttMnd'} += 3 if $pc{'race'} eq 'ウィークリング（マーマン）';

  ## ボーナス算出
  $pc{'bonusDex'} = int(($pc{'sttDex'} + $pc{'sttAddA'}) / 6);
  $pc{'bonusAgi'} = int(($pc{'sttAgi'} + $pc{'sttAddB'}) / 6);
  $pc{'bonusStr'} = int(($pc{'sttStr'} + $pc{'sttAddC'}) / 6);
  $pc{'bonusVit'} = int(($pc{'sttVit'} + $pc{'sttAddD'}) / 6);
  $pc{'bonusInt'} = int(($pc{'sttInt'} + $pc{'sttAddE'}) / 6);
  $pc{'bonusMnd'} = int(($pc{'sttMnd'} + $pc{'sttAddF'}) / 6);
  ## 冒険者レベル＋各ボーナス算出
  $st{'LvA'} = $pc{'level'}+$pc{'bonusDex'};
  $st{'LvB'} = $pc{'level'}+$pc{'bonusAgi'};
  $st{'LvC'} = $pc{'level'}+$pc{'bonusStr'};
  $st{'LvD'} = $pc{'level'}+$pc{'bonusVit'};
  $st{'LvE'} = $pc{'level'}+$pc{'bonusInt'};
  $st{'LvF'} = $pc{'level'}+$pc{'bonusMnd'};
  ## 各技能レベル＋各ボーナス算出
  foreach my $class (@data::class_names){
    my $id = $data::class{$class}{'id'};
    if($pc{'lv'.$id} > 0) {
      $st{$id.'A'} = $pc{'lv'.$id}+$pc{'bonusDex'};
      $st{$id.'B'} = $pc{'lv'.$id}+$pc{'bonusAgi'};
      $st{$id.'C'} = $pc{'lv'.$id}+$pc{'bonusStr'};
      $st{$id.'D'} = $pc{'lv'.$id}+$pc{'bonusVit'};
      $st{$id.'E'} = $pc{'lv'.$id}+$pc{'bonusInt'};
      $st{$id.'F'} = $pc{'lv'.$id}+$pc{'bonusMnd'};
    }
    else {
      $st{$id.'A'} = 0;
      $st{$id.'B'} = 0;
      $st{$id.'C'} = 0;
      $st{$id.'D'} = 0;
      $st{$id.'E'} = 0;
      $st{$id.'F'} = 0;
    }
  }

  ### 戦闘特技 --------------------------------------------------
  ## 自動習得
  my @abilities;
  if($pc{'lvFig'} >= 7) { push(@abilities, "タフネス"); }
  if($pc{'lvGra'} >= 1) { push(@abilities, "追加攻撃"); }
  if($pc{'lvGra'} >= 1 && $::SW2_0) { push(@abilities, "投げ攻撃"); }
  if($pc{'lvGra'} >= 7) { push(@abilities, "カウンター"); }
  if($pc{'lvFig'} >=13 || $pc{'lvGra'} >=13) { push(@abilities, "バトルマスター"); }
  if($pc{'lvCaster'} >= 11){ push(@abilities, "ルーンマスター"); }
  if($pc{'lvSco'} >= 5) { push(@abilities, $pc{'combatFeatsExcSco5'} || "トレジャーハント"); }
  if($pc{'lvSco'} >= 7) { push(@abilities, "ファストアクション"); }
  if($pc{'lvSco'} >=12) { push(@abilities, "トレジャーマスター"); }
  if($pc{'lvSco'} >=15) { push(@abilities, "匠の技"); }
  if($pc{'lvSco'} >= 9) { push(@abilities, "影走り"); }
  if($pc{'lvRan'} >= 5) { push(@abilities, $pc{'combatFeatsExcRan5'} || ($::SW2_0?"治癒適性":"サバイバビリティ")); }
  if($pc{'lvRan'} >= 7) { push(@abilities, "不屈"); }
  if($pc{'lvRan'} >= 9) { push(@abilities, "ポーションマスター"); }
  if($pc{'lvRan'} >=12) { push(@abilities, "縮地"); }
  if($pc{'lvRan'} >=15) { push(@abilities, "ランアンドガン"); }
  if($pc{'lvSag'} >= 5) { push(@abilities, $pc{'combatFeatsExcSag5'} || "鋭い目"); }
  if($pc{'lvSag'} >= 7) { push(@abilities, "弱点看破"); }
  if($pc{'lvSag'} >= 9) { push(@abilities, "マナセーブ"); }
  if($pc{'lvSag'} >=12) { push(@abilities, "マナ耐性"); }
  if($pc{'lvSag'} >=15) { push(@abilities, "賢人の知恵"); }
  $" = ',';
  $pc{'combatFeatsAuto'} = "@abilities";
  ## 選択特技による補正
  {
    foreach my $i (@set::feats_lv) {
      if($i > $pc{'level'}){ next; } # $iがLvを超えたら処理しない
      my $feat = $pc{'combatFeatsLv'.$i};
      if   ($feat eq '足さばき')  { $pc{'footwork'} = 1; }
      elsif($feat eq '命中強化Ⅰ')  { $pc{'accuracyEnhance'} = 1; }
      elsif($feat eq '命中強化Ⅱ')  { $pc{'accuracyEnhance'} = 2; }
      elsif($feat eq '回避行動Ⅰ')  { $pc{'evasiveManeuver'} = 1; }
      elsif($feat eq '回避行動Ⅱ')  { $pc{'evasiveManeuver'} = 2; }
      elsif($feat eq '心眼')        { $pc{'mindsEye'} = 4; }
      elsif($feat eq '魔力強化Ⅰ')  { $pc{'magicPowerEnhance'} = 1; }
      elsif($feat eq '魔力強化Ⅱ')  { $pc{'magicPowerEnhance'} = 2; }
      elsif($feat eq '賦術強化Ⅰ')  { $pc{'alchemyEnhance'} = 1; }
      elsif($feat eq '賦術強化Ⅱ')  { $pc{'alchemyEnhance'} = 2; }
      elsif($feat eq '頑強')        { $pc{'tenacity'} += 15; }
      elsif($feat eq '超頑強')      { $pc{'tenacity'} += 15; }
      elsif($feat eq 'キャパシティ'){ $pc{'capacity'} += 15; }
      elsif($feat eq '防具習熟Ａ／金属鎧')  { $pc{'masteryMetalArmour'}   += 1; }
      elsif($feat eq '防具習熟Ａ／非金属鎧'){ $pc{'masteryNonMetalArmour'}+= 1; }
      elsif($feat eq '防具習熟Ａ／盾')      { $pc{'masteryShield'}        += 1; }
      elsif($feat eq '防具習熟Ｓ／金属鎧')  { $pc{'masteryMetalArmour'}   += 2; }
      elsif($feat eq '防具習熟Ｓ／非金属鎧'){ $pc{'masteryNonMetalArmour'}+= 2; }
      elsif($feat eq '防具習熟Ｓ／盾')      { $pc{'masteryShield'}        += 2; }
      elsif($feat =~ /^武器習熟Ａ／(.*)$/) { $pc{'mastery'.ucfirst($data::weapon_id{$1})} += 1; }
      elsif($feat =~ /^武器習熟Ｓ／(.*)$/) { $pc{'mastery'.ucfirst($data::weapon_id{$1})} += 2; }
      elsif($feat =~ /^魔器習熟Ａ/) { $pc{'masteryArtisan'} += 1; }
      elsif($feat =~ /^魔器習熟Ｓ/) { $pc{'masteryArtisan'} += 1; }
      elsif($feat =~ /^魔器の達人/) { $pc{'masteryArtisan'} += 1; }
      elsif($feat eq 'スローイングⅠ'){ $pc{'throwing'} = 1; }
      elsif($feat eq 'スローイングⅡ'){ $pc{'throwing'} = 2; }
      elsif($feat eq '呪歌追加Ⅰ')  { $pc{'songAddition'} = 1; }
      elsif($feat eq '呪歌追加Ⅱ')  { $pc{'songAddition'} = 2; }
      elsif($feat eq '呪歌追加Ⅲ')  { $pc{'songAddition'} = 3; }
      elsif($feat eq '鼓咆陣率追加Ⅰ')  { $pc{'commandAddition'} = 1; }
      elsif($feat eq '鼓咆陣率追加Ⅱ')  { $pc{'commandAddition'} = 2; }
      elsif($feat eq '鼓咆陣率追加Ⅲ')  { $pc{'commandAddition'} = 3; }
      elsif($feat eq '抵抗強化Ⅰ')  { $pc{'resistEnhance'} = 1; }
      elsif($feat eq '抵抗強化Ⅱ')  { $pc{'resistEnhance'} = 2; }
    }
  }

  ### サブステータス --------------------------------------------------
  ## 生命抵抗力
  $pc{'vitResistBase'} = $st{'LvD'};
  $pc{'vitResistAddTotal'} = s_eval($pc{'vitResistAdd'}) + $pc{'resistEnhance'} + $pc{'seekerAbilityResist'};
  $pc{'vitResistTotal'}  = $pc{'vitResistBase'} + $pc{'vitResistAddTotal'};
  ## 精神抵抗力
  $pc{'mndResistBase'} = $st{'LvF'};
  $pc{'mndResistAddTotal'} = s_eval($pc{'mndResistAdd'}) + $pc{'raceAbilityMndResist'} + $pc{'resistEnhance'} + $pc{'seekerAbilityResist'};
  $pc{'mndResistTotal'}  = $pc{'mndResistBase'} + $pc{'mndResistAddTotal'};
  ## ＨＰＭＰ：装飾品
  foreach (
    'Head',  'Head_',
    'Ear',   'Ear_',
    'Face',  'Face_',
    'Neck',  'Neck_',
    'Back',  'Back_',
    'HandR', 'HandR_',
    'HandL', 'HandL_',
    'Waist', 'Waist_',
    'Leg',   'Leg_',
    'Other', 'Other_',
    'Other2','Other2_',
    'Other3','Other3_',
    'Other4','Other4_',) {
    $pc{'hpAccessory'} = 2 if $pc{"accessory$_".'Own'} eq 'HP';
    $pc{'mpAccessory'} = 2 if $pc{"accessory$_".'Own'} eq 'MP';
  }
  ## ＨＰ
  $pc{'hpBase'} = $pc{'level'} * 3 + $pc{'sttVit'} + $pc{'sttAddD'};
  $pc{'hpAddTotal'} = s_eval($pc{'hpAdd'}) + $pc{'tenacity'} + $pc{'hpAccessory'} + $pc{'seekerAbilityHpMp'};
  $pc{'hpAddTotal'} += 15 if $pc{'lvFig'} >= 7; #タフネス
  $pc{'hpTotal'}  = $pc{'hpBase'} + $pc{'hpAddTotal'};
  ## ＭＰ
  $pc{'mpBase'} = $lv_caster_total * 3 + $pc{'sttMnd'} + $pc{'sttAddF'};
  $pc{'mpBase'} = $pc{'level'} * 3 + $pc{'sttMnd'} + $pc{'sttAddF'} if ($pc{'race'} eq 'マナフレア');
  $pc{'mpAddTotal'} = s_eval($pc{'mpAdd'}) + $pc{'capacity'} + $pc{'raceAbilityMp'} + $pc{'mpAccessory'} + $pc{'seekerAbilityHpMp'};
  $pc{'mpTotal'}  = $pc{'mpBase'} + $pc{'mpAddTotal'};
  $pc{'mpTotal'}  = 0  if ($pc{'race'} eq 'グラスランナー');

  ## 移動力
  my $own_mobility = $pc{'armour1Own'} ? 2 : 0;
  $pc{'mobilityBase'} = $pc{'sttAgi'} + $pc{'sttAddB'} + $own_mobility;
  $pc{'mobilityBase'} = $pc{'mobilityBase'} * 2 + $own_mobility  if ($pc{'race'} eq 'ケンタウロス');
  $pc{'mobilityTotal'} = $pc{'mobilityBase'} + s_eval($pc{'mobilityAdd'});
  $pc{'mobilityFull'} = $pc{'mobilityTotal'} * 3;
  $pc{'mobilityLimited'} = $pc{'footwork'} ? 10 : 3;

  ## 判定パッケージ
  my @pack_lore;
  my @pack_init;
  foreach my $class (@data::class_names){
    next if !$data::class{$class}{'package'};
    my $c_id = $data::class{$class}{'id'};
    my $c_en = $data::class{$class}{'eName'};
    my %data = %{$data::class{$class}{'package'}};
    # 軍師の知略
    if($c_id eq 'War'){
      my $war_int_initiative;
      foreach(1 .. $pc{'lvWar'}+$pc{'commandAddition'}){
        if($pc{'craftCommand'.$_} =~ /軍師の知略$/){ $war_int_initiative = 1; last; }
      }
      if(!$war_int_initiative){ delete $data{'Int'} }
    }
    #
    foreach my $p_id (keys %data){
      my $value = $st{$c_id.$data{$p_id}{'stt'}} + $pc{'pack'.$c_id.$p_id.'Add'};
      $pc{'pack'.$c_id.$p_id} = $value;
      if($data{$p_id}{'monsterLore'}){ push @pack_lore, $value }
      if($data{$p_id}{'initiative'} ){ push @pack_init, $value }
    }
  }

  ## 魔物知識／先制力
  $pc{'monsterLore'} = max(@pack_lore) + $pc{'monsterLoreAdd'};
  $pc{'initiative'}  = max(@pack_init) + $pc{'initiativeAdd'};

  ## 魔力
  foreach my $name (@data::class_caster){
    next if (!$data::class{$name}{'magic'}{'jName'});
    my $id = $data::class{$name}{'id'};
    $pc{'magicPower'.$id} = $pc{'lv'.$id} ? ( $pc{'lv'.$id} + int(($pc{'sttInt'} + $pc{'sttAddE'} + ($pc{'magicPowerOwn'.$id} ? 2 : 0)) / 6) + $pc{'magicPowerAdd'.$id} + $pc{'magicPowerAdd'} + $pc{'magicPowerEnhance'} ) : 0;
    
    if($pc{'race'} eq 'ハイマン'){
      $pc{'magicPower'.$id} += $pc{'level'} >= 11 ? 2 : 1;
    }
    elsif($pc{'race'} =~ /^センティアン/ && $name eq 'プリースト'){
      $pc{'magicPower'.$id} += $pc{'level'} >= 11 ? 2 : $pc{'level'} >= 6 ? 1 : 0;
    }
    $pc{'magicPower'.$id} += $pc{'seekerAbilityMagic'} if $pc{'lv'.$id} >= 15; #求道者
  }
  ## 奏力ほか
  my %stt = ('知力'=>['Int','E'], '精神力'=>['Mnd','F']);
  foreach my $name (@data::class_names){
    next if (!$data::class{$name}{'craft'}{'stt'});
    my $id = $data::class{$name}{'id'};
    my $st = $data::class{$name}{'craft'}{'stt'};
    $pc{'magicPower'.$id} = $pc{'lv'.$id} ? ( $pc{'lv'.$id} + int(($pc{'stt'.$stt{$st}[0]} + $pc{'sttAdd'.$stt{$st}[1]} + ($pc{'magicPowerOwn'.$id} ? 2 : 0)) / 6) + $pc{'magicPowerAdd'.$id} ) : 0;
  }
  $pc{'magicPowerAlc'} += $pc{'alchemyEnhance'};
  
  ### 装備 --------------------------------------------------
  ## 武器
  foreach (1 .. $pc{'weaponNum'}){
    my $class;
    if   ($pc{'weapon'.$_.'Class'} eq "ファイター"       && $pc{'lvFig'}){ $class = 'Fig'; }
    elsif($pc{'weapon'.$_.'Class'} eq "グラップラー"     && $pc{'lvGra'}){ $class = 'Gra'; }
    elsif($pc{'weapon'.$_.'Class'} eq "フェンサー"       && $pc{'lvFen'}){ $class = 'Fen'; }
    elsif($pc{'weapon'.$_.'Class'} eq "シューター"       && $pc{'lvSho'}){ $class = 'Sho'; }
    elsif($pc{'weapon'.$_.'Class'} eq "エンハンサー"     && $pc{'lvEnh'}){ $class = 'Enh'; }
    elsif($pc{'weapon'.$_.'Class'} eq "デーモンルーラー" && $pc{'lvDem'}){ $class = 'Dem'; }
    ## 命中
    my $own_dex = $pc{'weapon'.$_.'Own'} ? 2 : 0; # 専用化補正
    $pc{'weapon'.$_.'AccTotal'} = 0;
    $pc{'weapon'.$_.'AccTotal'} = $pc{'lv'.$class} + int( ($pc{'sttDex'} + $pc{'sttAddA'} + $own_dex) / 6 ) if $pc{'lv'.$class};
    $pc{'weapon'.$_.'AccTotal'} += $pc{'accuracyEnhance'}; # 命中強化
    $pc{'weapon'.$_.'AccTotal'} += 1 if $pc{'throwing'} && $pc{'weapon'.$_.'Category'} eq '投擲'; # スローイング
    $pc{'weapon'.$_.'AccTotal'} += $pc{'weapon'.$_.'Acc'}; # 武器の修正値
    ## ダメージ
    $pc{'weapon'.$_.'DmgTotal'} = $pc{'weapon'.$_.'Dmg'};
    if   ($pc{'weapon'.$_.'Category'} eq 'クロスボウ'){
      $pc{'weapon'.$_.'DmgTotal'} += $pc{'lvSho'};
    }
    elsif($pc{'weapon'.$_.'Category'} eq 'ガン'      ){
      $pc{'weapon'.$_.'DmgTotal'} += $pc{'magicPowerMag'};
    }
    elsif(!$::SW2_0 && $pc{'weapon'.$_.'Class'} eq "デーモンルーラー"){
      $pc{'weapon'.$_.'DmgTotal'} += $pc{'magicPowerDem'};
    }
    else {
      $pc{'weapon'.$_.'DmgTotal'} += $st{$class.'C'};
    }

    $pc{'weapon'.$_.'DmgTotal'} += $pc{'mastery' . ucfirst($data::weapon_id{ $pc{'weapon'.$_.'Category'} }) };
    if($pc{'weapon'.$_.'Category'} eq 'ガン（物理）'){ $pc{'weapon'.$_.'DmgTotal'} += $pc{'masteryGun'}; }
    if($pc{'weapon'.$_.'Note'} =~ /〈魔器〉/){ $pc{'weapon'.$_.'DmgTotal'} += $pc{'masteryArtisan'}; }

    if($pc{'weapon'.$_.'Class'} eq "自動計算しない"){
      $pc{'weapon'.$_.'AccTotal'} = $pc{'weapon'.$_.'Acc'};
      $pc{'weapon'.$_.'DmgTotal'} = $pc{'weapon'.$_.'Dmg'};
    }
  }

  ## 基本回避力
    use POSIX 'ceil';
    $pc{'reqdStr'}  = $pc{'sttStr'} + $pc{'sttAddC'};
    $pc{'reqdStrF'} = ceil($pc{'reqdStr'} / 2);
    my $eva_class;
    if   ($pc{'evasionClass'} eq "ファイター"       && $pc{'lvFig'}){ $eva_class = $pc{'lvFig'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
    elsif($pc{'evasionClass'} eq "グラップラー"     && $pc{'lvGra'}){ $eva_class = $pc{'lvGra'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
    elsif($pc{'evasionClass'} eq "フェンサー"       && $pc{'lvFen'}){ $eva_class = $pc{'lvFen'}; $pc{'evasionStr'} = $pc{'reqdStrF'}; }
    elsif($pc{'evasionClass'} eq "シューター"       && $pc{'lvSho'}){ $eva_class = $pc{'lvSho'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
    elsif($pc{'evasionClass'} eq "デーモンルーラー" && $pc{'lvDem'}){ $eva_class = $pc{'lvDem'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
    else{ $eva_class = 0; $pc{'evasionStr'} = $pc{'reqdStr'}; }

  ## 防具
    foreach my $i (1..3){
      my $own_agi = $pc{"defTotal${i}CheckShield1"} && $pc{'shield1Own'} ? 2 : 0;
      my $art_def = 0;
      my $eva = ( $eva_class ? $eva_class + int(($pc{'sttAgi'}+$pc{'sttAddB'}+$own_agi)/6) : 0 ) + $pc{'evasiveManeuver'} + $pc{'mindsEye'};
      my $def = $pc{'raceAbilityDef'} + $pc{'defenseSeeker'};
      my $flag = 0;
      if($pc{"defTotal${i}CheckArmour1"}  ){ $flag++; $eva += $pc{'armour1Eva'};    $def += $pc{'armour1Def'} + max($pc{'masteryMetalArmour'},$pc{'masteryNonMetalArmour'}); }
      if($pc{"defTotal${i}CheckShield1"}  ){ $flag++; $eva += $pc{'shield1Eva'};    $def += $pc{'shield1Def'} + $pc{'masteryShield'}; }
      if($pc{"defTotal${i}CheckDefOther1"}){ $flag++; $eva += $pc{'defOther1Eva'}; $def += $pc{'defOther1Def'}; }
      if($pc{"defTotal${i}CheckDefOther2"}){ $flag++; $eva += $pc{'defOther2Eva'}; $def += $pc{'defOther2Def'}; }
      if($pc{"defTotal${i}CheckDefOther3"}){ $flag++; $eva += $pc{'defOther3Eva'}; $def += $pc{'defOther3Def'}; }
      if(($pc{"defTotal${i}CheckArmour1"} && $pc{'armour1Note'} =~ /〈魔器〉/)
      || ($pc{"defTotal${i}CheckShield1"} && $pc{'Shield1Note'} =~ /〈魔器〉/)){
        $def += $pc{'masteryArtisan'};
      }
      if($flag){
        $pc{"defenseTotal${i}Eva"} = $eva;
        $pc{"defenseTotal${i}Def"} = $def;
      }
    }

  ### グレード自動変更 --------------------------------------------------
  if (@set::grades){
    my $flag;
    foreach(@set::grades){
      if ($pc{'group'} eq @$_[0]){ $flag = 1; last; }
    }
    if($flag ne ''){
      foreach(@set::grades){
        if ($pc{'level'} <= @$_[1] && $pc{'expTotal'} <= @$_[2]){ $pc{'group'} = @$_[0]; last; }
      }
    }
  }

  ### 0を消去 --------------------------------------------------
  foreach (
  'lvFig','lvGra','lvFen','lvSho',
  'lvSor','lvCon','lvPri','lvFai','lvMag',
  'lvSco','lvRan','lvSag',
  'lvEnh','lvBar','lvRid','lvAlc',
  'lvDru','lvDem',
  'lvWar','lvMys','lvPhy',
  'lvGri','lvArt','lvAri',
  'cardRedB','cardRedA','cardRedS','cardRedSS',
  'cardGreB','cardGreA','cardGreS','cardGreSS',
  'cardBlaB','cardBlaA','cardBlaS','cardBlaSS',
  'cardWhiB','cardWhiA','cardWhiS','cardWhiSS',
  'cardGolB','cardGolA','cardGolS','cardGolSS',
  ){
    delete $pc{$_} if !$pc{$_};
  }

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{'words'}         =~ s/\r\n?|\n/<br>/g;
  $pc{'items'}         =~ s/\r\n?|\n/<br>/g;
  $pc{'freeNote'}      =~ s/\r\n?|\n/<br>/g;
  $pc{'freeHistory'}   =~ s/\r\n?|\n/<br>/g;
  $pc{'cashbook'}      =~ s/\r\n?|\n/<br>/g;
  $pc{'fellowProfile'} =~ s/\r\n?|\n/<br>/g;
  $pc{'fellowNote'}    =~ s/\r\n?|\n/<br>/g;
  $pc{'chatPalette'}   =~ s/\r\n?|\n/<br>/g;

  ### newline --------------------------------------------------
  my $charactername = ($pc{'aka'} ? "“$pc{'aka'}”" : "").$pc{'characterName'};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  my $classlv;
  foreach my $class (@data::class_list){
    $classlv .= $pc{'lv'.$data::class{$class}{'id'}}.'/';
  }
  $::newline = "$pc{'id'}<>$::file<>".
               "$pc{'birthTime'}<>$::now<>$charactername<>$pc{'playerName'}<>$pc{'group'}<>".
               "$pc{'expTotal'}<>$pc{'rank'}<>$pc{'race'}<>$pc{'gender'}<>$pc{'age'}<>$pc{'faith'}<>".
               "$classlv<>".
               "$pc{'sessionTotal'}<>$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<>$pc{'fellowPublic'}<>";

  return %pc;
}

1;