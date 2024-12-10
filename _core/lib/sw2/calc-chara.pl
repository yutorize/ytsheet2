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
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }
  
  ### 技能 --------------------------------------------------
  my @class_a; my @class_b; my $lv_caster_total;
  foreach my $class (@data::class_names){
    my $id = $data::class{$class}{id};
    
    ## 冒険者レベル算出
    $pc{level} = $pc{'lv'.$id} if ($pc{level} < $pc{'lv'.$id});
    
    ## 魔法使い最大/合計レベル算出
    $pc{lvCaster} = $pc{'lv'.$id} if ($pc{lvCaster} < $pc{'lv'.$id} && $data::class{$class}{magic}{jName});
    $lv_caster_total += $pc{'lv'.$id} if $data::class{$class}{magic}{jName};
  }

  ### スカレンセジ最大レベル算出 --------------------------------------------------
  my $smax = max($pc{lvSco},$pc{lvRan},$pc{lvSag});

  ### ウィザードレベル算出 --------------------------------------------------
  $pc{lvWiz} = max($pc{lvSor},$pc{lvCon}) if ($pc{lvSor} && $pc{lvCon});

  ### 経験点／名誉点／ガメル計算 --------------------------------------------------
  ## 履歴から 
  $pc{moneyTotal}   = 0;
  $pc{depositTotal} = 0;
  $pc{debtTotal}    = 0;
  $pc{expTotal}   = s_eval($pc{history0Exp});
  $pc{moneyTotal} = s_eval($pc{history0Money});
  $pc{honor}         = s_eval($pc{history0Honor});
  $pc{honorBarbaros} = s_eval($pc{history0HonorB});
  $pc{honorDragon}   = s_eval($pc{history0HonorD});
  foreach my $i (1 .. $pc{historyNum}){
    $pc{expTotal} += s_eval($pc{"history${i}Exp"});
    $pc{moneyTotal} += s_eval($pc{"history${i}Money"});
    
    if   ($pc{"history${i}HonorType"} eq 'barbaros'){ $pc{honorBarbaros} += s_eval($pc{"history${i}Honor"}); }
    elsif($pc{"history${i}HonorType"} eq 'dragon'  ){ $pc{honorDragon}   += s_eval($pc{"history${i}Honor"}); }
    else {
      $pc{honor} += s_eval($pc{"history${i}Honor"});
    }
  }
  $pc{historyExpTotal} = $pc{expTotal};
  $pc{historyMoneyTotal} = $pc{moneyTotal};
  $pc{historyHonorTotal} = $pc{honor};
  ## 収支履歴計算
  my $cashbook = $pc{cashbook};
  $cashbook =~ s/::((?:[\+\-\*\/]?[0-9,]+)+)/$pc{moneyTotal} += s_eval($1)/eg;
  $cashbook =~ s/:>((?:[\+\-\*\/]?[0-9,]+)+)/$pc{depositTotal} += s_eval($1)/eg;
  $cashbook =~ s/:<((?:[\+\-\*\/]?[0-9,]+)+)/$pc{debtTotal} += s_eval($1)/eg;
  $pc{moneyTotal} += $pc{debtTotal} - $pc{depositTotal};

  ## 名誉点2.0
  if($::SW2_0){
    ## 消失
    foreach (1 .. $pc{dishonorItemsNum}){
      $pc{dishonor} += $pc{'dishonorItem'.$_.'Pt'};
    }
    $pc{honor} -= $pc{dishonor};
    $pc{honorMax} = $pc{honor};
    $pc{honorBarbarosMax} = $pc{honorBarbaros};
    $pc{honorDragonMax}   = $pc{honorDragon};
    ## 消費
    foreach (1 .. $pc{honorItemsNum}){
      if   ($pc{"honorItem${_}PtType"} eq 'barbaros'){ $pc{honorBarbaros} -= $pc{'honorItem'.$_.'Pt'}; }
      elsif($pc{"honorItem${_}PtType"} eq 'dragon'  ){ $pc{honorDragon}   -= $pc{'honorItem'.$_.'Pt'}; }
      else { $pc{honor} -= $pc{'honorItem'.$_.'Pt'}; }
    }
    foreach (1 .. $pc{mysticArtsNum}){
      if   ($pc{"mysticArts${_}PtType"} eq 'barbaros'){ $pc{honorBarbaros} -= $pc{'mysticArts'.$_.'Pt'}; }
      elsif($pc{"mysticArts${_}PtType"} eq 'dragon'  ){ $pc{honorDragon}   -= $pc{'mysticArts'.$_.'Pt'}; }
      else { $pc{honor} -= $pc{'mysticArts'.$_.'Pt'}; }
    }
    foreach (1 .. $pc{mysticMagicNum}){
      if   ($pc{"mysticMagic${_}PtType"} eq 'barbaros'){ $pc{honorBarbaros} -= $pc{'mysticMagic'.$_.'Pt'}; }
      elsif($pc{"mysticMagic${_}PtType"} eq 'dragon'  ){ $pc{honorDragon}   -= $pc{'mysticMagic'.$_.'Pt'}; }
      else { $pc{honor} -= $pc{'mysticMagic'.$_.'Pt'}; }
    }
  }
  ## 名誉点2.5
  else {
    foreach (1 .. $pc{honorItemsNum}){
      $pc{honor} -= $pc{'honorItem'.$_.'Pt'};
    }
    foreach (@set::adventurer_rank){
      my ($name, $num, undef) = @$_;
      if ($pc{rank} eq $name) {
        $pc{honorRank} = $num;
      }
    }
    foreach (@set::barbaros_rank){
      my ($name, $num, undef) = @$_;
      if ($pc{rankBarbaros} eq $name) {
        $pc{honorRankBarbaros} = $num;
      }
    }
    $pc{honor} -= $pc{honorRank} + $pc{honorRankBarbaros};
    foreach (1 .. $pc{mysticArtsNum}){
      $pc{honor} -= $pc{'mysticArts'.$_.'Pt'};
    }
    foreach (1 .. $pc{mysticMagicNum}){
      $pc{honor} -= $pc{'mysticMagic'.$_.'Pt'};
    }
    foreach (1 .. $pc{dishonorItemsNum}){
      if($pc{'dishonorItem'.$_.'PtType'} eq 'barbaros'){
        $pc{dishonorBarbaros} += $pc{'dishonorItem'.$_.'Pt'};
      }
      else { $pc{dishonor} += $pc{'dishonorItem'.$_.'Pt'}; }
    }
    $pc{honor}    -= $pc{honorOffset} + $pc{honorOffsetBarbaros};
    $pc{dishonor} -= $pc{honorOffset};
    $pc{dishonorBarbaros} -= $pc{honorOffsetBarbaros};
  }
  ## 冒険者ランク
  if('','Barbaros'){
    if($pc{"rank$_"} !~ /★$/ || $pc{"rankStar$_"} <= 1){ $pc{"rankStar$_"} = '' }
    if($pc{"rank$_"} =~ /★$/ && $pc{"rankStar$_"} >= 2){ $pc{honor} -= 500 * ($pc{"rankStar$_"}-1) }
  }

  ## 経験点消費
  my @expA = ( 0, 1000, 2000, 3500, 5000, 7000, 9500, 12500, 16500, 21500, 27500, 35000, 44000, 54500, 66500, 80000, 95000, 125000 );
  my @expB = ( 0,  500, 1500, 2500, 4000, 5500, 7500, 10000, 13000, 17000, 22000, 28000, 35500, 44500, 55000, 67000, 80500, 105500 );
  my @expS = ( 0, 3000, 6000, 9000, 12000, 16000, 20000, 24000, 28000, 33000, 38000, 43000, 48000, 54000, 60000, 66000, 72000, 79000, 86000, 93000, 100000 );
  $pc{expRest} = $pc{expTotal};
  foreach (@data::class_names){
    if    ($data::class{$_}{expTable} eq 'A'){ $pc{expRest} -= $expA[$pc{'lv'.$data::class{$_}{id}}]; }
    elsif ($data::class{$_}{expTable} eq 'B'){ $pc{expRest} -= $expB[$pc{'lv'.$data::class{$_}{id}}]; }
  }
  
  ### 求道者 --------------------------------------------------
  $pc{expRest} -= $expS[$pc{lvSeeker}];
  if($pc{lvSeeker}){
    $pc{lvMonster} = $pc{level};
    $pc{lvMonster} += $expS[$pc{lvSeeker}] >= 90001 ? 7
                    : $expS[$pc{lvSeeker}] >= 70001 ? 6
                    : $expS[$pc{lvSeeker}] >= 50001 ? 5
                    : $expS[$pc{lvSeeker}] >= 40001 ? 4
                    : $expS[$pc{lvSeeker}] >= 30001 ? 3
                    : $expS[$pc{lvSeeker}] >= 20001 ? 2
                    : $expS[$pc{lvSeeker}] >= 10001 ? 1
                    : 0;
  }
  $pc{sttSeekerGrow} = $pc{lvSeeker} >= 17 ? 30
                     : $pc{lvSeeker} >= 13 ? 24
                     : $pc{lvSeeker} >=  9 ? 18
                     : $pc{lvSeeker} >=  5 ? 12
                     : $pc{lvSeeker} >=  1 ?  6
                     : 0;
  $pc{defenseSeeker} = $pc{lvSeeker} >= 18 ? 10
                     : $pc{lvSeeker} >= 14 ?  8
                     : $pc{lvSeeker} >= 10 ?  6
                     : $pc{lvSeeker} >=  6 ?  4
                     : $pc{lvSeeker} >=  2 ?  2
                     : 0;
  if($pc{lvSeeker}){
    foreach (1..5) {
      last if ($_ == 1 && $pc{lvSeeker} < 3);
      last if ($_ == 2 && $pc{lvSeeker} < 7);
      last if ($_ == 3 && $pc{lvSeeker} < 11);
      last if ($_ == 4 && $pc{lvSeeker} < 15);
      last if ($_ == 5 && $pc{lvSeeker} < 19);
      $pc{buildupAddFeats     }++ if $pc{'seekerBuildup'.$_} eq '戦闘特技';
      $pc{buildupAddSorcery   }++ if $pc{'seekerBuildup'.$_} eq '真語魔法';
      $pc{buildupAddConjury   }++ if $pc{'seekerBuildup'.$_} eq '操霊魔法';
      $pc{buildupAddWizardry  }++ if $pc{'seekerBuildup'.$_} eq '深智魔法';
      $pc{buildupAddHolypray  }++ if $pc{'seekerBuildup'.$_} eq '神聖魔法';
      $pc{buildupAddFairyism  }++ if $pc{'seekerBuildup'.$_} eq '妖精魔法';
      $pc{buildupAddMagitech  }++ if $pc{'seekerBuildup'.$_} eq '魔動機術';
      $pc{buildupAddDemonology}++ if $pc{'seekerBuildup'.$_} eq '召異魔法';
      $pc{buildupAddGramarye  }++ if $pc{'seekerBuildup'.$_} eq '秘奥魔法';
      $pc{buildupAddEnhance   }++ if $pc{'seekerBuildup'.$_} eq '練技';
      $pc{buildupAddSong      }++ if $pc{'seekerBuildup'.$_} eq '呪歌';
      $pc{buildupAddRiding    }++ if $pc{'seekerBuildup'.$_} eq '騎芸';
      $pc{buildupAddAlchemy   }++ if $pc{'seekerBuildup'.$_} eq '賦術';
      $pc{buildupAddCommand   }++ if $pc{'seekerBuildup'.$_} eq '鼓咆';
      $pc{buildupAddDivination}++ if $pc{'seekerBuildup'.$_} eq '占瞳';
      $pc{buildupAddPotential }++ if $pc{'seekerBuildup'.$_} eq '魔装';
      $pc{buildupAddSeal      }++ if $pc{'seekerBuildup'.$_} eq '呪印';
      $pc{buildupAddDignity   }++ if $pc{'seekerBuildup'.$_} eq '貴格';
    }
    foreach (1..5) {
      last if ($_ == 1 && $pc{lvSeeker} < 4);
      last if ($_ == 2 && $pc{lvSeeker} < 8);
      last if ($_ == 3 && $pc{lvSeeker} < 12);
      last if ($_ == 4 && $pc{lvSeeker} < 16);
      last if ($_ == 5 && $pc{lvSeeker} < 20);
         if($pc{'seekerAbility'.$_} eq 'ＨＰ、ＭＰ上昇'){ $pc{seekerAbilityHpMp}   = 10; }
      elsif($pc{'seekerAbility'.$_} eq '抵抗力上昇'    ){ $pc{seekerAbilityResist} =  3; }
      elsif($pc{'seekerAbility'.$_} eq '魔力上昇'      ){ $pc{seekerAbilityMagic}  =  3; }
      elsif($pc{'seekerAbility'.$_} eq '種族特徴の獲得、強化'){ $pc{seekerAbilityRaceA} = 1; }
    }
  }
  ### 種族特徴 --------------------------------------------------
  if($pc{race} && !exists $data::races{$pc{race}}){
    $pc{raceAbility} = $pc{raceAbilityFree};
  }
  else {
    my $i = 1;
    sub setAbility {
      my $lv = shift;
      my @output;
      foreach (@{ $data::races{$pc{race}}{'ability'.$lv} }){
        if(ref($_) eq 'ARRAY'){
          push(@output, $pc{'raceAbilitySelect'.$i});
          $i++;
        }
        else {
          if(exists $data::races{$pc{race}}{abilityReplace}){
            while(exists $data::races{$pc{race}}{abilityReplace}{$_}
              && $pc{level} >= $data::races{$pc{race}}{abilityReplace}{$_}{lv}
            ){
              last if $data::races{$pc{race}}{abilityReplace}{$_}{before} eq $_; #ループ事故防止
              $_ = $data::races{$pc{race}}{abilityReplace}{$_}{before};
            }
          }
          push(@output, $_);
        }
      }
      return @output;
    }
    my @abilities = setAbility('');
    if($pc{level} >=  6){ push @abilities, setAbility('Lv6'); }
    if($pc{level} >= 11){ push @abilities, setAbility('Lv11'); }
    if($pc{level} >= 16){ push @abilities, setAbility('Lv16'); unshift @abilities, '剣の託宣／運命凌駕' }
    elsif($pc{seekerAbilityRaceA}){ push @abilities, setAbility('Lv16'); }
    my %unique;
    @abilities = grep { ! $unique{$_}++ } @abilities;
    $_ .= ($unique{$_} >= 2 ? '＋' : '') foreach(@abilities);
    $pc{raceAbility} = '［'. join('］［', @abilities) . '］';
  }
  ### 種族特徴チェック --------------------------------------------------
  $pc{raceAbilityDef} = 0;
  $pc{raceAbilityMp} = 0;
  $pc{raceAbilityMndResist} = 0;
  $pc{raceAbilityMagicPower} = 0;
  if($pc{raceAbility} =~ /［鱗の皮膚］/){
    $pc{raceAbilityDef} += 1;
  }
  if($pc{raceAbility} =~ /［月光の守り］/){
    $pc{raceAbilityMndResist} += 4;
    if($pc{level} >= 11){ $pc{raceAbilityMndResist} += 2; }
  }
  if($pc{raceAbility} =~ /［晶石の身体］/){
    $pc{raceAbilityDef} += 2;
    $pc{raceAbilityMp} += 15;
    if($pc{level} >= 6){
      $pc{raceAbilityDef} += 1;
      $pc{raceAbilityMp} += 15;
    }
    if($pc{level} >= 11){
      $pc{raceAbilityDef} += 1;
      $pc{raceAbilityMp} += 15;
    }
    if($pc{level} >= 16){
      $pc{raceAbilityDef} += 2;
      $pc{raceAbilityMp} += 30;
    }
  }
  if($pc{raceAbility} =~ /［奈落の身体／アビストランク］/){
    $pc{raceAbilityDef} += 1;
    if($pc{level} >=  6){ $pc{raceAbilityDef} += 1; }
    if($pc{level} >= 11){ $pc{raceAbilityDef} += 1; }
  }
  if($pc{raceAbility} =~ /［トロールの体躯］/){
    $pc{raceAbilityDef} += 1;
    if($pc{level} >= 16){ $pc{raceAbilityDef} += 2; }
  }
  if($pc{raceAbility} =~ /［魔法の申し子］/){
    $pc{raceAbilityMagicPower} += 1;
    if($pc{level} >= 11){ $pc{raceAbilityMagicPower} += 1; }
  }
  if($pc{raceAbility} =~ /［(神の御名と共に|神への礼賛|神への祈り)］/){
    if($pc{level} >=  6){ $pc{raceAbilityMagicPowerPri} += 1; }
    if($pc{level} >= 11){ $pc{raceAbilityMagicPowerPri} += 1; }
  }
  if($pc{level} >= 16){
    $pc{raceAbility} =~ s/［(竜|魔物)化］/［剣の託宣／復活$1化］/;
  }
  ### 装備品の備考 --------------------------------------------------
  my %equipModTotal = {};
  foreach (@{extractModifications(\%pc)}) {
    my %mod = %{$_};
    foreach ('A'..'F'){
      $pc{'sttEquip'.$_} += $mod{$_} // 0;
    }
    foreach ('vResist','mResist','eva','def','mobility'){
      $equipModTotal{$_} += $mod{$_} // 0;
    }
    foreach ('magicPower','magicCast','magicDamage'){
      $pc{$_.'Equip'} += $mod{$_} // 0;
    }
    $pc{reqdStrWeaponMod} += $mod{reqdWeapon} // 0;
  }

  ### 能力値計算 --------------------------------------------------
  ## 成長
  $pc{sttHistGrowA} = $pc{sttHistGrowB} = $pc{sttHistGrowC} = $pc{sttHistGrowD} = $pc{sttHistGrowE} = $pc{sttHistGrowF} = 0;
  for (my $i = 1; $i <= $pc{historyNum}; $i++) {
    my $grow = $pc{"history${i}Grow"};
    $grow =~ s/器(?:用度?)?(?:×|\*)?([0-9]{1,3})/$pc{sttHistGrowA} += $1; ''/ge;
    $grow =~ s/敏(?:捷度?)?(?:×|\*)?([0-9]{1,3})/$pc{sttHistGrowB} += $1; ''/ge;
    $grow =~ s/筋(?:力)?(?:×|\*)?([0-9]{1,3})/$pc{sttHistGrowC} += $1; ''/ge;
    $grow =~ s/生(?:命力?)?(?:×|\*)?([0-9]{1,3})/$pc{sttHistGrowD} += $1; ''/ge;
    $grow =~ s/知(?:力)?(?:×|\*)?([0-9]{1,3})/$pc{sttHistGrowE} += $1; ''/ge;
    $grow =~ s/精(?:神力?)?(?:×|\*)?([0-9]{1,3})/$pc{sttHistGrowF} += $1; ''/ge;
    $pc{sttHistGrowA} += ($grow =~ s/器/器/g);
    $pc{sttHistGrowB} += ($grow =~ s/敏/敏/g);
    $pc{sttHistGrowC} += ($grow =~ s/筋/筋/g);
    $pc{sttHistGrowD} += ($grow =~ s/生/生/g);
    $pc{sttHistGrowE} += ($grow =~ s/知/知/g);
    $pc{sttHistGrowF} += ($grow =~ s/精/精/g);
  }
  
  ## 能力値算出
  $pc{historyGrowTotal} = 0;
  foreach (
    ['A','Dex'],
    ['B','Agi'],
    ['C','Str'],
    ['D','Vit'],
    ['E','Int'],
    ['F','Mnd']
  ){
    my $i = @$_[0];
    my $name = @$_[1];
    # 成長
    $pc{historyGrowTotal} += $pc{'sttPreGrow'.$i} + $pc{'sttHistGrow'.$i};
    $pc{'sttGrow'.$i} = $pc{'sttPreGrow'.$i} + $pc{'sttHistGrow'.$i} + $pc{sttSeekerGrow};

    # 心技体
    my $base
      = ($i =~ /A|B/) ? $pc{sttBaseTec}
      : ($i =~ /C|D/) ? $pc{sttBasePhy}
      : ($i =~ /E|F/) ? $pc{sttBaseSpi}
      : 0;
    # 合計
    $pc{'stt'.$name} = $base + $pc{'sttBase'.$i} + $pc{'sttGrow'.$i};
    # 種族特徴補正
    $pc{'stt'.$name} += exists $data::races{$pc{race}} ? $data::races{$pc{race}}{statusMod}{$name} : 0;
    ## ボーナス算出
    $pc{'bonus'.$name} = int(($pc{'stt'.$name} + $pc{'sttAdd'.$i} + $pc{'sttEquip'.$i}) / 6);
    ## 冒険者レベル＋各ボーナス算出
    $st{'Lv'.$i} = $pc{level}+$pc{'bonus'.$name};
    ## 各技能レベル＋各ボーナス算出
    foreach my $class (@data::class_names){
      my $id = $data::class{$class}{id};
      $st{$id.$i} = ($pc{'lv'.$id} > 0) ? $pc{'lv'.$id}+$pc{'bonus'.$name} : 0;
    }
  }

  ### 戦闘特技 --------------------------------------------------
  ## 自動習得
  my @abilities;
  if($pc{lvFig} >= 7) { push(@abilities, "タフネス"); }
  if($pc{lvGra} >= 1) { push(@abilities, "追加攻撃"); }
  if($pc{lvGra} >= 1 && $::SW2_0) { push(@abilities, "投げ攻撃"); }
  if($pc{lvGra} >= 5 && $::SW2_0) { push(@abilities, "鎧貫き"); }
  if($pc{lvGra} >= 7) { push(@abilities, "カウンター"); }
  if($pc{lvBat} >= 7) { push(@abilities, "舞い流し"); }
  if($pc{lvFig} >=13 || $pc{lvGra} >=13 || $pc{lvBat} >=13) { push(@abilities, "バトルマスター"); }
  if($pc{lvCaster} >= 11){ push(@abilities, "ルーンマスター"); }
  if($pc{lvSco} >= 5) { push(@abilities, $pc{combatFeatsExcSco5} || "トレジャーハント"); }
  if($pc{lvSco} >= 7) { push(@abilities, "ファストアクション"); }
  if($pc{lvSco} >=12) { push(@abilities, "トレジャーマスター"); }
  if($pc{lvSco} >=15) { push(@abilities, "匠の技"); }
  if($pc{lvSco} >= 9) { push(@abilities, "影走り"); }
  if($pc{lvRan} >= 5) { push(@abilities, $pc{combatFeatsExcRan5} || ($::SW2_0?"治癒適性":"サバイバビリティ")); }
  if($pc{lvRan} >= 7) { push(@abilities, "不屈"); }
  if($pc{lvRan} >= 9) { push(@abilities, "ポーションマスター"); }
  if($pc{lvRan} >=12) { push(@abilities, ($::SW2_0?"韋駄天":"縮地")); }
  if($pc{lvRan} >=15) { push(@abilities, ($::SW2_0?"縮地":"ランアンドガン")); }
  if($pc{lvSag} >= 5) { push(@abilities, $pc{combatFeatsExcSag5} || "鋭い目"); }
  if($pc{lvSag} >= 7) { push(@abilities, "弱点看破"); }
  if($pc{lvSag} >= 9) { push(@abilities, "マナセーブ"); }
  if($pc{lvSag} >=12) { push(@abilities, "マナ耐性"); }
  if($pc{lvSag} >=15) { push(@abilities, "賢人の知恵"); }
  $" = ',';
  $pc{combatFeatsAuto} = "@abilities";
  ## 選択特技による補正
  {
    foreach my $i (@set::feats_lv) {
      if($i > $pc{level}){ next; } # $iがLvを超えたら処理しない
      my $feat = $pc{'combatFeatsLv'.$i};
      if   ($feat eq '足さばき')  { $pc{footwork} = 1; }
      elsif($feat eq '命中強化Ⅰ')  { $pc{accuracyEnhance} = 1; }
      elsif($feat eq '命中強化Ⅱ')  { $pc{accuracyEnhance} = 2; }
      elsif($feat eq '回避行動Ⅰ')  { $pc{evasiveManeuver} = 1; }
      elsif($feat eq '回避行動Ⅱ')  { $pc{evasiveManeuver} = 2; }
      elsif($feat eq '心眼')        { $pc{mindsEye} = 4; }
      elsif($feat eq '終律増強')    { $pc{finaleEnhance} = 10; }
      elsif($feat eq '魔力強化Ⅰ')  { $pc{magicPowerEnhance} = 1; }
      elsif($feat eq '魔力強化Ⅱ')  { $pc{magicPowerEnhance} = 2; }
      elsif($feat eq '賦術強化Ⅰ')  { $pc{alchemyEnhance} = 1; }
      elsif($feat eq '賦術強化Ⅱ')  { $pc{alchemyEnhance} = 2; }
      elsif($feat eq '頑強')        { $pc{tenacity} += 15; }
      elsif($feat eq '超頑強')      { $pc{tenacity} += 15; }
      elsif($feat eq 'キャパシティ'){ $pc{capacity} += 15; }
      elsif($feat eq '防具習熟Ａ／金属鎧')  { $pc{masteryMetalArmour}   += 1; }
      elsif($feat eq '防具習熟Ａ／非金属鎧'){ $pc{masteryNonMetalArmour}+= 1; }
      elsif($feat eq '防具習熟Ａ／盾')      { $pc{masteryShield}        += 1; }
      elsif($feat eq '防具習熟Ｓ／金属鎧')  { $pc{masteryMetalArmour}   += 2; }
      elsif($feat eq '防具習熟Ｓ／非金属鎧'){ $pc{masteryNonMetalArmour}+= 2; }
      elsif($feat eq '防具習熟Ｓ／盾')      { $pc{masteryShield}        += 2; }
      elsif($feat =~ /^武器習熟Ａ／(.*)$/) { $pc{'mastery'.ucfirst($data::weapon_id{$1})} += 1; }
      elsif($feat =~ /^武器習熟Ｓ／(.*)$/) { $pc{'mastery'.ucfirst($data::weapon_id{$1})} += 2; }
      elsif($feat =~ /^魔器習熟Ａ/) { $pc{masteryArtisan} += 1; }
      elsif($feat =~ /^魔器習熟Ｓ/) { $pc{masteryArtisan} += 1; }
      elsif($feat =~ /^魔器の達人/) { $pc{masteryArtisan} += 1; }
      elsif($feat eq 'スローイングⅠ'){ $pc{throwing} = 1; }
      elsif($feat eq 'スローイングⅡ'){ $pc{throwing} = 2; }
      elsif($feat eq '呪歌追加Ⅰ')  { $pc{songAddition} = 1; }
      elsif($feat eq '呪歌追加Ⅱ')  { $pc{songAddition} = 2; }
      elsif($feat eq '呪歌追加Ⅲ')  { $pc{songAddition} = 3; }
      elsif($feat eq '鼓咆陣率追加Ⅰ')  { $pc{commandAddition} = 1; }
      elsif($feat eq '鼓咆陣率追加Ⅱ')  { $pc{commandAddition} = 2; }
      elsif($feat eq '鼓咆陣率追加Ⅲ')  { $pc{commandAddition} = 3; }
      elsif($feat eq '抵抗強化Ⅰ')  { $pc{resistEnhance} = 1; }
      elsif($feat eq '抵抗強化Ⅱ')  { $pc{resistEnhance} = 2; }
    }
  }
  ### 魔装 --------------------------------------------------
  foreach my $num (1..$pc{lvPhy}){
    if   ($pc{"craftPotential$num"} =~ /^部位.+強化$/     ){ $pc{partEnhance} += 1 }
    elsif($pc{"craftPotential$num"} =~ /^部位耐久超?増強$/){ $pc{partEnduranceEnhance} += 1 }
    elsif($pc{"craftPotential$num"} =~ /^部位耐久極増強$/ ){ $pc{partEnduranceEnhance} += 2 }
    elsif($pc{"craftPotential$num"} =~ /^コア耐久超?増強$/){ $pc{coreEnduranceEnhance} += 1 }
    elsif($pc{"craftPotential$num"} =~ /^コア耐久極増強$/ ){ $pc{coreEnduranceEnhance} += 2 }
  }

  ### サブステータス --------------------------------------------------
  ## 生命抵抗力
  $pc{vitResistBase} = $st{LvD};
  $pc{vitResistAddTotal} = $equipModTotal{vResist} + s_eval($pc{vitResistAdd}) + $pc{resistEnhance} + $pc{seekerAbilityResist};
  $pc{vitResistTotal}  = $pc{vitResistBase} + $pc{vitResistAddTotal};
  ## 精神抵抗力
  $pc{mndResistBase} = $st{LvF};
  $pc{mndResistAddTotal} = $equipModTotal{mResist} + s_eval($pc{mndResistAdd}) + $pc{raceAbilityMndResist} + $pc{resistEnhance} + $pc{seekerAbilityResist};
  $pc{mndResistTotal}  = $pc{mndResistBase} + $pc{mndResistAddTotal};
  ## ＨＰＭＰ：装飾品
  foreach my $type ('Head', 'Ear', 'Face', 'Neck', 'Back', 'HandR', 'HandL', 'Waist', 'Leg', 'Other', 'Other2','Other3','Other4') {
    foreach my $add ('','_','__'){
      $pc{hpAccessory} = 2 if $pc{"accessory$type$add".'Own'} eq 'HP';
      $pc{mpAccessory} = 2 if $pc{"accessory$type$add".'Own'} eq 'MP';
    }
  }
  ## ＨＰ
  $pc{hpBase} = $pc{level}*3 + $pc{sttVit} + $pc{sttAddD} + $pc{sttEquipD};
  $pc{hpAddTotal} = s_eval($pc{hpAdd}) + $pc{tenacity} + $pc{hpAccessory} + $pc{seekerAbilityHpMp};
  $pc{hpAddTotal} += 15 if $pc{lvFig} >= 7; #タフネス
  $pc{hpTotal}  = $pc{hpBase} + $pc{hpAddTotal};
  ## ＭＰ
  $pc{mpBase} = $lv_caster_total*3 + $pc{sttMnd} + $pc{sttAddF} + $pc{sttEquipF};
  $pc{mpBase} = $pc{level}*3 + $pc{sttMnd} + $pc{sttAddF} + $pc{sttEquipF} if ($pc{raceAbility} =~ /［溢れるマナ］/);
  $pc{mpAddTotal} = s_eval($pc{mpAdd}) + $pc{capacity} + $pc{raceAbilityMp} + $pc{mpAccessory} + $pc{seekerAbilityHpMp};
  $pc{mpTotal} = $pc{mpBase} + $pc{mpAddTotal};
  $pc{mpTotal} = 0  if ($pc{raceAbility} =~ /［マナ不干渉］/);

  ## 移動力
  my $own_mobility = 0;
  foreach my $num (1 .. $pc{armourNum}){
    if($pc{"armour${num}Category"} =~ /鎧/ && $pc{"armour${num}Own"}){
      $own_mobility = 2;
      last;
    }
  }
  $pc{mobilityBase} = $pc{sttAgi} + $pc{sttAddB} + $pc{sttEquipB};
  $pc{mobilityBase} = $pc{mobilityBase} * 2  if ($pc{raceAbility} =~ /［半馬半人］/);
  $pc{mobilityAddTotal} = s_eval($pc{mobilityAdd}) + $equipModTotal{mobility} + $own_mobility;
  $pc{mobilityTotal} = $pc{mobilityBase} + $pc{mobilityAddTotal};
  $pc{mobilityFull} = $pc{mobilityTotal} * 3;
  $pc{mobilityLimited} = min($pc{footwork} ? 10 : 3, $pc{mobilityTotal});

  ## 判定パッケージ
  my @pack_lore;
  my @pack_init;
  foreach my $class (@data::class_names){
    next if !$data::class{$class}{package};
    my $c_id = $data::class{$class}{id};
    my $c_en = $data::class{$class}{eName};
    my $craftName = ucfirst $data::class{$class}{craft}{eName};
    my %data = %{$data::class{$class}{package}};
    
    foreach my $p_id (keys %data){
      my $auto = 0;
      my $disabled = 0;
      my $addAcuire = $pc{ $data::class{$class}{craft}{eName}.'Addition' }
          + $pc{ 'buildupAdd'.ucfirst($data::class{$class}{craft}{eName}) };
      if(exists $data{$p_id}{unlockCraft}){
        $disabled = 1;
        foreach(1 .. $pc{'lv'.$c_id}+$addAcuire){
          if($pc{'craft'.$craftName.$_} eq $data{$p_id}{unlockCraft}){ $disabled = 0; last; }
        }
      }
      # 陣率：軍師の知略
      if($c_id eq 'War' && $p_id eq 'Int'){ 
        foreach(1 .. $pc{'lv'.$c_id}+$addAcuire){
          if($pc{'craftCommand'.$_} =~ /^陣率/){ $auto +=1; last; }
        }
      }
      next if $disabled;

      my $value = $st{$c_id.$data{$p_id}{stt}} + $pc{'pack'.$c_id.$p_id.'Add'} + $auto;
      $pc{'pack'.$c_id.$p_id} = $value;
      $pc{'pack'.$c_id.$p_id.'Auto'} = $auto;
      if($pc{'lv'.$c_id}){
        if($data{$p_id}{monsterLore}){ push @pack_lore, $value }
        if($data{$p_id}{initiative} ){ push @pack_init, $value }
      }
    }
  }

  ## 魔物知識／先制力
  $pc{monsterLore} = max(@pack_lore) + $pc{monsterLoreAdd};
  $pc{initiative}  = max(@pack_init) + $pc{initiativeAdd};

  ## 魔力
  foreach my $name (@data::class_caster){
    next if (!$data::class{$name}{magic}{jName});
    my $id = $data::class{$name}{id};
    $pc{'magicPower'.$id} = $pc{'lv'.$id} ? (
        $pc{'lv'.$id}
      + int(($pc{sttInt}
      + $pc{sttAddE}
      + $pc{sttEquipE}
      + ($pc{'magicPowerOwn'.$id} ? 2 : 0)) / 6)
      + $pc{'magicPowerAdd'.$id}
      + $pc{magicPowerAdd}
      + $pc{magicPowerEnhance}
      + $pc{magicPowerEquip}
      + $pc{raceAbilityMagicPower}
      + $pc{'raceAbilityMagicPower'.$id}
    ) : 0;
    
    $pc{'magicPower'.$id} += $pc{seekerAbilityMagic} if $pc{'lv'.$id} >= 15; #求道者
  }
  ## 奏力ほか
  my %stt = ('知力'=>['Int','E'], '精神力'=>['Mnd','F']);
  foreach my $name (@data::class_names){
    next if (!$data::class{$name}{craft}{stt});
    my $id = $data::class{$name}{id};
    my $st = $data::class{$name}{craft}{stt};
    $pc{'magicPower'.$id} = $pc{'lv'.$id} ? ( $pc{'lv'.$id} + int(($pc{'stt'.$stt{$st}[0]} + $pc{'sttAdd'.$stt{$st}[1]} + $pc{'sttEquip'.$stt{$st}[1]} + ($pc{'magicPowerOwn'.$id} ? 2 : 0)) / 6) + $pc{'magicPowerAdd'.$id} ) : 0;
  }
  $pc{magicPowerAlc} += $pc{alchemyEnhance};
  
  ### 装備 --------------------------------------------------
  ## 武器
  foreach (1 .. $pc{weaponNum}){
    my $class = $pc{"weapon${_}Class"};
    my $id = $data::class{$class}{id};
    my $lv = $pc{'lv'.$id} || 0;
    my $category = $pc{"weapon${_}Category"};
    my $partNum = $pc{"weapon${_}Part"};
    ## 命中
    my $acc = 0;
    if($data::class{$class}{accUnlock}{acc} eq 'power'){
      $acc = $pc{'magicPower'.$id};
    }
    else {
      my $dex = $pc{sttDex} + ($partNum ? $pc{sttPartA} : $pc{sttAddA}+$pc{sttEquipA});
      my $own_dex = $pc{"weapon${_}Own"} ? 2 : 0; # 専用化補正
      if($lv){ $acc = $lv + int(($dex+$own_dex) / 6) }
    }
    ## 人orコア部位
    if(!$partNum || $partNum eq $pc{partCore}) {
      $acc += $pc{accuracyEnhance}; # 命中強化
      $acc += 1 if $pc{throwing} && $category eq '投擲'; # スローイング
    }
    ## その他部位
    else {
      # 部位強化
      $acc += $pc{partEnhance};
    }
    $acc += $pc{"weapon${_}Acc"}; # 武器の修正値
    ## ダメージ
    my $str = $pc{sttStr} + ($partNum ? $pc{sttPartC} : $pc{sttAddC}+$pc{sttEquipC});
    my $dmg = 0;
    $dmg = $pc{"weapon${_}Dmg"};
    if   ($category eq 'クロスボウ'){
      $dmg += $::SW2_0 ? 0 : $pc{lvSho};
    }
    elsif($category eq 'ガン'){
      $dmg += $pc{magicPowerMag};
    }
    elsif($data::class{$class}{accUnlock}{dmg} eq 'power'){
      $dmg += $pc{'magicPower'.$id};
    }
    elsif($lv) {
      $dmg += $lv + int($str / 6);
    }

    if(!$partNum || $partNum eq $pc{partCore}) {
      $dmg += $pc{'mastery' . ucfirst($data::weapon_id{ $category }) };
      if($category eq 'ガン（物理）'){ $dmg += $pc{masteryGun}; }
      if($pc{"weapon${_}Note"} =~ /〈魔器〉/){ $dmg += $pc{masteryArtisan}; }
    }
    else {
      if($category eq '格闘'){ $dmg += $pc{masteryGrapple}; }
      elsif($category && $pc{race} eq 'ディアボロ' && $pc{level} >= 6){
         $dmg += $pc{'mastery' . ucfirst($data::weapon_id{$category}) };
      }
    }
    ##
    if($class eq "自動計算しない"){
      $pc{"weapon${_}AccTotal"} = $pc{"weapon${_}Acc"};
      $pc{"weapon${_}DmgTotal"} = $pc{"weapon${_}Dmg"};
    }
    else {
      $pc{"weapon${_}AccTotal"} = $acc;
      $pc{"weapon${_}DmgTotal"} = $dmg;
    }
  }

  
  ## 回避力・防護点
  foreach my $i (1..$pc{defenseNum}){
    my $class = $pc{"evasionClass$i"};
    my $id = $data::class{$class}{id};
    my $lv = $pc{'lv'.$id} || 0;
    my $partNum = $pc{"evasionPart$i"};
    my $partName = $pc{"evasionPart${i}Name"} = $pc{"part${partNum}Name"};

    ## 基礎値
    my $agi = $pc{sttAgi} + ($partNum ? $pc{sttPartB} : $pc{sttAddB}+$pc{sttEquipB});
    my $eva = 0;
    my $def = 0;
    ## 部位（コア含）
    if($partNum){
      unless($pc{raceAbility} =~ /［蠍人の身体］/ && $partNum eq $pc{partCore}){
        $def += $data::partsData{$partName}{def}[$pc{lvPhy}||0]; # 部位基礎値
      }
      $def += $pc{"part${partNum}Def"}; # 手動補正
    }
    ## 人orコア部位
    if(!$partNum || $partNum eq $pc{partCore}) {
      # 種族特徴
      $def += $pc{raceAbilityDef} + $pc{defenseSeeker};
      # 戦闘特技
      $eva += $pc{evasiveManeuver} + $pc{mindsEye};
      if($pc{evasiveManeuver} == 2 && $id ne 'Fen' && $id ne 'Bat'){ $eva -= 1 }
      if($pc{mindsEye} && $id ne 'Fen'){ $eva -= $pc{mindsEye} }
    }
    ## 部位全般
    if($partNum){
      # コア部位
      if($partNum eq $pc{partCore}) {
        $def += $pc{coreEnduranceEnhance};
      }
      # その他部位
      else {
        $eva += $pc{partEnhance};
        $def += $pc{partEnduranceEnhance};
      }
      if($partName eq '邪眼'){
        $eva += 2;
      }
    }
    ## 装備
    my $own_agi = 0;
    my $artisan = 0;
    foreach my $num (1 .. $pc{armourNum}){
      next if !$pc{"defTotal${i}CheckArmour${num}"};
      
      my $category = $pc{"armour${num}Category"};
      $eva += $pc{"armour${num}Eva"};
      $def += $pc{"armour${num}Def"};
      if(!$partNum || $partNum eq $pc{partCore}) {
        if   ($category eq   '金属鎧'){ $def += $pc{masteryMetalArmour} }
        elsif($category eq '非金属鎧'){ $def += $pc{masteryNonMetalArmour} }
        elsif($category eq       '盾'){ $def += $pc{masteryShield} }
        if($pc{"armour${num}Note"} =~ /〈魔器〉/){ $artisan = $pc{masteryArtisan}; }
      }
      
      if($category eq '盾' && $pc{"armour${num}Own"}){ $own_agi = 2 }
    }
    $eva += $lv ? $lv + int(($agi+$own_agi)/6) : 0;
    $def += $artisan;

    $eva += $equipModTotal{eva};
    $def += $equipModTotal{def};

    $pc{"defenseTotal${i}Eva"} = $eva;
    $pc{"defenseTotal${i}Def"} = $def;
  }
  ### 部位 --------------------------------------------------
  $pc{coreDefAuto} = $pc{coreEnduranceEnhance};
  $pc{coreHpAuto}  = $pc{coreEnduranceEnhance} * 5;
  $pc{partDefAuto} = $pc{partEnduranceEnhance};
  $pc{partHpAuto}  = $pc{partEnduranceEnhance} * 5;
  foreach (1 .. $pc{partNum}) {
    my $name = $pc{"part${_}Name"};
    my $lv = $pc{lvPhy} || 0;
    ## コア
    if($pc{partCore} eq $_){
      $pc{"part${_}DefTotal"} = $data::partsData{$name}{def}[$lv] + $pc{"part${_}Def"} + $pc{coreDefAuto};
      if($pc{raceAbility} =~ /蠍人の身体/){
        $pc{"part${_}DefTotal"} = 0;
        $pc{"part${_}HpTotal" } = $pc{hpTotal} + $pc{coreHpAuto};
        $pc{"part${_}MpTotal" } = $pc{mpTotal};
      }
      else {
        $pc{"part${_}HpTotal" } = $pc{hpTotal}-$pc{sttAddD}-$pc{sttEquipD}-$pc{hpAdd}-$pc{hpAccessory} +$pc{sttPartD} + $pc{coreHpAuto};
        $pc{"part${_}MpTotal" } = $pc{mpTotal}-$pc{sttAddF}-$pc{sttEquipF}-$pc{mpAdd}-$pc{mpAccessory} +$pc{sttPartF};
        my $hpAccessory = 0;
        my $mpAccessory = 0;
        foreach my $add ('','_','__'){
          if($pc{"accessoryEar$add".'Own'} eq 'HP'){ $hpAccessory =2; }
          if($pc{"accessoryEar$add".'Own'} eq 'MP'){ $mpAccessory =2; }
        }
        $pc{"part${_}HpTotal" } += $hpAccessory;
        $pc{"part${_}MpTotal" } += $mpAccessory;
      }
    }
    ## その他
    else {
      $pc{"part${_}DefTotal"} = $data::partsData{$name}{def}[$lv] + $pc{partDefAuto};
      $pc{"part${_}HpTotal" } = $data::partsData{$name}{hp }[$lv] + $pc{partHpAuto};
      $pc{"part${_}MpTotal" } = $data::partsData{$name}{mp }[$lv];
    }
    $pc{"part${_}DefTotal"} += $pc{"part${_}Def"};
    $pc{"part${_}HpTotal" } += $pc{"part${_}Hp" };
    $pc{"part${_}MpTotal" } += $pc{"part${_}Mp" };
  }
  
  ### 穢れ --------------------------------------------------
  {
    my %effects = map { $_->{name} => $_ } @set::effects;
    foreach my $box (1 .. $pc{effectBoxNum}){
      $pc{"effect${box}PtTotal"} = 0;
      my $name = $pc{"effect${box}Name"};
      my $freeMode = ($name =~ /^自由記入/) ? 1 : 0;
      foreach my $num (1 .. $pc{"effect${box}Num"}){
        next if ($num == 1 && $freeMode);
        if($effects{$name}{calc}){
          $pc{"effect${box}PtTotal"} += $pc{"effect${box}-${num}Pt$_"} foreach (@{$effects{$name}{calc}});
        }
      }
      if($pc{"effect${box}Name"} eq '穢れ'){
        $pc{"effect${box}PtTotal"} += $data::races{$pc{race}}{sin} || 0;
        $pc{sin} = $pc{"effect${box}PtTotal"};
      }
    }
  }
  ### グレード自動変更 --------------------------------------------------
  if (@set::grades){
    my $flag;
    foreach(@set::grades){
      if ($pc{group} eq @$_[0]){ $flag = 1; last; }
    }
    if($flag ne ''){
      foreach(@set::grades){
        if ($pc{level} <= @$_[1] && $pc{expTotal} <= @$_[2]){ $pc{group} = @$_[0]; last; }
      }
    }
  }

  ### 0を消去 --------------------------------------------------
  foreach (
  'cardRedB','cardRedA','cardRedS','cardRedSS',
  'cardGreB','cardGreA','cardGreS','cardGreSS',
  'cardBlaB','cardBlaA','cardBlaS','cardBlaSS',
  'cardWhiB','cardWhiA','cardWhiS','cardWhiSS',
  'cardGolB','cardGolA','cardGolS','cardGolSS',
  'sttAddA','sttAddB','sttAddC','sttAddD','sttAddE','sttAddF',
  ){
    delete $pc{$_} if !$pc{$_};
  }
  foreach my $data (values %data::class){
    delete $pc{'lv'.$data->{id}} if !$pc{'lv'.$data->{id}};
  }

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{words}         =~ s/\r\n?|\n/<br>/g;
  $pc{items}         =~ s/\r\n?|\n/<br>/g;
  $pc{freeNote}      =~ s/\r\n?|\n/<br>/g;
  $pc{freeHistory}   =~ s/\r\n?|\n/<br>/g;
  $pc{cashbook}      =~ s/\r\n?|\n/<br>/g;
  $pc{fellowProfile} =~ s/\r\n?|\n/<br>/g;
  $pc{fellowNote}    =~ s/\r\n?|\n/<br>/g;
  $pc{chatPalette}   =~ s/\r\n?|\n/<br>/g;
  $pc{'chatPaletteInsert'.$_} =~ s/\r\n?|\n/<br>/g foreach(1..$pc{chatPaletteInsertNum});
  $pc{$_} =~ s/\r\n?|\n/<br>/g foreach (grep {/^fellow[-0-9]+(?:Action|Note)$/} keys %pc);
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my $charactername = ($pc{aka} ? "“$pc{aka}”" : "").$pc{characterName};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  my $classlv;
  foreach my $class (@data::class_list){
    $classlv .= $pc{'lv'.$data::class{$class}{id}}.'/';
  }
  my $rank = $pc{honorRank} >= $pc{honorRankBarbaros} ? $pc{rank} : $pc{rankBarbaros};
  my $race = (exists $data::races{$pc{race}}) ? $pc{race}
           : $pc{race} ? "その他:$pc{race}"
           : '';
  my $faith = $pc{faith} eq 'その他の信仰' ? ("その他:$pc{faithOther}" || $pc{faith}) : $pc{faith};

  $_ = removeTags unescapeTags $_ foreach($race,$faith);

  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$charactername<>$pc{playerName}<>$pc{group}<>".
               "$pc{expTotal}<>$rank<>$race<>$pc{gender}<>$pc{age}<>$faith<>".
               "$classlv<>".
               "$pc{lastSession}<>$pc{image}<> $pc{tags} <>$pc{hide}<>$pc{fellowPublic}<>";

  return %pc;
}

1;