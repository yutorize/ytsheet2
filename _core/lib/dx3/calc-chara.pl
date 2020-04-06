################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_syndrome;
my %awakens;
my %impulses;
$awakens{@$_[0]} = @$_[1] foreach(@data::awakens);
$impulses{@$_[0]} = @$_[1] foreach(@data::impulses);

sub data_calc {
  my %pc = %{$_[0]};
  
  ### 能力値 --------------------------------------------------
  my %status = (0=>'body', 1=>'sense', 2=>'mind', 3=>'social');
  foreach my $num (keys %status){
    my $name = $status{$num};
    my $Name = ucfirst $name;
    my $base = 0;
    $base += $data::syndrome_status{$pc{'syndrome1'}}[$num];
    $base += $pc{'syndrome2'} ? $data::syndrome_status{$pc{'syndrome2'}}[$num] : $base;
    if($name eq $pc{'sttWorks'}){ $base++; }
    
    $pc{'sttTotal'.$Name} = $base + $pc{'sttGrow'.$Name} + $pc{'sttAdd'.$Name};
    # 経験点
    for (my $i = $base; $i < $base+$pc{'sttGrow'.$Name}; $i++){
      $pc{'expUsedStatus'} += ($i > 20) ? 30 : ($i > 10) ? 20 : 10;
    }
  }
  ### 副能力値 --------------------------------------------------
  $pc{'maxHpTotal'}      = $pc{'sttTotalBody'}  * 2 + $pc{'sttTotalMind'} + 20 + $pc{'maxHpAdd'};
  $pc{'initiativeTotal'} = $pc{'sttTotalSense'} * 2 + $pc{'sttTotalMind'} + $pc{'initiativeAdd'};
  $pc{'moveTotal'} = $pc{'initiativeTotal'} + 5 + $pc{'moveAdd'};
  $pc{'dashTotal'} = $pc{'moveTotal'} * 2 + $pc{'dashAdd'};
  $pc{'stockTotal'} = $pc{'sttTotalSocial'} * 2 + $pc{'skillProcure'} * 2 + $pc{'stockAdd'};
  $pc{'savingTotal'} = $pc{'stockTotal'} + $pc{'savingAdd'};
  
  ### 技能 --------------------------------------------------
  # 経験点
  $pc{'expUsedSkill'} = -9; #ワークス取得ぶん
  foreach my $name ('Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure'){
    my $lv = $pc{'skill'.$name};
    for(my $i = 0; $i < $lv; $i++){ $pc{'expUsedSkill'} += ($i > 20) ? 10 : ($i > 10) ? 5 : ($i > 5) ? 3 : 2; }
      if($pc{'skill'.$name} && $pc{'skill'.$name}){ $pc{'skillTotal'.$name} = $pc{'skill'.$name} + $pc{'skillAdd'.$name}; }
  }
  foreach my $name ('Ride','Art','Know','Info'){
    foreach my $num (1 .. $pc{'skillNum'}){
      my $lv = $pc{'skill'.$name.$num};
      for(my $i = 0; $i < $lv; $i++){ $pc{'expUsedSkill'} += ($i > 20) ? 10 : ($i > 10) ? 5 : ($i > 5) ? 3 : 1; }
      if($pc{'skill'.$name.$num} && $pc{'skill'.$name.$num}){ $pc{'skillTotal'.$name.$num} = $pc{'skill'.$name.$num} + $pc{'skillAdd'.$name.$num}; }
    }
  }
  
  ### エフェクト --------------------------------------------------
  foreach my $num (1 .. $pc{'effectNum'}){
    my $type = $pc{'effect'.$num.'Type'};
    my $lv = $pc{'effect'.$num.'Lv'};
    if($lv >= 1){
      # イージー
      if($type eq 'easy'){
        $pc{'expUsedEffect'} += $lv * 2;
      }
      # 通常
      else {
        $pc{'expUsedEffect'} += $lv * 5 + 10; #lv×5 + 新規取得の差分10
        if($type =~ /^(auto|dlois)$/i){ $pc{'expUsedEffect'} += -15; } #自動かDロイスは新規取得ぶん減らす
      }
    }
  }
  
  ### アイテム --------------------------------------------------
  foreach my $num (1 .. $pc{'weaponNum'}){
    $pc{'stockUsed'}   += $pc{"weapon${num}Stock"};
    $pc{'expUsedItem'} += $pc{"weapon${num}Exp"};
  }
  foreach my $num (1 .. $pc{'armorNum'}){
    $pc{'stockUsed'}   += $pc{"armor${num}Stock"};
    $pc{'expUsedItem'} += $pc{"armor${num}Exp"};
  }
  foreach my $num (1 .. $pc{'vehicleNum'}){
    $pc{'stockUsed'}   += $pc{"vehicle${num}Stock"};
    $pc{'expUsedItem'} += $pc{"vehicle${num}Exp"};
  }
  foreach my $num (1 .. $pc{'itemNum'}){
    $pc{'stockUsed'}   += $pc{"item${num}Stock"};
    $pc{'expUsedItem'} += $pc{"item${num}Exp"};
  }
  $pc{'savingTotal'} -= $pc{'stockUsed'}; 
  
  ### 侵蝕率 --------------------------------------------------
  $pc{'lifepathAwakenEncroach'}  = $awakens{$pc{'lifepathAwaken'}};
  $pc{'lifepathImpulseEncroach'} = $impulses{$pc{'lifepathImpulse'}};
  $pc{'baseEncroach'} = $pc{'lifepathAwakenEncroach'} + $pc{'lifepathImpulseEncroach'} + $pc{'lifepathOtherEncroach'};
  
  ### ロイス --------------------------------------------------
  my @dloises;
  foreach my $num (1..7){
    if($pc{"lois${num}Relation"} =~ /[DＤ]ロイス/){
      $pc{"lois${num}Name"} =~ s#/#／#g;
      push(@dloises, $pc{"lois${num}Name"});
    }
  }
  ### メモリー --------------------------------------------------
  $pc{'expUsedMemory'} = 0;
  foreach my $num (1..3){
    if($pc{"memory${num}Gain"}){
      $pc{'expUsedMemory'} += 15;
    }
  }

  ### 経験点 --------------------------------------------------
  ## 履歴から 
  foreach my $i (0 .. $pc{'historyNum'}){
    $pc{'expTotal'} += s_eval($pc{"history${i}Exp"});
  }

  ## 経験点消費
  $pc{'expRest'} = $pc{'expTotal'};
  $pc{'expUsed'} = $pc{'expUsedStatus'} + $pc{'expUsedSkill'} + $pc{'expUsedEffect'} + $pc{'expUsedItem'} + $pc{'expUsedMemory'};
  $pc{'expRest'} -= $pc{'expUsed'};

  ### 0を消去 --------------------------------------------------
  foreach (
    'skillMelee','skillRanged','skillRC','skillNegotiate',
    'skillDodge','skillPercept','skillWill','skillProcure',
    'skillAddMelee','skillAddRanged','skillAddRC','skillAddNegotiate',
    'skillAddDodge','skillAddPercept','skillAddWill','skillAddProcure',
  ){
    delete $pc{$_} if !$pc{$_};
  }
  foreach (
    'skillRide','skillArt','skillKnow','skillInfo',
    'skillAddRide','skillAddArt','skillAddKnow','skillAddInfo',
  ){
    foreach my $num (1..$pc{'skillNum'}){
      delete $pc{$_.$num} if !$pc{$_.$num};
    }
  }

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{'freeNote'}      =~ s/\r\n?|\n/<br>/g;
  $pc{'freeHistory'}   =~ s/\r\n?|\n/<br>/g;
  $pc{'chatPalette'}   =~ s/\r\n?|\n/<br>/g;
  $pc{"combo${_}Note"}   =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{'comboNum'});
  $pc{"weapon${_}Note"}  =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{'weaponNum'});
  $pc{"armor${_}Note"}   =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{'armorNum'});
  $pc{"vehicle${_}Note"} =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{'vehicleNum'});
  $pc{"item${_}Note"}    =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{'itemNum'});

  ### newline --------------------------------------------------
  my($name, undef) = split(/:/,$pc{'characterName'});
  my($aka,  undef) = split(/:/,$pc{'aka'});
  my $charactername = ($aka?"“$aka”":"").$name;
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $_ =~ s/[|｜]([^|｜]+?)《.+?》/$1/g foreach (@dloises);
  $_ =~ s/[:：].+?$//g foreach (@dloises);
  $::newline = "$pc{'id'}<>$::file<>".
               "$pc{'birthTime'}<>$::now<>$charactername<>$pc{'playerName'}<>$pc{'group'}<>".
               "$pc{'expTotal'}<>$pc{'gender'}<>$pc{'age'}<>$pc{'sign'}<>$pc{'blood'}<>$pc{'works'}<>".
               
               "$pc{'syndrome1'}/$pc{'syndrome2'}/$pc{'syndrome3'}<>".
               join('/',@dloises).'<>'.
               
               "$pc{'sessionTotal'}<>$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<><>";

  return %pc;
}

1;