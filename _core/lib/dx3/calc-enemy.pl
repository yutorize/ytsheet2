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

  foreach my $num (keys %status){
    my $name = $status{$num};
    my $Name = ucfirst $name;

    next if ($pc{'sttTotal'.$Name} ne '');

    my $base = 0;
    if($data::syndrome_status{$pc{syndrome1}}){ $pc{'sttSyn1'.$Name} = $data::syndrome_status{$pc{syndrome1}}[$num] }
    if($data::syndrome_status{$pc{syndrome2}}){ $pc{'sttSyn2'.$Name} = $data::syndrome_status{$pc{syndrome2}}[$num] }
    $base += $pc{'sttSyn1'.$Name};
    $base += $pc{syndrome2} ? $pc{'sttSyn2'.$Name} : $base;

    $pc{'sttTotal'.$Name} = $base;
  }

  ### 副能力値 --------------------------------------------------
  if($pc{maxHpTotal}      eq ''){ $pc{maxHpTotal}      = $pc{sttTotalBody}  * 2 + $pc{sttTotalMind} + 20; }
  if($pc{initiativeTotal} eq ''){ $pc{initiativeTotal} = $pc{sttTotalSense} * 2 + $pc{sttTotalMind}; }

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
    }
  }

  #### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    qw/freeNote chatPalette/,
    ( map { 'words'.$_ } '', 2 .. ($set::image_maxcount || 1) ),
    ( map { "combo${_}Note"   } 1..$pc{comboNum} ),
    ( map { "weapon${_}Note"  } 1..$pc{weaponNum} ),
  );

  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### updatedLine --------------------------------------------------
  my %NL;
  $NL{name}  = ($pc{aka} ? "“$pc{aka}”" : "").$pc{enemyName};
  $NL{$_} = $pc{$_} foreach (qw/author enemyType stage/);
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
  $NL{author}    = substr($NL{author}   , 0, 25).'..' if length($NL{author}   ) > 25;
  $NL{enemyType} = substr($NL{enemyType}, 0, 25).'..' if length($NL{enemyType}) > 25;
  $NL{stage}     = substr($NL{stage}    , 0, 25).'..' if length($NL{stage}    ) > 25;
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
    . "$pc{birthTime}<>$::now<>$NL{name}<>$NL{author}<><>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>"
    . "$NL{enemyType}<>$NL{stage}<>"
    . synCheck($pc{syndrome1}).'/'
    . synCheck($pc{syndrome2}).'/'
    . synCheck($pc{syndrome3}).'<>'
    . "$pc{maxHpTotal}<>$pc{initiativeTotal}<>$pc{armorTotal}<>$pc{encroachTotal}<>";

  return %pc;
}

1;
