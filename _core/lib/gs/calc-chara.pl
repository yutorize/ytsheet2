################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;
require $set::data_races;

sub data_calc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }

  ### 経験点／名誉点／所持金計算 --------------------------------------------------
  ## 履歴から 
  $pc{moneyTotal}   = 0;
  $pc{depositTotal} = 0;
  $pc{debtTotal}    = 0;
  $pc{expTotal}   = s_eval($pc{history0Exp});
  $pc{adpTotal}   = s_eval($pc{history0Adp}) + $pc{adpFromExp};
  $pc{moneyTotal} = s_eval($pc{history0Money});
  $pc{adventures} = s_eval($pc{history0Adventures}) || 0;
  $pc{completed}  = s_eval($pc{history0Completed}) || 0;
  foreach my $i (1 .. $pc{historyNum}){
    $pc{adventures}++ if $pc{"history${i}Completed"};
    $pc{completed}++  if $pc{"history${i}Completed"} > 0;
    $pc{expTotal}   += s_eval($pc{"history${i}Exp"});
    $pc{adpTotal}   += s_eval($pc{"history${i}Adp"});
    $pc{moneyTotal} += s_eval($pc{"history${i}Money"});
  }
  $pc{historyExpTotal} = $pc{expTotal};
  $pc{historyAdpTotal} = $pc{adpTotal};
  $pc{historyMoneyTotal} = $pc{moneyTotal};
  ## 収支履歴計算
  my $cashbook = $pc{"cashbook"};
  $cashbook =~ s/::((?:[\+\-\*\/]?[0-9,]+)+)/$pc{'moneyTotal'} += s_eval($1)/eg;
  $cashbook =~ s/:>((?:[\+\-\*\/]?[0-9,]+)+)/$pc{'depositTotal'} += s_eval($1)/eg;
  $cashbook =~ s/:<((?:[\+\-\*\/]?[0-9,]+)+)/$pc{'debtTotal'} += s_eval($1)/eg;
  $pc{moneyTotal} += $pc{debtTotal} - $pc{depositTotal};

  ## 貨幣
  if(!$pc{moneyAllCoins}){ $pc{moneyGold} = $pc{moneyLargeGold} = 0 }

  ## 経験点消費
  my @exp = ( 0, 1000, 2000, 3500, 5500, 8000, 11500, 16500, 23500, 33000, 45500 );
  $pc{expUsed} = 0;
  foreach (@data::class_names){
    my $id = $data::class{$_}{'id'};
    $pc{'expUsed'.$id} = $exp[$pc{'lv'.$id}] - ($_ eq $pc{careerOriginClass} ? 1000 : 0);
    $pc{expUsed}      += $pc{'expUsed'.$id};
  }
  $pc{expUsed} += $pc{adpFromExp} * 500;
  $pc{expRest} = $pc{expTotal} - $pc{expUsed};
  
  ## 冒険者レベル／成長点
  my %adventurerExpTable = (
       0 => { lv=> 1, pt=> 10 },
    4000 => { lv=> 2, pt=> 15 },
    7000 => { lv=> 3, pt=> 15 },
   11000 => { lv=> 4, pt=> 20 },
   16000 => { lv=> 5, pt=> 20 },
   23000 => { lv=> 6, pt=> 25 },
   33000 => { lv=> 7, pt=> 25 },
   47000 => { lv=> 8, pt=> 30 },
   66000 => { lv=> 9, pt=> 30 },
   91000 => { lv=>10, pt=> 35 },
  );
  foreach my $key (sort {$a <=> $b} keys %adventurerExpTable){
    if($pc{'expTotal'} >= $key) {
      $pc{level}     = $adventurerExpTable{$key}{lv};
      $pc{adpTotal} += $adventurerExpTable{$key}{pt};
    }
    else { last; }
  }
  ## 技能の成長点消費
  my %gradeToPtA = (
    '初歩'=>  5,
    '習熟'=> 15,
    '熟練'=> 30,
    '達人'=> 55,
    '伝説'=> 95,
  );
  my %gradeToPtG = (
    '初歩'=>  1,
    '習熟'=>  6,
    '熟練'=> 21,
  );
  $pc{adpUsed} = 0;
  foreach my $i (1 .. $pc{skillNum}){
    my $grade = $pc{"skill${i}Grade"};
    my $point = 0;
    if($grade){
      $point = $gradeToPtA{$grade};
      if($pc{"skill${i}Auto"}){ $point -= 5 }
      $pc{adpUsed} += $point;
      $pc{"skill${i}Adp"} = $point;
    }
  }
  foreach my $i (1 .. $pc{generalSkillNum}){
    my $grade = $pc{"generalSkill${i}Grade"};
    my $point = 0;
    if($grade){
      $point = $gradeToPtG{$grade};
      if($pc{"generalSkill${i}Auto"}){ $point -= 1 }
      $pc{adpUsed} += $point;
      $pc{"generalSkill${i}Adp"} = $point;
    }
  }
  $pc{adpRest} = $pc{adpTotal} - $pc{adpUsed};

  ### 能力値計算  --------------------------------------------------
  ## 能力値算出
  foreach my $primary ('Str','Psy','Tec','Int'){
    $pc{"ability1${primary}"} =
    + $pc{"ability1${primary}Base"}
    + $pc{"ability1${primary}Mod"}
    + ($pc{ability1Bonus} eq $primary ? 1 : 0);
  }
  foreach my $secondary ('Foc','Edu','Ref'){
    $pc{"ability2${secondary}"} =
    + $pc{"ability2${secondary}Base"}
    + $pc{"ability2${secondary}Mod"};

    foreach my $primary ('Str','Psy','Tec','Int'){
      $pc{"ability${primary}${secondary}"} = $pc{"ability1${primary}"} + $pc{"ability2${secondary}"}
    }
  }

  ### 状態 --------------------------------------------------
  {
    ## 生命力
    $pc{statusLife} = $pc{statusLifeDice} + $pc{ability1Str} + $pc{ability1Psy} + $pc{ability2Edu} + $pc{statusLifeMod};
    $pc{statusLifeX2} = $pc{statusLife} *2;

    ## 移動力
    my ($race, $raceB, $raceV, $raceBV);
    ($race  = $pc{race    }) =~ s/:(.+?)$/$raceV  = $1; ''/e;
    ($raceB = $pc{raceBase}) =~ s/:(.+?)$/$raceBV = $1; ''/e;
    $pc{statusMoveRace}
      = ($race && $data::races{$race}{move} eq 'base' && $raceB && $data::races{$raceB}{move} eq 'variant') ? ($raceBV ? $data::races{$raceB}{variantData}{$raceBV}{move} : 0)
      : ($race && $data::races{$race}{move} eq 'base'   ) ? ($raceB ? $data::races{$raceB}{move} : 0)
      : ($race && $data::races{$race}{move} eq 'variant') ? ($raceV ? $data::races{$race}{variantData}{$raceV}{move} : 0)
      : ($race) ? $data::races{$race}{move} 
      : 0;
    $pc{statusMove} = $pc{statusMoveDice} * $pc{statusMoveRace} + $pc{statusMoveMod};

    ## 呪文使用回数
    $pc{statusSpellBase} = ($pc{statusSpellDice} >= 12) ? 3
                         : ($pc{statusSpellDice} >= 10) ? 2
                         : ($pc{statusSpellDice} >=  7) ? 1
                         : 0;
    $pc{statusSpell} = $pc{statusSpellBase} + $pc{statusSpellMod};

    ## 呪文抵抗基準値
    $pc{statusResist} = $pc{abilityPsyRef} + $pc{level};
  }
  
  ### 呪文行使 --------------------------------------------------
  foreach my $name (grep { $data::class{$_}{type} =~ /spell/ } @data::class_names){
    my $id = $data::class{$name}{id};
    if($pc{'lv'.$id}){
      $pc{'spellCast'.$id} = $pc{'ability'.$data::class{$name}{cast}} + $pc{'lv'.$id} + $pc{spellCastModValue};
    }
  }
  
  ### 攻撃 --------------------------------------------------
  ## 職業
  foreach my $class (grep { $data::class{$_}{type} =~ /warrior/ } @data::class_names){
    my $id = $data::class{$class}{id};
    foreach my $type ('Melee','Throwing','Projectile'){
      if($data::class{$class}{proper}{hitscore} =~ /$type/){ 
        $pc{'hitScore'.$id.$type} = $pc{'lv'.$id} + $pc{abilityTecFoc} + $pc{'hitScoreMod'.$type};
      }
    }
  }
  ## 武器
  foreach (1 .. $pc{'weaponNum'}){
    my $name  = $pc{'weapon'.$_.'Class'};
    my $class = $data::class{$name}{'id'};
    my $type  = $set::weapon_type{$pc{'weapon'.$_.'Type'}};
    ## 命中
    $pc{'weapon'.$_.'HitTotal'} = $pc{abilityTecFoc} + $pc{'hitScoreMod'.$type} + $pc{'weapon'.$_.'HitMod'} + $pc{'lv'.$class};
  }

  ### 回避 --------------------------------------------------
  ## 職業
  $pc{dodgeClassLv} = $pc{'lv'. $data::class{$pc{dodgeClass}}{'id'} };
  ## 防具
  foreach (1){
    $pc{'armor'.$_.'DodgeTotal'} = $pc{abilityTecRef} + $pc{dodgeModValue} + $pc{'armor'.$_.'DodgeMod'} + $pc{dodgeClassLv};
    $pc{'armor'.$_.'MoveTotal'} = $pc{statusMove} + $pc{'armor'.$_.'MoveMod'};
  }

  ### 盾受け --------------------------------------------------
  ## 職業
  $pc{blockClassLv} = $pc{'lv'. $data::class{$pc{blockClass}}{'id'} };
  foreach (1){
    $pc{'shield'.$_.'BlockTotal'} = $pc{abilityTecRef} + $pc{blockModValue} + $pc{'shield'.$_.'BlockMod'} + $pc{blockClassLv};
    $pc{'shield'.$_.'ArmorTotal'} = $pc{armor1Armor} + $pc{'shield'.$_.'Armor'};
  }

  ### 0を消去 --------------------------------------------------
  foreach (@data::class_names){
    my $id = $data::class{$_}{'id'};
    delete $pc{'lv'.$id} if !$pc{'lv'.$id};
  }
  foreach (
    'statusLifeMod',
    'statusMoveMod',
    'statusSpellMod',
    'statusResistMod',
  ){
    delete $pc{$_} if !$pc{$_};
  }

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{'words'}         =~ s/\r\n?|\n/<br>/g;
  $pc{'items'}         =~ s/\r\n?|\n/<br>/g;
  $pc{'freeNote'}      =~ s/\r\n?|\n/<br>/g;
  $pc{'freeHistory'}   =~ s/\r\n?|\n/<br>/g;
  $pc{'cashbook'}      =~ s/\r\n?|\n/<br>/g;
  $pc{'chatPalette'}   =~ s/\r\n?|\n/<br>/g;
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{'tags'} = pcTagsEscape($pc{'tags'});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{'historyNum'}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{"lastSession"} = tagDelete tagUnescape $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my $charactername = ($pc{'aka'} ? "“$pc{'aka'}”" : "").$pc{'characterName'};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  my $classlv;
  foreach my $class (@data::class_list){
    $classlv .= $pc{'lv'.$data::class{$class}{'id'}}.'/';
  }
  my $race     = ($pc{race}     && $pc{raceFree}    ) ? "$pc{race}($pc{raceFree})"         : $pc{race}     || $pc{raceFree};
  my $raceBase = ($pc{raceBase} && $pc{raceBaseFree}) ? "$pc{raceBase}($pc{raceBaseFree})" : $pc{raceBase} || $pc{raceBaseFree};
  $race     =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $raceBase =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  my $faith = tagDelete tagUnescape $pc{faith};
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$charactername<>$pc{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>$pc{lastSession}<>".

               "$pc{expTotal}<>$pc{level}<>$classlv<>".
               "$race<>$raceBase<>$pc{gender}<>$pc{age}<>$pc{rank}<>$pc{faith}<>";

  return %pc;
}

1;