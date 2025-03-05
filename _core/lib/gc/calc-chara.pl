################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;

sub data_calc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }

  ### 経験点 --------------------------------------------------
  foreach my $num (0 .. $pc{historyNum}){ $pc{expTotal} += s_eval($pc{"history${num}Exp"}); }
  $pc{historyExpTotal} = $pc{expTotal};
  foreach my $level (2 .. $pc{level}){ $pc{expUsed} += $level * 10; }
  $pc{expRest} = $pc{expTotal} - $pc{expUsed};

  ### 装備 --------------------------------------------------
  foreach my $stt ('Weight','Acc','Init','Move','Guard'){
    $pc{"weaponTotal${stt}"} = 0;
    foreach my $category ('Main','Sub','Other'){
      $pc{"weaponTotal${stt}"} += $pc{"weapon${category}${stt}"};
    }
  }
  foreach my $stt ('Weight','Eva','DefWeapon','DefFire','DefShock','DefInternal','Init','Move'){
    $pc{"armorTotal${stt}"} = 0;
    foreach my $category ('Main','Sub','Other'){
      $pc{"armorTotal${stt}"} += $pc{"armor${category}${stt}"};
    }
  }
  foreach my $num (1 .. $pc{itemNum}){
    $pc{"itemsTotalWeight"} += $pc{"item${num}Weight"} * $pc{"item${num}Quantity"};
  }
  $pc{sttInitEquip} = $pc{weaponTotalInit} + $pc{armorTotalInit};
  $pc{sttMoveEquip} = $pc{weaponTotalMove} + $pc{armorTotalMove};
  
  $pc{totalWeight} = $pc{weaponTotalWeight} + $pc{armorTotalWeight} + $pc{itemsTotalWeight};

  ### 乗騎 --------------------------------------------------
  {
    my $num = 1;
    $pc{vehicleTotalAtk}        = $pc{"vehicle${num}Atk"};
    $pc{vehicleTotalAcc}        = $pc{"vehicle${num}Acc"}        + $pc{weaponTotalAcc};
    $pc{vehicleTotalEva}        = $pc{"vehicle${num}Eva"}        + $pc{armorTotalEva};
    $pc{vehicleTotalDefWeapon  }= $pc{"vehicle${num}DefWeapon"  }+ $pc{armorTotalDefWeapon};
    $pc{vehicleTotalDefFire    }= $pc{"vehicle${num}DefFire"    }+ $pc{armorTotalDefFire};
    $pc{vehicleTotalDefShock   }= $pc{"vehicle${num}DefShock"   }+ $pc{armorTotalDefShock};
    $pc{vehicleTotalDefInternal}= $pc{"vehicle${num}DefInternal"}+ $pc{armorTotalDefInternal};
    $pc{vehicleTotalInit}       = $pc{"vehicle${num}Init"}       + $pc{sttInitEquip};
    $pc{vehicleTotalMove}       = $pc{"vehicle${num}Move"}       + $pc{sttMoveEquip};
  }

  ### 能力値 --------------------------------------------------
  foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
    $pc{"stt${stt}Total"} = 0;
    foreach my $i (2 .. $pc{level}){
      $pc{"stt${stt}Grow"} += $pc{"stt${stt}Grow${i}"};
    }
    foreach my $type ('Works','Make','Grow','Mod'){
      $pc{"stt${stt}Total"} += $pc{"stt${stt}${type}"};
    }
    $pc{"stt${stt}CheckBase"}  = int($pc{"stt${stt}Total"} / 3);
    $pc{"stt${stt}CheckTotal"} = $pc{"stt${stt}CheckBase"} + $pc{"stt${stt}Style"};
  }
  # HP/MP
  $pc{sttHpTotal} = $pc{sttStrWorks} +  $pc{sttStrMake};
  $pc{sttMpTotal} = $pc{sttMndWorks} +  $pc{sttMndMake};
  foreach ('Hp','Mp'){
    $pc{"stt${_}Total"} += $pc{"stt${_}Works"} + $pc{"stt${_}Style"} + $pc{"stt${_}Mod"};
    if($pc{level} > 1){ $pc{"stt${_}Total"} += ($pc{level} - 1) * $pc{"stt${_}GrowStyle"} }
  }
  # 行動値
  $pc{sttInitTotal} = int(($pc{sttPerTotal} + $pc{sttIntTotal}) / 2) + $pc{sttInitEquip} + $pc{sttInitMod};
  # 移動力
  $pc{sttMoveBase} = $pc{sttRefTotal} + $pc{sttMoveEquip} + $pc{sttMoveMod};
  $pc{sttMoveTotal} = int($pc{sttMoveBase} / 5) + 1;
  # 重量
  $pc{sttMaxWeight} = $pc{sttStrTotal}*2 + $pc{sttMaxWeightMod};
  # 天運
  $pc{sttFateTotal} = 3 + $pc{sttFateMod};

  ### 技能 --------------------------------------------------
  foreach my $stt ("Str","Ref","Per","Int","Mnd","Emp"){
    my $i = 1;
    foreach my $skill (@{$set::skill{$stt}}){
      if   ($pc{"skill${stt}${i}Lv"} < 2){ $pc{"skill${stt}${i}Lv"} = 2; }
      elsif($pc{"skill${stt}${i}Lv"} > 5){ $pc{"skill${stt}${i}Lv"} = 5; }
      $pc{"skill${stt}${i}Label"} = $skill;
      $i++;
    }
  }

  ### 0を消去 --------------------------------------------------
  foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
    foreach my $type ('Make','Other'){
      delete $pc{"stt${stt}${type}"} if !$pc{"stt${stt}${type}"};
    }
  }
  foreach my $stt ('Hp','Mp','Init','Move','Weight','Fate'){
    delete $pc{"stt${stt}Other"} if !$pc{"stt${stt}Other"};
  }
  #### 改行を<br>に変換 --------------------------------------------------
  foreach (
    'words',
    'freeNote',
    'freeHistory',
    'chatPalette',
  ){
    $pc{$_} =~ s/\r\n?|\n/<br>/g;
  }
  
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
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$charactername<>$pc{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>".

               "$pc{class}<>$pc{style}<>$pc{styleSub}<>$pc{works}<>".
               "$pc{level}<>$pc{expTotal}<>".
               "$pc{country}<>$pc{gender}<>$pc{age}<>$pc{height}<>$pc{weight}<>".
               "$pc{lastSession}<>";

  return %pc;
}

1;