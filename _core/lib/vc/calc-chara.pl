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
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }

  ### 戦果点 --------------------------------------------------
  foreach my $num (0 .. $pc{historyNum}){ $pc{resultPoint} += s_eval($pc{"history${num}Result"}); }
  $pc{historyResultTotal} = $pc{resultPoint};
  foreach my $num (0 .. $pc{goodsNum  }){ $pc{resultPoint} -= $pc{"goods${num}Cost"}; }
  foreach my $num (0 .. $pc{itemsNum  }){ $pc{resultPoint} -= $pc{"item${num}Cost"}; }

  ### 能力値 --------------------------------------------------
  $pc{staminaMax} = 5 + $pc{vitality} + $pc{staminaAdd};
  $pc{staminaHalf} = int($pc{staminaMax} / 2);

  foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
    $pc{'battleSubtotal'.$stt} = $pc{'battleBase'.$stt} + $pc{'battleRace'.$stt};
    $pc{'battleTotal'.$stt} = $pc{'battleSubtotal'.$stt};
    foreach my $type ('Weapon','Head','Body','Acc1','Acc2','Other'){
      $pc{'battleTotal'.$stt} += $pc{'battle'.$type.$stt};
    }
    $pc{'battleTotal'.$stt} += $pc{level};
  }
  $pc{hpMax} = $pc{battleTotalStr} + $pc{hpAdd};

  ### 0を消去 --------------------------------------------------
  foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
    foreach my $type ('Race','Weapon','Head','Body','Acc1','Acc2','Other'){
      delete $pc{'battle'.$type.$stt} if !$pc{'battle'.$type.$stt};
    }
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
  $pc{tags} = pcTagsEscape($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = tagDelete tagUnescape $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my $charactername = ($pc{aka} ? "“$pc{aka}”" : "").$pc{characterName};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$charactername<>$pc{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>".

               "$pc{race}<>$pc{class}<>$pc{style1}／$pc{style2}<>".
               "$pc{level}<>$pc{resultPointsTotal}<>".
               "$pc{gender}<>$pc{age}<>$pc{height}<>$pc{lastSession}<>";

  return %pc;
}

1;