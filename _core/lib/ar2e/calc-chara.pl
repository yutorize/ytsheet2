################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_races;
require $set::data_class;

sub data_calc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{'ver'}){
    %pc = data_update_chara(\%pc);
  }
  

  ### 経験点／ゴールド計算 --------------------------------------------------
  ## 履歴から 
  $pc{'moneyTotal'}   = 0;
  #$pc{'depositTotal'} = 0;
  #$pc{'debtTotal'}    = 0;
  $pc{'payment'}    = 0;
  $pc{'expTotal'}   = s_eval($pc{"history0Exp"});
  $pc{'moneyTotal'} = s_eval($pc{"history0Money"});
  foreach my $i (1 .. $pc{'historyNum'}){
    $pc{'expTotal'}   += s_eval($pc{"history${i}Exp"});
    $pc{'payment'}    += s_eval($pc{"history${i}Payment"});
    $pc{'moneyTotal'} += s_eval($pc{"history${i}Money"});
  }
  $pc{'expTotal'} -= $pc{'payment'};
  $pc{'historyExpTotal'} = $pc{'expTotal'};
  $pc{'historyMoneyTotal'} = $pc{'moneyTotal'};
  ## 収支履歴計算
  my $cashbook = $pc{"cashbook"};
  $cashbook =~ s/::((?:[\+\-\*\/]?[0-9]+)+)/$pc{'moneyTotal'} += eval($1)/eg;
  #$cashbook =~ s/:>((?:[\+\-\*\/]?[0-9]+)+)/$pc{'depositTotal'} += eval($1)/eg;
  #$cashbook =~ s/:<((?:[\+\-\*\/]?[0-9]+)+)/$pc{'debtTotal'} += eval($1)/eg;
  #$pc{'moneyTotal'} += $pc{'debtTotal'} - $pc{'depositTotal'};

  ## スキルレベル
  $pc{'skillLvTotal'} = $pc{'skillLvGeneral'} = 0;
  my %skill;
  foreach my $num (1 .. $pc{'skillsNum'}){
    my $name = $pc{"skill${num}Name"};
    my $lv = $pc{"skill${num}Lv"};
    next if !$lv;
    my $type = $pc{"skill${num}Type"};
    if ($data::class{$type} && $data::class{$type}{'type'} eq 'fate'){ $type = 'power'; }
    if    ($type eq 'general'){ $pc{'skillLvGeneral'} += $lv; }
    elsif ($type eq 'add'    ){ $pc{'skillLvTotal'} += $lv; $pc{'skillLvLimitAdd'} += 1; }
    elsif ($type eq 'geis'   ){ $pc{'skillLvTotal'} += $lv; $pc{'skillLvLimitAdd'} += 1; }
    elsif ($type eq 'power'  ){ $pc{'skillLvTotal'} += $lv; $pc{'skillLvLimitAdd'} -= $lv; }
    elsif ($type eq 'another'){ $pc{'skillLvTotal'} += $lv; $pc{'skillLvLimitAdd'} += $lv; }
    else                      { $pc{'skillLvTotal'} += $lv; }

    if   ($name =~ /(?:^|[\/／])バイタリティ/  ){ $pc{'hpAuto'} = $pc{'level'} }
    elsif($name =~ /(?:^|[\/／])インテンション/){ $pc{'mpAuto'} = $pc{'level'} }
    elsif($name =~ /(?:^|[\/／])エンラージリミット/){ $skill{'エンラージリミット'} = 1 }
    elsif($name =~ /(?:^|[\/／])アストラルボディ/  ){ $skill{'アストラルボディ'} = 'Mnd' }
    elsif($name =~ /(?:^|[\/／])ファランクススタイル[:：]器用/){ $skill{'ファランクススタイル'} = 'Dex' }
    elsif($name =~ /(?:^|[\/／])ファランクススタイル[:：]敏捷/){ $skill{'ファランクススタイル'} = 'Agi' }
    elsif($name =~ /(?:^|[\/／])ファランクススタイル[:：]知力/){ $skill{'ファランクススタイル'} = 'Int' }
    elsif($name =~ /(?:^|[\/／])ファランクススタイル[:：]感知/){ $skill{'ファランクススタイル'} = 'Sen' }
    elsif($name =~ /(?:^|[\/／])ファランクススタイル[:：]精神/){ $skill{'ファランクススタイル'} = 'Mnd' }
    elsif($name =~ /(?:^|[\/／])ファランクススタイル[:：]幸運/){ $skill{'ファランクススタイル'} = 'Luk' }
    elsif($name =~ /(?:^|[\/／])レガシーサイン/){ $skill{'レガシーサイン'} = 1 }
  }
  $pc{'skillLvLimitAdd'} = !$pc{'skillLvLimitAdd'} ? '' : $pc{'skillLvLimitAdd'} > 0 ? "+$pc{'skillLvLimitAdd'}" : $pc{'skillLvLimitAdd'};
  ## 成長点消費
  #レベル
  foreach my $lv (2 .. $pc{'level'}){
    $pc{'expUsedLevel'} += ($lv - 1) * 10;
  }
  #一般スキル
  $pc{'expUsedGeneralSkills'} = ($pc{'skillLvGeneral'} - 2) * 5;
  $pc{'skillLvGeneral'} -= $skill{'レガシーサイン'};
  #誓約
  foreach my $num (1 .. $pc{'geisesNum'}){
    $pc{'expUsedGeises'} += $pc{"geis${num}Cost"};
  }
  #コネクション
  foreach my $lv (1 .. $pc{'connectionsNum'}){
    $pc{'expUsedConnections'}++ if $pc{"connection${lv}Name"};
  }
  #合計
  $pc{'expUsed'} = $pc{'expUsedLevel'} + $pc{'expUsedGeneralSkills'} + $pc{'expUsedConnections'} + $pc{'expUsedGeises'};
  $pc{'expRest'} = $pc{'expTotal'} - $pc{'expUsed'};
  
  ### クラス --------------------------------------------------
  $pc{'classMain'}    = $pc{'classMainLv1'};
  $pc{'classSupport'} = $pc{'classSupportLv1'};
  if($pc{'classSupport'} eq 'free'){ $pc{'classSupport'} = $pc{"classSupportLv1Free"}; }
  $pc{'classTitle'} = '';
  
  ## レベルアップ
  $pc{'skillLvLimit'} += 1+1+4; #種族1＋メイン1＋任意4
  $pc{'hpGrow'} = 0;
  $pc{'mpGrow'} = 0;
  foreach my $lv (2 .. $pc{'level'}){
    my $name = $pc{"lvUp${lv}Class"};
    ## クラス
    if($data::class{$name}){
      if($data::class{$name}{'base'}){ $pc{'classMain'}    = $name; }
      else                           { $pc{'classSupport'} = $name; }
    }
    elsif($name eq 'free' ){ $pc{'classSupport'} = $pc{"lvUp${lv}ClassFree"}; }
    elsif($name eq 'title'){ $pc{'classTitle'}   = $pc{"lvUp${lv}ClassFree"}; }
    ## HP／MP成長
    if($data::class{$pc{'classMain'}}){
      $pc{'hpGrow'} += $data::class{$pc{'classMain'}}{'stt'}{'HpGrow'};
      $pc{'mpGrow'} += $data::class{$pc{'classMain'}}{'stt'}{'MpGrow'};
    }
    ## フェイト成長
    if($pc{"lvUp${lv}Class"} eq 'fate'){ $pc{'fateGrow'} += int($lv / 10)+1; }
    ## スキル習得可能数
    $pc{'skillLvLimit'} += $name ? 2 : 3;
  }

  ### 能力値 --------------------------------------------------
  foreach my $s ('Str','Dex','Agi','Int','Sen','Mnd','Luk'){
    $pc{"stt${s}Grow"} = 0;
    foreach my $lv (2 .. $pc{'level'}){
      if($pc{"lvUp${lv}Stt${s}"}){ $pc{"stt${s}Grow"}++; }
    }
    $pc{"stt${s}Base"} = $pc{"stt${s}Race"} + $pc{"stt${s}Make"} + $pc{"stt${s}BaseAdd"} + $pc{"stt${s}Grow"};
    $pc{"stt${s}Bonus"} = int($pc{"stt${s}Base"} / 3);
    $pc{"stt${s}Total"} = $pc{"stt${s}Bonus"} + $pc{"stt${s}Main"} + $pc{"stt${s}Support"} + $pc{"stt${s}Add"};
    $pc{"roll${s}"} = $pc{"stt${s}Total"} + $pc{"roll${s}Add"};
  }

  ## HP／MP
  $pc{'hpTotal'} = $pc{'sttStrBase'} + $pc{'hpMain'} + $pc{'hpSupport'} + $pc{'hpAdd'} + $pc{'hpAuto'} +  $pc{'hpGrow'};
  $pc{'mpTotal'} = $pc{'sttMndBase'} + $pc{'mpMain'} + $pc{'mpSupport'} + $pc{'mpAdd'} + $pc{'mpAuto'} +  $pc{'mpGrow'};

  ## フェイト
  $pc{'fateTotal'} = $pc{'fateGrow'} + $pc{'fateAdd'} + 5 + ($pc{'classMainLv1'} eq $pc{'classSupportLv1'} ? 1 : 0);
  $pc{'fateLimit'} = $pc{'sttLukTotal'} + $pc{'fateLimitAdd'};

  ### 武器・戦闘判定 --------------------------------------------------
  $pc{'armamentTotalWeightWeapon'} =
  $pc{'armamentTotalWeightArmour'} =
  $pc{'armamentTotalAcc' } =
  $pc{'armamentTotalAtk' } =
  $pc{'armamentTotalEva' } =
  $pc{'armamentTotalDef' } =
  $pc{'armamentTotalMDef'} =
  $pc{'armamentTotalIni' } =
  $pc{'armamentTotalMove'} = 0;
  foreach my $id ('HandR','HandL','Head','Body','Sub','Other'){
    if($id =~ /^Hand/){ $pc{'armamentTotalWeightWeapon'} += $pc{"armament${id}Weight"}; }
    else              { $pc{'armamentTotalWeightArmour'} += $pc{"armament${id}Weight"}; }
    $pc{'armamentTotalAcc' } += $pc{"armament${id}Acc"};
    $pc{'armamentTotalAtk' } += $pc{"armament${id}Atk"};
    $pc{'armamentTotalEva' } += $pc{"armament${id}Eva"};
    $pc{'armamentTotalDef' } += $pc{"armament${id}Def"};
    $pc{'armamentTotalMDef'} += $pc{"armament${id}MDef"};
    $pc{'armamentTotalIni' } += $pc{"armament${id}Ini"};
    $pc{'armamentTotalMove'} += $pc{"armament${id}Move"};
  }
  $pc{'armamentTotalAccR' } = $pc{'armamentTotalAcc'} - $pc{"armamentHandLAcc"};
  $pc{'armamentTotalAccL' } = $pc{'armamentTotalAcc'} - $pc{"armamentHandRAcc"};
  $pc{'armamentTotalAtkR' } = $pc{'armamentTotalAtk'} - $pc{"armamentHandLAtk"};
  $pc{'armamentTotalAtkL' } = $pc{'armamentTotalAtk'} - $pc{"armamentHandRAtk"};

  $pc{'battleAddAcc' } = $pc{'armamentTotalAcc' } + $pc{"battleSkillAcc" } + $pc{"battleOtherAcc" };
  $pc{'battleAddAtk' } = $pc{'armamentTotalAtk' } + $pc{"battleSkillAtk" } + $pc{"battleOtherAtk" };
  $pc{'battleAddEva' } = $pc{'armamentTotalEva' } + $pc{"battleSkillEva" } + $pc{"battleOtherEva" };
  $pc{'battleAddDef' } = $pc{'armamentTotalDef' } + $pc{"battleSkillDef" } + $pc{"battleOtherDef" };
  $pc{'battleAddMDef'} = $pc{'armamentTotalMDef'} + $pc{"battleSkillMDef"} + $pc{"battleOtherMDef"};
  $pc{'battleAddIni' } = $pc{'armamentTotalIni' } + $pc{"battleSkillIni" } + $pc{"battleOtherIni" };
  $pc{'battleAddMove'} = $pc{'armamentTotalMove'} + $pc{"battleSkillMove"} + $pc{"battleOtherMove"};

  $pc{'battleTotalAcc' } = $pc{'battleAddAcc' } + $pc{'rollDex'};
  $pc{'battleTotalAtk' } = $pc{'battleAddAtk' };
  $pc{'battleTotalEva' } = $pc{'battleAddEva' } + $pc{'rollAgi'};
  $pc{'battleTotalDef' } = $pc{'battleAddDef' };
  $pc{'battleTotalMDef'} = $pc{'battleAddMDef'} + $pc{'sttMndTotal'};
  $pc{'battleTotalIni' } = $pc{'battleAddIni' } + $pc{'sttAgiTotal'} + $pc{'sttSenTotal'};
  $pc{'battleTotalMove'} = $pc{'battleAddMove'} + $pc{'sttStrTotal'} + 5;
  
  if($pc{'battleTotalDef' } < 0){ $pc{'battleTotalDef' } = 0; }
  if($pc{'battleTotalMDef'} < 0){ $pc{'battleTotalMDef'} = 0; }
  
  $pc{'battleTotalAccR' } = $pc{'battleTotalAcc'} - $pc{"armamentHandLAcc"};
  $pc{'battleTotalAccL' } = $pc{'battleTotalAcc'} - $pc{"armamentHandRAcc"};
  $pc{'battleTotalAtkR' } = $pc{'battleTotalAtk'} - $pc{"armamentHandLAtk"};
  $pc{'battleTotalAtkL' } = $pc{'battleTotalAtk'} - $pc{"armamentHandRAtk"};
  
  $pc{'battleDiceAcc' } = $pc{'rollDexDice'} + $pc{'battleSkillAccDice'} + $pc{'battleOtherAccDice'};
  $pc{'battleDiceAtk' } = $pc{'rollStrDice'} + $pc{'battleSkillAtkDice'} + $pc{'battleOtherAtkDice'};
  $pc{'battleDiceEva' } = $pc{'rollAgiDice'} + $pc{'battleSkillEvaDice'} + $pc{'battleOtherEvaDice'};
  
  ### 特殊な判定 --------------------------------------------------
  $pc{'rollTrapDetectAdd'  } = $pc{'rollTrapDetectSkill'}   + $pc{'rollTrapDetectOther'};
  $pc{'rollTrapReleaseAdd' } = $pc{'rollTrapReleaseSkill'}  + $pc{'rollTrapReleaseOther'};
  $pc{'rollDangerDetectAdd'} = $pc{'rollDangerDetectSkill'} + $pc{'rollDangerDetectOther'};
  $pc{'rollEnemyLoreAdd'   } = $pc{'rollEnemyLoreSkill'}    + $pc{'rollEnemyLoreOther'};
  $pc{'rollAppraisalAdd'   } = $pc{'rollAppraisalSkill'}    + $pc{'rollAppraisalOther'};
  $pc{'rollMagicAdd'       } = $pc{'rollMagicSkill'}        + $pc{'rollMagicOther'};
  $pc{'rollSongAdd'        } = $pc{'rollSongSkill'}         + $pc{'rollSongOther'};
  $pc{'rollAlchemyAdd'     } = $pc{'rollAlchemySkill'}      + $pc{'rollAlchemyOther'};
  
  $pc{'rollTrapDetect'  } = $pc{'rollSen'} + $pc{'rollTrapDetectAdd'  };
  $pc{'rollTrapRelease' } = $pc{'rollDex'} + $pc{'rollTrapReleaseAdd' };
  $pc{'rollDangerDetect'} = $pc{'rollSen'} + $pc{'rollDangerDetectAdd'};
  $pc{'rollEnemyLore'   } = $pc{'rollInt'} + $pc{'rollEnemyLoreAdd'   };
  $pc{'rollAppraisal'   } = $pc{'rollInt'} + $pc{'rollAppraisalAdd'   };
  $pc{'rollMagic'       } = $pc{'rollInt'} + $pc{'rollMagicAdd'       };
  $pc{'rollSong'        } = $pc{'rollMnd'} + $pc{'rollSongAdd'        };
  $pc{'rollAlchemy'     } = $pc{'rollDex'} + $pc{'rollAlchemyAdd'     };
  
  $pc{'rollTrapDetectDice'  } = $pc{'rollSenDice'} + $pc{'rollTrapDetectDiceAdd'  };
  $pc{'rollTrapReleaseDice' } = $pc{'rollDexDice'} + $pc{'rollTrapReleaseDiceAdd' };
  $pc{'rollDangerDetectDice'} = $pc{'rollSenDice'} + $pc{'rollDangerDetectDiceAdd'};
  $pc{'rollEnemyLoreDice'   } = $pc{'rollIntDice'} + $pc{'rollEnemyLoreDiceAdd'   };
  $pc{'rollAppraisalDice'   } = $pc{'rollIntDice'} + $pc{'rollAppraisalDiceAdd'   };
  $pc{'rollMagicDice'       } = $pc{'rollIntDice'} + $pc{'rollMagicDiceAdd'       };
  $pc{'rollSongDice'        } = $pc{'rollMndDice'} + $pc{'rollSongDiceAdd'        };
  $pc{'rollAlchemyDice'     } = $pc{'rollDexDice'} + $pc{'rollAlchemyDiceAdd'     };
  
  ### 傾向重量計算 --------------------------------------------------
  {
    my $items = $pc{'items'};
    my $ab = $skill{'アストラルボディ'};
    my $fs = $skill{'ファランクススタイル'};
    my $el = $skill{'エンラージリミット'};
    $pc{'weightItems'} = 0;
    $pc{'weightLimitWeapon'} = $pc{'stt'.($ab || 'Str').'Base'} + $pc{'weightLimitAddWeapon'};
    $pc{'weightLimitArmour'} = ($fs && $ab ? max($pc{'stt'.$fs.'Base'}, $pc{'sttMndBase'})
                             : $pc{'stt'.($fs || $ab || 'Str').'Base'}
                             ) + $pc{'weightLimitAddArmour'};
    $pc{'weightLimitItems'}  = ($el && $ab ? max($pc{'sttStrBase'}*2, $pc{'sttMndBase'})
                             :  $el        ? $pc{'sttStrBase'} * 2
                             :  $ab        ? $pc{'sttMndBase'}
                             :  $pc{'sttStrBase'}
                             ) + $pc{'weightLimitAddItems'};
    $items =~ s/[@＠]\[\s*?((?:[\+\-\*\/]?[0-9]+)+)\s*?\]/$pc{'weightItems'} += eval($1)/eg;
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
  foreach my $s ('Str','Dex','Agi','Int','Sen','Mnd','Luk'){
    foreach my $type ('Make','BaseAdd','Main','Support','Add'){
      delete $pc{'stt'.$s.$type} if !$pc{'stt'.$s.$type};
    }
    delete $pc{'roll'.$s.'Add'} if !$pc{'roll'.$s.'Add'};
  }
  #### 改行を<br>に変換 --------------------------------------------------
  foreach (
    'words',
    'items',
    'freeNote',
    'freeHistory',
    'cashbook',
    'chatPalette',
    'armamentHandRNote',
    'armamentHandLNote',
    'armamentHeadNote',
    'armamentBodyNote',
    'armamentSubNote',
    'armamentOtherNote',
    'battleSkillNote',
    'battleOtherNote',
  ){
    $pc{$_} =~ s/\r\n?|\n/<br>/g;
  }
  foreach my $i (1 .. $pc{'geisesNum'}){
    $pc{"geis${i}Note"} =~ s/\r\n?|\n/<br>/g;
  }
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{'tags'} = pcTagsEscape($pc{'tags'});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{'historyNum'}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{"lastSession"} = tag_delete tag_unescape $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my $charactername = ($pc{'aka'} ? "“$pc{'aka'}”" : "").$pc{'characterName'};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  my $race = $pc{'race'} eq 'free' ? $pc{'raceFree'} : $pc{'race'};
  $pc{'lastSession'} = tag_delete tag_unescape $pc{'lastSession'};
  $::newline = "$pc{'id'}<>$::file<>".
               "$pc{'birthTime'}<>$::now<>$charactername<>$pc{'playerName'}<>$pc{'group'}<>".
               "$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<>".

               "$race<>$pc{'gender'}<>$pc{'age'}<>".
               "$pc{'expTotal'}<>$pc{'level'}<>".
               "$pc{'classMain'}/$pc{'classSupport'}/$pc{'classTitle'}<>".
               "$pc{'homeArea'}<> $pc{'areaTags'} <>$pc{'guildName'}<>$pc{'payment'}<>".
               "$pc{'lastSession'}<>";

  return %pc;
}

1;