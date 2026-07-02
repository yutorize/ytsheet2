################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_syndrome;
my %awakens;
my %impulses;
$awakens{@$_[0]} = @$_[1] foreach(@data::awakens);
$impulses{@$_[0]} = @$_[1] foreach(@data::impulses);

sub dataCalc {
  my %pc = %{$_[0]};
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = upgradeCharaData(\%pc);
  }
  
  ### 能力値 --------------------------------------------------
  my %status = (0=>'body', 1=>'sense', 2=>'mind', 3=>'social');
  $pc{expUsedStatus} = 0;
  $pc{fpUsedStatus}  = 0;
  foreach my $num (keys %status){
    my $name = $status{$num};
    my $Name = ucfirst $name;
    my $base = 0;
    if($data::syndrome_status{$pc{syndrome1}}){ $pc{'sttSyn1'.$Name} = $data::syndrome_status{$pc{syndrome1}}[$num] }
    if($data::syndrome_status{$pc{syndrome2}}){ $pc{'sttSyn2'.$Name} = $data::syndrome_status{$pc{syndrome2}}[$num] }
    $base += $pc{'sttSyn1'.$Name};
    $base += $pc{syndrome2} ? $pc{'sttSyn2'.$Name} : $base;
    $pc{'sttBase'.$Name} = $base;
    if($name eq $pc{sttWorks}){ $base++; }
    
    $pc{'sttTotal'.$Name} = $base + $pc{'sttGrow'.$Name} + $pc{'sttAdd'.$Name};
    # 経験点
    for (my $i = $base; $i < $base+$pc{'sttGrow'.$Name}; $i++){
      $pc{expUsedStatus} += ($i > 20) ? 30 : ($i > 10) ? 20 : 10;
      $pc{fpUsedStatus}++;
    }
  }
  if($pc{fpUsedStatus} > 3){ $pc{fpUsedStatus} = 3 }
  ### 副能力値 --------------------------------------------------
  $pc{maxHpTotal}      = $pc{sttTotalBody}  * 2 + $pc{sttTotalMind} + 20 + $pc{maxHpAdd};
  $pc{initiativeTotal} = $pc{sttTotalSense} * 2 + $pc{sttTotalMind} + $pc{initiativeAdd};
  $pc{moveTotal} = $pc{initiativeTotal} + 5 + $pc{moveAdd};
  $pc{dashTotal} = $pc{moveTotal} * 2 + $pc{dashAdd};
  $pc{stockTotal} = $pc{sttTotalSocial} * 2 + $pc{skillProcure} * 2 + $pc{stockAdd};
  $pc{savingTotal} = $pc{stockTotal} + $pc{savingAdd};
  $pc{magicTotal}  = ceil(($pc{sttTotalMind} + $pc{skillWill} + $pc{skillAddWill}) / 2) + $pc{magicAdd};
  
  ### 技能 --------------------------------------------------
  my %skill_name_to_id = (
    '白兵' => 'Melee',
    '射撃' => 'Ranged',
    'RC' => 'RC',
    '交渉' => 'Negotiate',
    '回避' => 'Dodge',
    '知覚' => 'Percept',
    '意志' => 'Will',
    '調達' => 'Procure',
  );
  # 経験点
  $pc{expUsedSkill} = -9; #ワークス取得ぶん
  foreach my $name ('Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure'){
    my $lv = $pc{'skill'.$name};
    for(my $i = 0; $i < $lv; $i++){ $pc{expUsedSkill} += ($i > 20) ? 10 : ($i > 10) ? 5 : ($i > 5) ? 3 : 2; }
    if($pc{'skill'.$name} || $pc{'skillAdd'.$name}){ $pc{'skillTotal'.$name} = $pc{'skill'.$name} + $pc{'skillAdd'.$name}; }
    
  }
  foreach my $name ('Ride','Art','Know','Info'){
    foreach my $num (1 .. $pc{'skill'.$name.'Num'}){
      my $lv = $pc{'skill'.$name.$num};
      for(my $i = 0; $i < $lv; $i++){ $pc{expUsedSkill} += ($i > 20) ? 10 : ($i > 10) ? 5 : ($i > 5) ? 3 : 1; }
      if($pc{'skill'.$name.$num} || $pc{'skillAdd'.$name.$num}){ $pc{'skillTotal'.$name.$num} = $pc{'skill'.$name.$num} + $pc{'skillAdd'.$name.$num}; }
      $skill_name_to_id{$pc{'skill'.$name.$num.'Name'}} = $name.$num if $pc{'skill'.$name.$num.'Name'};
    }
  }
  $pc{fpUsedSkill} = $pc{expUsedSkill} / 2;
  if($pc{fpUsedSkill} > 5){ $pc{fpUsedSkill} = 5 }
  
  ### エフェクト --------------------------------------------------
  $pc{expUsedEffect} = 0;
  $pc{fpUsedEffect}  = 0;
  foreach my $num (1 .. $pc{effectNum}){
    my $type = $pc{'effect'.$num.'Type'};
    my $lv = $pc{'effect'.$num.'Lv'};
    if($lv >= 1){
      # イージー
      if($type eq 'easy'){
        $pc{expUsedEffect} += $lv * 2;
      }
      # 通常
      else {
        $pc{expUsedEffect} += $lv * 5 + 10; #lv×5 + 新規取得の差分10
        if($type =~ /^(auto|dlois)$/i){
          $pc{expUsedEffect} += -15; #自動かDロイスは新規取得ぶん減らす
          if($pc{createType} eq 'C' && $pc{'effect'.$num.'Name'} =~ /^コンセントレイト/ && $lv >= 2){
            $pc{expUsedEffect} += -5;
          }
        }
        else {
          $pc{fpUsedEffect}++;
        }
      }
    }
    $pc{expUsedEffect} += $pc{'effect'.$num.'Exp'};
  }
  if($pc{fpUsedEffect} > 4){ $pc{fpUsedEffect} = 4 }
  $pc{fpUsedEffectLv} = ($pc{expUsedEffect} - $pc{fpUsedEffect}*15) / 5;
  if($pc{fpUsedEffectLv} > 2){ $pc{fpUsedEffectLv} = 2 }

  ### 術式 --------------------------------------------------
  $pc{expUsedMagic} = 0;
  foreach my $num (1 .. $pc{magicNum}){
    $pc{expUsedMagic} += $pc{'magic'.$num.'Exp'};
  }
  
  ### コンボ --------------------------------------------------
  foreach my $num (1 .. $pc{comboNum}){
    my $name = $pc{"combo${num}Skill"};
    my $id = $skill_name_to_id{$name};
    my $lv = $pc{"skill${id}"} + $pc{"skillAdd${id}"};
    my $stt = do {
      my $stt;
      if($name && $id){
        if   ($id =~ /Melee|Dodge|Ride/)      { $stt = $pc{sttTotalBody}; }
        elsif($id =~ /Ranged|Percept|Art/)    { $stt = $pc{sttTotalSense}; }
        elsif($id =~ /RC|Will|Know/)          { $stt = $pc{sttTotalMind}; }
        elsif($id =~ /Negotiate|Procure|Info/){ $stt = $pc{sttTotalSocial}; }
      }
      if($pc{"combo${num}Stt"}){
        if   ($pc{"combo${num}Stt"} eq '肉体'){ $stt = $pc{sttTotalBody}; }
        elsif($pc{"combo${num}Stt"} eq '感覚'){ $stt = $pc{sttTotalSense}; }
        elsif($pc{"combo${num}Stt"} eq '精神'){ $stt = $pc{sttTotalMind}; }
        elsif($pc{"combo${num}Stt"} eq '社会'){ $stt = $pc{sttTotalSocial}; }
      }
      $stt;
    };
    if($pc{"combo${num}Manual"}){
      $lv = 0; $stt = 0;
    }
    foreach (1..5) {
      my $dadd = $pc{"combo${num}DiceAdd".$_};
      my $fadd = $pc{"combo${num}FixedAdd".$_};
      $pc{"combo${num}Dice" .$_} = ($stt && $dadd) ? optimizeOperator("$stt+$dadd") : ($stt||$dadd) if !$pc{"combo${num}Dice" .$_};
      $pc{"combo${num}Fixed".$_} = ($lv  && $fadd) ? optimizeOperator("$lv+$fadd" ) : ($lv ||$fadd) if !$pc{"combo${num}Fixed".$_};
    }
  }
  
  ### アイテム --------------------------------------------------
  foreach my $num (1 .. $pc{weaponNum}){
    $pc{stockUsed}   += $pc{"weapon${num}Stock"};
    $pc{expUsedItem} += $pc{"weapon${num}Exp"};
  }
  foreach my $num (1 .. $pc{armorNum}){
    $pc{stockUsed}   += $pc{"armor${num}Stock"};
    $pc{expUsedItem} += $pc{"armor${num}Exp"};
  }
  foreach my $num (1 .. $pc{vehicleNum}){
    $pc{stockUsed}   += $pc{"vehicle${num}Stock"};
    $pc{expUsedItem} += $pc{"vehicle${num}Exp"};
  }
  foreach my $num (1 .. $pc{itemNum}){
    $pc{stockUsed}   += $pc{"item${num}Stock"};
    $pc{expUsedItem} += $pc{"item${num}Exp"};
  }
  $pc{savingTotal} -= $pc{stockUsed}; 
  
  ### 侵蝕率 --------------------------------------------------
  $pc{lifepathAwakenEncroach}  = $awakens{$pc{lifepathAwaken}};
  $pc{lifepathImpulseEncroach} = $impulses{$pc{lifepathImpulse}};
  $pc{baseEncroach} = $pc{lifepathAwakenEncroach} + $pc{lifepathImpulseEncroach} + $pc{lifepathOtherEncroach};
  
  ### ロイス --------------------------------------------------
  my @dloises;
  foreach my $num (1..7){
    if($pc{"lois${num}Relation"} =~ /[DＤ]ロイス|^[DＤ]$/){
      $pc{"lois${num}Name"} =~ s#/#／#g;
      push(@dloises, $pc{"lois${num}Name"});
    }
  }
  ### メモリー --------------------------------------------------
  $pc{expUsedMemory} = 0;
  foreach my $num (1..3){
    if($pc{"memory${num}Relation"} || $pc{"memory${num}Name"}){
      $pc{expUsedMemory} += 15;
    }
  }

  ### 経験点 --------------------------------------------------
  ## 履歴から 
  $pc{expTotal} = $set::make_exp + $pc{history0Exp};
  foreach my $i (1 .. $pc{historyNum}){
    $pc{expTotal} += s_eval($pc{"history${i}Exp"}) if $pc{"history${i}ExpApply"};
  }
  $pc{expSpent} = $pc{expTotal} - 130;
  $pc{expBase} = 130;
  ## コンストラクション
  if($pc{createType} eq 'C'){
    $pc{expTotal} = $pc{expSpent};
    $pc{expBase} = '';
    if($pc{expUsedStatus} <= 30) { $pc{expUsedStatus} = 0 } else { $pc{expUsedStatus} -= 30 }
    if($pc{expUsedSkill}  <= 10) { $pc{expUsedSkill}  = 0 } else { $pc{expUsedSkill}  -= 10 }
    if($pc{expUsedEffect} <= 70) { $pc{expUsedEffect} = 0 } else { $pc{expUsedEffect} -= 70 }
  }
  ## 経験点消費
  $pc{expUsed} = $pc{expUsedStatus} + $pc{expUsedSkill} + $pc{expUsedEffect} + $pc{expUsedMagic} + $pc{expUsedItem} + $pc{expUsedMemory};
  $pc{expRest} = $pc{expTotal} - $pc{expUsed};

  $pc{createTypeName} = ($pc{createType} eq 'C') ? 'コンストラクション' : 'フルスクラッチ';

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
    'Ride','Art','Know','Info',
  ){
    foreach my $num (1..$pc{'skill'.$_.'Num'}){
      delete $pc{'skill'.$_.$num} if !$pc{'skill'.$_.$num};
      delete $pc{'skillAdd'.$_.$num} if !$pc{'skillAdd'.$_.$num};
    }
  }

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{'words'.$_} =~ s/\r\n?|\n/<br>/g foreach('', 2 .. ($set::image_maxcount || 1));
  $pc{freeNote}      =~ s/\r\n?|\n/<br>/g;
  $pc{freeHistory}   =~ s/\r\n?|\n/<br>/g;
  $pc{chatPalette}   =~ s/\r\n?|\n/<br>/g;
  $pc{"combo${_}Note"}   =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{comboNum});
  $pc{"weapon${_}Note"}  =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{weaponNum});
  $pc{"armor${_}Note"}   =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{armorNum});
  $pc{"vehicle${_}Note"} =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{vehicleNum});
  $pc{"item${_}Note"}    =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{itemNum});
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  $_ = escapePcData($_) foreach (@dloises);
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### updatedLine --------------------------------------------------
  my %NL;
  $NL{name}  = ($pc{aka} ? "“$pc{aka}”" : "").$pc{characterName};
  $NL{$_} = $pc{$_} foreach ('playerName','gender','age','sign','blood','works');
  foreach (keys %NL){
    $NL{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  if(length($NL{name}) > 108){
    if($NL{name} =~ s/“.+”//r){ $NL{name} =~ s/“.+”// }
    if(length($NL{name}) > 108){
      $NL{name} = substr($NL{name}, 0, 108).'..' if length($NL{name}) > 108;
    }
  }
  $NL{playerName} = substr($NL{playerName}, 0, 25).'..' if length($NL{playerName}) > 25;
  $NL{gender} = substr($NL{gender}, 0, 20).'..' if length($NL{gender}) > 20;
  $NL{age}    = substr($NL{age}   , 0, 20).'..' if length($NL{age}   ) > 20;
  $NL{sign}   = substr($NL{sign}  , 0, 20).'..' if length($NL{sign}  ) > 20;
  $NL{blood}  = substr($NL{blood} , 0, 20).'..' if length($NL{blood} ) > 20;
  $NL{works}  = substr($NL{works} , 0, 20).'..' if length($NL{works} ) > 20;
  foreach (@dloises){
    $_ =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
    $_ =~ s/[:：].+?$//g;
    $_ = removeTags unescapeTags $_ =~ s/^\s|\s$//gr;
    $_ = substr($_ , 0, 30).'..' if length($_) > 30;
  }
  sub synCheck {
    my $syn = shift;
    if($syn eq ''){ return '' }
    if(grep { $_ eq $syn } @data::syndromes){ return $syn; }
    $syn =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
    $syn = removeTags unescapeTags $syn =~ s/^\s|\s$//gr;
    $syn = substr($syn, 0, 20).'..' if length($syn) > 20;
    return "その他:$syn";
  }
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{name}<>$NL{playerName}<>$pc{group}<>"
    . (130+$pc{expSpent})
    . "<>$NL{gender}<>$NL{age}<>$NL{sign}<>$NL{blood}<>$NL{works}<>"
    . synCheck($pc{syndrome1}).'/'
    . synCheck($pc{syndrome2}).'/'
    . synCheck($pc{syndrome3}).'<>'
    . join('/',@dloises).'<>'
    . "$pc{lastSession}<>"
    . $pc{"image".imageSuffix($pc{mainImage})}."<> $pc{tags} <>$pc{hide}<>$pc{stage}<>";

  return %pc;
}

1;