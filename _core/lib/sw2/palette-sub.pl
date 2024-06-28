################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;
require $set::data_items;
my @class_names;
foreach(@data::class_names){
  push(@class_names, $_);
  if($_ eq 'コンジャラー'){ push(@class_names, 'ウィザード'); }
}

### 魔法威力 #########################################################################################
my %pows = (
  Sor => {
    10  =>  1,
    20  =>  3,
    30  =>  5,
    40  =>  8,
    50  => 11,
    60  => 14,
    100 => 15,
  },
  Con => {
    0   =>  1,
    10  =>  7,
    20  =>  8,
    30  =>  9,
    60  => 15,
  },
  Wiz => {
    10  =>  7,
    20  =>  4,
    30  =>  9,
    70  => 13,
  },
  Pri => {
    10  =>  3,
    20  =>  5,
    30  =>  9,
    50  => 11,
  },
  Mag => {
    30  =>  5,
    90  => 15,
  },
  Fai => {
    10  =>  2,
    20  =>  5,
    30  =>  4,
    40  => 10,
    50  => 11,
    60  => 14,
    80  => 10
  },
  Dru => {
    10  =>  4,
    20  =>  4,
    30  => 12,
    50  => 15,
  },
  Dem => {
    10  =>  3,
    20  =>  2,
    30  => 15,
    40  =>  9,
    70  => 14,
  },
  Gri => {
    10  =>  1,
    20  =>  1,
    30  =>  4,
    40  =>  7,
    50  =>  7,
    60  => 10,
    80  => 13,
    100 => 13,
  },
  Bar => {
    10  =>  1,
    20  =>  5,
    30  => 10,
  },
);
if($::SW2_0){
  $pows{Dem} = {
    10  =>  1,
    20  =>  1,
    30  =>  5,
    40  =>  5,
    50  =>  5,
  };
}

my %heals = (
  Con => {
    0   =>  2,
    30  => 11,
  },
  Pri => {
    10  =>  2,
    30  =>  5,
    50  => 10,
    70  => 13,
  },
  Gri => {
    20  =>  1,
    40  =>  7,
    100 => 13,
  },
  Bar => {
    0   =>  1,
    10  =>  1,
    20  =>  1,
    30  =>  5,
    40  => 10,
  },
);

my @gunPowers = (
  { lv =>  1, p => 20, c => '' },
  { lv =>  2, p => 20, c => -1 },
  { lv =>  6, p => 30, c => '' },
  { lv =>  7, p => 10, c => '' },
  { lv =>  9, p => 30, c => -1 },
  { lv => 12, p => 40, c => '', h => '2H' },
  { lv => 15, p => 70, c => '', h => '2H' },
);
my @gunHeals = (
  { lv =>  2, p =>  0 },
  { lv => 10, p => 30 },
  { lv => 13, p => 20, h => '2H' },
);

my $skill_mark = "\\[[常準主補宣]\\]|[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;";

sub normalizeCrit {
  my $crit = shift;
  $crit =~ s/⑦|➆/7/;
  $crit =~ s/⑧|➇/8/;
  $crit =~ s/⑨|➈/9/;
  $crit =~ s/⑩|➉/10/;
  $crit =~ s/⑪/11/;
  $crit =~ s/⑫/12/;
  $crit =~ s/⑬/13/;
  return $crit;
}
sub appendPaletteInsert {
  my $position = shift;
  my $text;
  foreach (1 .. $::pc{chatPaletteInsertNum}) {
    if($::pc{"chatPaletteInsert${_}Position"} eq $position){
      $text .= $::pc{"chatPaletteInsert$_"} =~ s/<br>/\n/gr;;
      $text .= "\n" if $::pc{"chatPaletteInsert$_"};
    }
  }
  return $text;
}

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{YTC} = 1; }
  elsif($tool eq 'tekey' ){ $bot{TKY} = $bot{BCD} = 1; }
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }
  ## ＰＣ
  if(!$type){
    $text .= appendPaletteInsert('');
    # 基本判定
    $text .= "### ■非戦闘系\n";
    $text .= "2d+{冒険者}+{器用B} 冒険者＋器用\n";
    $text .= "2d+{冒険者}+{敏捷B} 冒険者＋敏捷\n";
    $text .= "2d+{冒険者}+{筋力B} 冒険者＋筋力\n";
    $text .= "2d+{冒険者}+{知力B} 冒険者＋知力\n";
    foreach my $class (@class_names){
      my $c_id = $data::class{$class}{id};
      next if !$data::class{$class}{package} || !$::pc{'lv'.$c_id};
      my %data = %{$data::class{$class}{package}};
      foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data){
        my $name = $class.$data{$p_id}{name};
        $text .= "2d+{$name} $name\n";
        if($data{$p_id}{monsterLore} && $::pc{monsterLoreAdd}){ $text .= "2d+{$name}+$::pc{monsterLoreAdd} 魔物知識\n"; }
        if($data{$p_id}{initiative } && $::pc{initiativeAdd }){ $text .= "2d+{$name}+$::pc{initiativeAdd } 先制\n"; }
      }
    }
    $text .= "\n";
    $text .= appendPaletteInsert('general');

    foreach (1 .. $::pc{commonClassNum}){
      next if !$::pc{"commonClass$_"};
      my $name = removeTags unescapeTags $::pc{'commonClass'.$_};
      $name =~ s/[(（].+?[）)]$//;
      $text .= "2d+{$name}+{器用B} ${name}＋器用\n" if $::pc{"paletteCommonClass${_}Dex"};
      $text .= "2d+{$name}+{敏捷B} ${name}＋敏捷\n" if $::pc{"paletteCommonClass${_}Agi"};
      $text .= "2d+{$name}+{筋力B} ${name}＋筋力\n" if $::pc{"paletteCommonClass${_}Str"};
      $text .= "2d+{$name}+{生命B} ${name}＋生命\n" if $::pc{"paletteCommonClass${_}Vit"};
      $text .= "2d+{$name}+{知力B} ${name}＋知力\n" if $::pc{"paletteCommonClass${_}Int"};
      $text .= "2d+{$name}+{精神B} ${name}＋精神\n" if $::pc{"paletteCommonClass${_}Mnd"};
    }
    $text .= "\n";
    $text .= appendPaletteInsert('common');

    # 魔法
    foreach my $name (@class_names){
      next if !($data::class{$name}{magic}{jName} || $data::class{$name}{craft}{stt});
      next if !$::pc{'lv' . $data::class{$name}{id} };
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■魔法系\n";
      $text .= "//魔力修正=".($::pc{magicPowerAdd}||0)."\n";
      $text .= "//行使修正=".($::pc{magicCastAdd}||0)."\n";
      $text .= "//魔法C=10\n";
      $text .= "//魔法D修正=".($::pc{magicDamageAdd}||0)."\n";
      $text .= "//物理魔法D修正=".($::pc{magicDamageAdd}||0)."\n" if $::pc{lvDru} || $::pc{lvSor} >= 12 || ($::pc{lvFai} && $::pc{fairyContractEarth});
      $text .= "//回復量修正=0\n" if $::pc{lvCon} || $::pc{lvPri} || $::pc{lvGri} || $::pc{lvBar} || $::pc{lvMag} >= 2;
      last;
    }

    foreach my $name (@class_names){
      next if !($data::class{$name}{magic}{jName} || $data::class{$name}{craft}{stt});
      my $id   = $data::class{$name}{id};
      my $name = $data::class{$name}{magic}{jName} || $data::class{$name}{craft}{jName};
      next if !$::pc{'lv'.$id};
      
      my %dmgTexts;
      foreach my $paNum (0 .. $::pc{paletteMagicNum}){
        next if($paNum && !($::pc{'paletteMagic'.$paNum.'Name'} && $::pc{'paletteMagic'.$paNum.'Check'.$id}));

        my $text;

        my $activeName  = $::pc{'paletteMagic'.$paNum.'Name'} ? "＋$::pc{'paletteMagic'.$paNum.'Name'}" : '';
        my $activePower = $::pc{'paletteMagic'.$paNum.'Power'} ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Power'}") : '';
        my $activeCrit  = $::pc{'paletteMagic'.$paNum.'Crit' } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Crit' }") : '';
        my $activeDmg   = $::pc{'paletteMagic'.$paNum.'Dmg'  } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Dmg'  }") : '';
        my $activeRoll  = $::pc{'paletteMagic'.$paNum.'Roll' } ? '#'.optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Roll' }") : '';

        my $magicPower = "{$name}" . ($name =~ /魔/ ? $activePower :"");
        
        my $half;
        foreach my $pow (sort {$a <=> $b} keys %{$pows{$id}}) {
          next if($pows{$id}{$pow} > $::pc{'lv'.$id} && $id ne 'Fai');
          next if($id eq 'Wiz' && $pows{$id}{$pow} > min($::pc{lvSor},$::pc{lvCon}));
          next if($id eq 'Fai' && $pows{$id}{$pow} > fairyRank($::pc{lvFai},$::pc{fairyContractEarth},$::pc{fairyContractWater},$::pc{fairyContractFire },$::pc{fairyContractWind },$::pc{fairyContractLight},$::pc{fairyContractDark }));
          if($id eq 'Bar'){ $pow += $::pc{finaleEnhance} || 0; }

          $text .= "k${pow}[{魔法C}$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id})."+{魔法D修正}$activeDmg ダメージ\n";
          if ($id eq 'Sor' && $pow == 30 && $::pc{lvSor} >= 12) {
            $text .= "k${pow}[10$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id})."+{物理魔法D修正}$activeDmg 物理ダメージ\n";
          }
          if ($id eq 'Fai' && $::pc{fairyContractEarth} && ($pow == 10 || $pow == 50)) {
            $text .= "k${pow}[12$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id})."+{物理魔法D修正}$activeDmg 物理ダメージ\n";
          }
          my $halfCrit = $activeName =~ /クリティカルキャスト/ ? "{魔法C}$activeCrit" : "13";
          if ($bot{YTC}) { $half .= "k${pow}[$halfCrit]+$magicPower" . "//" . addNum($::pc{'magicDamageAdd'.$id}) . "+{魔法D修正}$activeDmg 半減\n"; }
          if ($bot{BCD}) { $half .= "k${pow}[$halfCrit]+$magicPower" . "h+("  . ($::pc{'magicDamageAdd'.$id} || '') . "+{魔法D修正}$activeDmg) 半減\n"; }
        }
        $text .= $half;
        if($id eq 'Dru'){
          my $druidBase = "$magicPower+{物理魔法D修正} 物理ダメージ";
          if($bot{YTC}){
            $text .= "kウルフバイト+$druidBase\n"       if($::pc{lvDru} >=  1);
            $text .= "kソーンバッシュ+$druidBase\n"     if($::pc{lvDru} >=  3);
            $text .= "kコングスマッシュ+$druidBase\n"   if($::pc{lvDru} >=  7);
            $text .= "kボアラッシュ+$druidBase\n"       if($::pc{lvDru} >=  9);
            $text .= "kマルサーヴラプレス+$druidBase\n" if($::pc{lvDru} >= 10);
            $text .= "kルナアタック+$druidBase\n"       if($::pc{lvDru} >= 13);
            $text .= "kダブルストンプ+$druidBase\n"     if($::pc{lvDru} >= 15);
          }
          elsif ($bot{BCD}) {
            $text .= "Dru[0,3,6]+$druidBase／【ウルフバイト】\n"          if($::pc{lvDru} >=  1);
            $text .= "Dru[4,7,13]+$druidBase／【ソーンバッシュ】\n"       if($::pc{lvDru} >=  3);
            $text .= "Dru[12,15,18]+$druidBase／【コングスマッシュ】\n"   if($::pc{lvDru} >=  7);
            $text .= "Dru[13,16,19]+$druidBase／【ボアラッシュ】\n"       if($::pc{lvDru} >=  9);
            $text .= "Dru[18,21,24]+$druidBase／【マルサーヴラプレス】\n" if($::pc{lvDru} >= 10);
            $text .= "Dru[18,21,36]+$druidBase／【ルナアタック】\n"       if($::pc{lvDru} >= 13);
            $text .= "Dru[24,27,30]+$druidBase／【ダブルストンプ】\n"     if($::pc{lvDru} >= 15);
          }
        }
      
        foreach my $pow (sort {$a <=> $b} keys %{$heals{$id}}) {
          next if($::pc{'lv'.$id} < $heals{$id}{$pow});
          $text .= "k${pow}[13]+$magicPower+{回復量修正} 回復量\n"
        }

        $text =~ s/^(k[0-9]+)\[(.+?)\]/$1\[($2)\]/gm if $bot{BCD};
        $dmgTexts{$paNum} = $text;
      }
      
      foreach my $paNum (0 .. $::pc{paletteMagicNum}){
        next if($paNum && !($::pc{'paletteMagic'.$paNum.'Name'} && $::pc{'paletteMagic'.$paNum.'Check'.$id}));
        
        my $activeName  = $::pc{'paletteMagic'.$paNum.'Name'} ? "＋$::pc{'paletteMagic'.$paNum.'Name'}" : '';
        my $activePower = $::pc{'paletteMagic'.$paNum.'Power'} ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Power'}") : '';
        my $activeCast  = $::pc{'paletteMagic'.$paNum.'Cast' } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Cast' }") : '';

        $text .= "2d+{$name}";
        if   ($name =~ /魔/){ $text .= "$activePower+{行使修正}$activeCast ${name}行使$activeName\n"; }
        elsif($name =~ /歌/){ $text .= " 呪歌演奏\n"; }
        else                { $text .= " ${name}\n"; }
        
        if($dmgTexts{$paNum + 1} && $dmgTexts{$paNum} eq $dmgTexts{$paNum + 1}){
          next;
        }
        if($dmgTexts{$paNum} eq $dmgTexts{$paNum - 1}){
          $activeName = $::pc{'paletteMagic'.($paNum - 1).'Name'} ? "＋$::pc{'paletteMagic'.($paNum - 1).'Name'}" : '';
        }
        $text .= $bot{BCD} ? ($dmgTexts{$paNum} =~ s/(ダメージ|半減)(\n|／)/$1／$name$activeName$2/gr) : $dmgTexts{$paNum};
        $text .= "\n";
      }
    }
    
    $text .= appendPaletteInsert('magic');

    # 攻撃
    foreach (1 .. $::pc{weaponNum}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■武器攻撃系\n";
      $text .= "//命中修正=0\n";
      $text .= "//C修正=0\n";
      $text .= "//追加D修正=0\n";
      $text .= "//必殺効果=0\n";
      $text .= "//クリレイ=0\n";
      last;
    }
    
    foreach (1 .. $::pc{weaponNum}){
      if($::pc{'weapon'.$_.'Category'} eq 'ガン'){
        $text .= "//ガン追加D修正=0\n";
        last;
      }
    }
    
    foreach (1 .. $::pc{weaponNum}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      next if (
        $::pc{'weapon'.$_.'Name'}  eq $::pc{'weapon'.($_-1).'Name'}  &&
        $::pc{'weapon'.$_.'Part'}  eq $::pc{'weapon'.($_-1).'Part'}  &&
        $::pc{'weapon'.$_.'Usage'} eq $::pc{'weapon'.($_-1).'Usage'} &&
        $::pc{'weapon'.$_.'Acc'}   eq $::pc{'weapon'.($_-1).'Acc'}   &&
        $::pc{'weapon'.$_.'Rate'}  eq $::pc{'weapon'.($_-1).'Rate'}  &&
        $::pc{'weapon'.$_.'Crit'}  eq $::pc{'weapon'.($_-1).'Crit'}  &&
        $::pc{'weapon'.$_.'Dmg'}   eq $::pc{'weapon'.($_-1).'Dmg'}
      );
      $::pc{'weapon'.$_.'Name'} ||= $::pc{'weapon'.($_-1).'Name'};
      $::pc{'weapon'.$_.'Crit'} = normalizeCrit $::pc{'weapon'.$_.'Crit'};
      my $partName = $::pc{'part'.$::pc{'weapon'.$_.'Part'}.'Name'};
      
      my %dmgTexts;
      foreach my $paNum (0 .. $::pc{paletteAttackNum}){
        next if($paNum && !($::pc{'paletteAttack'.$paNum.'Name'} && $::pc{'paletteAttack'.$paNum.'CheckWeapon'.$_}));

        my $text;
        my $activeCrit = $::pc{'paletteAttack'.$paNum.'Crit'} ? optimizeOperatorFirst "+$::pc{'paletteAttack'.$paNum.'Crit'}" : '';
        my $activeDmg  = $::pc{'paletteAttack'.$paNum.'Dmg' } ? optimizeOperatorFirst "+$::pc{'paletteAttack'.$paNum.'Dmg' }" : '';

        if($::pc{'weapon'.$_.'Category'} eq 'ガン'){
          foreach my $bullet (sort {$a->{p} <=> $b->{p}} @gunPowers){
            next if $::pc{lvMag} < $bullet->{lv};
            next if $bullet->{h} && $::pc{'weapon'.$_.'Usage'} !~ /$bullet->{h}/;
            $text .= "k$bullet->{p}\[";
            $text .= "(" if $bot{BCD};
            $text .= "$::pc{'weapon'.$_.'Crit'}$bullet->{c}";
            $text .= "$::pc{'paletteAttack'.$paNum.'Crit'}";
            $text .= ")" if $bot{BCD};
            $text .= "\]";
            $text .= $::pc{paletteUseVar} ? "{追加D$_}" : $::pc{"weapon${_}DmgTotal"};
            $text .= "+{ガン追加D修正}";
            $text .= "$::pc{'paletteAttack'.$paNum.'Dmg'}";
            $text .= " ダメージ";
            $text .= "\n";
          }
          foreach my $bullet (sort {$a->{p} <=> $b->{p}} @gunHeals){
            next if $::pc{lvMag} < $bullet->{lv};
            next if $bullet->{h} && $::pc{'weapon'.$_.'Usage'} !~ /$bullet->{h}/;
            $text .= "k$bullet->{p}\[";
            $text .= "13";
            $text .= "\]+";
            $text .= $::pc{paletteUseVar} ? "{追加D$_}" : $::pc{"weapon${_}DmgTotal"};
            $text .= "+{回復量修正}";
            $text .= " 回復量";
            $text .= "\n";
          }
        }
        else {
          $text .= "k$::pc{'weapon'.$_.'Rate'}\[";
          $text .= "(" if $bot{BCD};
          $text .= "$::pc{'weapon'.$_.'Crit'}+{C修正}$activeCrit";
          $text .= ")" if $bot{BCD};
          $text .= "\]+";
          $text .= $::pc{paletteUseVar} ? "{追加D$_}" : $::pc{"weapon${_}DmgTotal"};
          $text .= $activeDmg;
          
          $text .= "+{追加D修正}";
          if($::pc{'paletteAttack'.$paNum.'Roll'}){
            $::pc{'paletteAttack'.$paNum.'Roll'} =~ s/^+//;
            $text .= "$+{クリレイ}\#$::pc{'paletteAttack'.$paNum.'Roll'}";
          }
          else {
            $text .= "{出目修正}";
          }
          $text .= "";

          if($::pc{'weapon'.$_.'Name'} =~ /首切/ || $::pc{'weapon'.$_.'Note'} =~ /首切/){
            $text .= $bot{YTC} ? '首切' : $bot{BCD} ? 'r5' : '';
          }
          $text .= " ダメージ";
          $text .= extractWeaponMarks($::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Note'}) unless $bot{BCD};
          $text .= "／$::pc{'weapon'.$_.'Name'}$::pc{'weapon'.$_.'Usage'}" if $bot{BCD};
          $text .= "（${partName}）" if $partName && $bot{BCD};
          $text .= "\n";
        }
        $dmgTexts{$paNum} = $text;
      }

      foreach my $paNum (0 .. $::pc{paletteAttackNum}){
        next if($paNum && !($::pc{'paletteAttack'.$paNum.'Name'} && $::pc{'paletteAttack'.$paNum.'CheckWeapon'.$_}));
        
        my $activeName = $::pc{'paletteAttack'.$paNum.'Name'} ? "＋$::pc{'paletteAttack'.$paNum.'Name'}" : '';

        $text .= "2d+";
        $text .= $::pc{paletteUseVar} ? "{命中$_}" : $::pc{"weapon${_}AccTotal"};
        $text .= "+{命中修正}";
        if($::pc{'paletteAttack'.$paNum.'Acc'}){
          $text .= optimizeOperatorFirst "+$::pc{'paletteAttack'.$paNum.'Acc'}";
        }
        $text .= " 命中力／$::pc{'weapon'.$_.'Name'}$::pc{'weapon'.$_.'Usage'}";
        $text .= "（${partName}）" if $partName;
        if($::pc{'paletteAttack'.$paNum.'Name'}){
          $text .= "＋$::pc{'paletteAttack'.$paNum.'Name'}";
        }
        $text .= "\n";
        
        if($dmgTexts{$paNum + 1} && $dmgTexts{$paNum} eq $dmgTexts{$paNum + 1}){
          next;
        }
        if($dmgTexts{$paNum} eq $dmgTexts{$paNum - 1}){
          $activeName = $::pc{'paletteAttack'.($paNum - 1).'Name'} ? "＋$::pc{'paletteAttack'.($paNum - 1).'Name'}" : '';
        }
        $text .= $bot{BCD} ? ($dmgTexts{$paNum} =~ s/(\n)/$activeName$1/gr) : $dmgTexts{$paNum};
        $text .= "\n";
      }
    }
    $text .= "//出目修正=\$+{クリレイ}\#{必殺効果}\n" if $text =~ /■武器攻撃系/;
    
    $text .= appendPaletteInsert('attack');
    # 抵抗回避
    $text .= "###\n" if $bot{TKY};
    $text .= "### ■抵抗回避\n";
    $text .= "//生命抵抗修正=0\n";
    $text .= "//精神抵抗修正=0\n";
    $text .= "//回避修正=0\n";
    $text .= "2d+{生命抵抗}+{生命抵抗修正} 生命抵抗力\n";
    $text .= "2d+{精神抵抗}+{精神抵抗修正} 精神抵抗力\n";
    foreach my $i (1..$::pc{defenseNum}){
      my $hasChecked = 0;
      foreach my $j (1..$::pc{armourNum}){
        $hasChecked++ if($::pc{"defTotal${i}CheckArmour${j}"});
      }
      next if !$hasChecked && !$::pc{"evasionClass${i}"};

      $text .= "2d+";
      $text .= $::pc{paletteUseVar} ? "{回避${i}}" : $::pc{"defenseTotal${i}Eva"};
      $text .= "+{回避修正} 回避力".($::pc{"defenseTotal${i}Note"}?"／$::pc{'defenseTotal'.$i.'Note'}":'')."\n";
    }
    $text .= appendPaletteInsert('defense');
    
    #
    $text .= "###\n" if $bot{YTC} || $bot{TKY};
  }
  ## 魔物
  elsif($type eq 'm') {
    $text .= "//生命抵抗修正=0\n";
    $text .= "//精神抵抗修正=0\n";
    $text .= "//回避修正=0\n";
    $text .= "2d+{生命抵抗}+{生命抵抗修正} 生命抵抗力\n";
    $text .= "2d+{精神抵抗}+{精神抵抗修正} 精神抵抗力\n";
    foreach (1 .. $::pc{statusNum}){
      (my $part   = $::pc{'status'.$_.'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
      $text .= "2d+{回避$_}+{回避修正} 回避／".$part."\n" if $::pc{'status'.$_.'Evasion'} ne '';
    }
    $text .= "\n";

    $text .= "//命中修正=0\n";
    $text .= "//打撃修正=0\n";
    foreach (1 .. $::pc{statusNum}){
      (my $part   = $::pc{'status'.$_.'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
      (my $weapon = $::pc{'status'.$_.'Style'}) =~ s/^(.+?)[（(].+?[)）]$/$1/;
      if($part ne $weapon){ $weapon = $::pc{'status'.$_.'Style'}; }
      $text .= "2d+{命中$_}+{命中修正} 命中力／$weapon\n" if $::pc{'status'.$_.'Accuracy'} ne '';
      $text .= "{ダメージ$_}+{打撃修正} ダメージ／".$weapon."\n" if $::pc{'status'.$_.'Damage'} ne '';
      $text .= "\n";
    }
    my $skills = $::pc{skills};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/\|/｜/g;
    $skills =~ s/<br>/\n/gi;
    $skills =~ s/^
      (?:$skill_mark)+
      (?<name>.+?)
      (?: [0-9]+(?:レベル|LV)|\(.+\) )*
      [\/／]
      (?:魔力)
      ([0-9]+)
      [(（][0-9]+[）)]
      /$text .= "2d+{$+{name}} $+{name}\n\n";/megix;
    
    $skills =~ s/^
      (?<head>
        (?<mark>(?:$skill_mark)+)
        (?<name>.+)
        [\/／]
        (
          (?<dice>(?<base>[0-9]+)  [(（]  (?<fix>[0-9]+)  [）)]  )
          |
          (?<fix>[0-9]+)
        )
        (?<other>.+?)
      )
      \s
      (?<note>[\s\S]*?)
      (?=^$skill_mark|^●|\z)
      /
      $text .= convertMark($+{mark})."$+{name}／$+{fix}$+{other}\n"
            .($+{base} ne '' ?"2d+{$+{name}} ".convertMark($+{mark})."$+{name}$+{other}\n":'')
            .skillNote($+{head},$+{name},$+{note})."\n";
      /megix;
  }
  
  return $text;

  sub skillNote {
    my $head = shift;
    my $name = shift;
    my $note = shift;
    my $half = ($head =~ /半減/ ? 1 : 0);
    $note =~ tr#＋－×÷#+\-*/#;
    my $out;
    $note =~ s/「?(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "{${name}ダメージ} $+{elm}$+{dmg}ダメージ\n".($half?"{${name}ダメージ}\/\/2 $+{elm}$+{dmg}ダメージ（半減）\n":'');/smegi if $bot{YTC};
    $note =~ s/「?(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "{${name}ダメージ} $+{elm}$+{dmg}ダメージ／${name}\n".($half?"({${name}ダメージ})\/2U $+{elm}$+{dmg}ダメージ（半減）／${name}\n":'');/smegi if $bot{BCD};
    return $out;
  }
  sub convertMark {
    my $text = shift;
    return $text if $bot{BCD}; #BCDは変換しない
    if($::SW2_0){
      $text =~ s{[○◯〇]}{[常]}gi;
      $text =~ s{[＞▶〆]}{[主]}gi;
      $text =~ s{[☆≫»]|&gt;&gt;}{[補]}gi;
      $text =~ s{[□☑🗨]}{[宣]}gi;
      $text =~ s{[▽]}{▽}gi;
      $text =~ s{[▼]}{▼}gi;
    } else {
      $text =~ s{[○◯〇]}{[常]}gi;
      $text =~ s{[△]}{[準]}gi;
      $text =~ s{[＞▶〆]}{[主]}gi;
      $text =~ s{[☆≫»]|&gt;&gt;}{[補]}gi;
      $text =~ s{[□☑🗨]}{[宣]}gi;
    }
    
    return $text;
  }
}
sub extractWeaponMarks {
  my $text = shift;
  my $marks = '';
  while ($text =~ s/(\[[刃打魔]\])//) {
    $marks .= $1;
  }
  return $marks;
}
### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  
  my $text = palettePreset($tool,$type);
  my %propaty;
  foreach (paletteProperties($tool,$type)){
    if($_ =~ /^\/\/(.+?)=(.*)$/){
      $propaty{$1} = $2;
    }
  }
  my $hit = 1;
  while ($hit){
    $hit = 0;
    foreach(keys %propaty){
      if($text =~ s/\Q{$_}\E/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  $text =~ s/[0-9]+\/6/int s_eval($&)/egi;
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
my %stt_id_to_name = (
  A => '器用',
  B => '敏捷',
  C => '筋力',
  D => '生命',
  E => '知力',
  F => '精神',
);
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//器用度=$::pc{sttDex}";
    push @propaties, "//敏捷度=$::pc{sttAgi}";
    push @propaties, "//筋力=$::pc{sttStr}"  ;
    push @propaties, "//生命力=$::pc{sttVit}";
    push @propaties, "//知力=$::pc{sttInt}"  ;
    push @propaties, "//精神力=$::pc{sttMnd}";
    push @propaties, "//器用増強=".($::pc{sttAddA}||0);
    push @propaties, "//敏捷増強=".($::pc{sttAddB}||0);
    push @propaties, "//筋力増強=".($::pc{sttAddC}||0);
    push @propaties, "//生命増強=".($::pc{sttAddD}||0);
    push @propaties, "//知力増強=".($::pc{sttAddE}||0);
    push @propaties, "//精神増強=".($::pc{sttAddF}||0);
    push @propaties, "###" if $tool eq 'tekey';
    push @propaties, "### ■技能レベル";
    push @propaties, "//冒険者レベル=$::pc{level}";
    my @classes_en;
    foreach my $name (@class_names){
      my $id = $data::class{$name}{id};
      next if !$::pc{'lv'.$id};
      push @propaties, "//$name=$::pc{'lv'.$id}";
      push @classes_en, "//".uc($id)."={$name}";
    }
    foreach my $num (1..($::pc{commonClassNum}||10)){
      my $name = removeTags unescapeTags $::pc{'commonClass'.$num};
      $name =~ s/[(（].+?[）)]$//;
      push @propaties, "//$name=$::pc{'lvCommon'.$num}" if $name;
    }
    push @propaties, '';
    push @propaties, "###" if $tool eq 'tekey';
    push @propaties, "### ■代入パラメータ";
    push @propaties, "//器用={器用度}";
    push @propaties, "//敏捷={敏捷度}";
    push @propaties, "//生命={生命力}";
    push @propaties, "//精神={精神力}";
    push @propaties, "//器用B=(({器用}+{器用増強})/6)";
    push @propaties, "//敏捷B=(({敏捷}+{敏捷増強})/6)";
    push @propaties, "//筋力B=(({筋力}+{筋力増強})/6)";
    push @propaties, "//生命B=(({生命}+{生命増強})/6)";
    push @propaties, "//知力B=(({知力}+{知力増強})/6)";
    push @propaties, "//精神B=(({精神}+{精神増強})/6)";
    push @propaties, "//DEX={器用}+{器用増強}";
    push @propaties, "//AGI={敏捷}+{敏捷増強}";
    push @propaties, "//STR={筋力}+{筋力増強}";
    push @propaties, "//VIT={生命}+{生命増強}";
    push @propaties, "//INT={知力}+{知力増強}";
    push @propaties, "//MND={精神}+{精神増強}";
    push @propaties, "//dexB={器用B}";
    push @propaties, "//agiB={敏捷B}";
    push @propaties, "//strB={筋力B}";
    push @propaties, "//vitB={生命B}";
    push @propaties, "//intB={知力B}";
    push @propaties, "//mndB={精神B}";
    push @propaties, @classes_en;
    push @propaties, '';
    push @propaties, "//生命抵抗=({冒険者}+{生命B})".($::pc{vitResistAddTotal}?"+$::pc{vitResistAddTotal}":"");
    push @propaties, "//精神抵抗=({冒険者}+{精神B})".($::pc{mndResistAddTotal}?"+$::pc{mndResistAddTotal}":"");
    push @propaties, "//最大HP=$::pc{hpTotal}";
    push @propaties, "//最大MP=$::pc{mpTotal}";
    push @propaties, '';
    push @propaties, "//冒険者={冒険者レベル}";
    push @propaties, "//LV={冒険者}";
    push @propaties, '';
    #push @propaties, "//魔物知識=$::pc{monsterLore}" if $::pc{monsterLore};
    #push @propaties, "//先制力=$::pc{initiative}" if $::pc{initiative};
    foreach my $class (@class_names){
      my $c_id = $data::class{$class}{id};
      next if !$data::class{$class}{package} || !$::pc{'lv'.$c_id};
      my %data = %{$data::class{$class}{package}};
      foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data){
        my $name = $class.$data{$p_id}{name};
        my $stt  = $stt_id_to_name{$data{$p_id}{stt}};
        my $add  = $::pc{'pack'.$c_id.$p_id.'Add'} + $::pc{'pack'.$c_id.$p_id.'Auto'};
        push @propaties, "//$name=\{$class\}+\{${stt}B\}".addNum($add);
      }
    }
    push @propaties, '';
    
    foreach my $name (@class_names){
      next if !($data::class{$name}{magic}{jName} || $data::class{$name}{craft}{stt});
      my $id = $data::class{$name}{id};
      next if !$::pc{'lv'.$id};
      my $magic = $data::class{$name}{magic}{jName} || $data::class{$name}{craft}{jName};
      my $stt = $data::class{$name}{craft}{stt} || '知力';
      my $own = $::pc{'magicPowerOwn'.$id} ? "+2" : "";
      my $add;
      if($data::class{$name}{magic}{jName}){
        $add .= addNum $::pc{magicPowerEnhance};
        $add .= addNum $::pc{'magicPowerAdd'.$id};
        $add .= addNum $::pc{raceAbilityMagicPower};
        $add .= addNum $::pc{'raceAbilityMagicPower'.$id};
        $add .= $::pc{paletteUseBuff} ? "+{魔力修正}" : addNum($::pc{magicPowerAdd});
      }
      elsif($id eq 'Alc') {
        $add .= addNum($::pc{alchemyEnhance});
      }
      push @propaties, "//$magic=({$name}+({$stt}+{$stt\増強}$own)/6)$add";
    }
    push @propaties, '';
    
    foreach (1 .. $::pc{weaponNum}){
      next if $::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Usage'}.$::pc{'weapon'.$_.'Reqd'}.
              $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.$::pc{'weapon'.$_.'Crit'}.
              $::pc{'weapon'.$_.'Dmg'}.$::pc{'weapon'.$_.'Own'}.$::pc{'weapon'.$_.'Note'}
              eq '';
      $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
      
      $::pc{'weapon'.$_.'Crit'} = normalizeCrit $::pc{'weapon'.$_.'Crit'};
      
      my $class = $::pc{"weapon${_}Class"};
      my $category = $::pc{"weapon${_}Category"};
      my $partNum = $::pc{"weapon${_}Part"};

      push @propaties, "//武器$_=$::pc{'weapon'.$_.'Name'}";
      
      # 命中
      if(!$::pc{'weapon'.$_.'Class'} || $::pc{'weapon'.$_.'Class'} eq '自動計算しない'){ push @propaties, "//命中$_=$::pc{'weapon'.$_.'Acc'}"; }
      else {
        my $accMod = 0;
        if(!$partNum || $partNum eq $::pc{partCore}) {
          $accMod += $::pc{accuracyEnhance};
          $accMod += 1 if $::pc{throwing} && $category eq '投擲';
        }
        else {
          $accMod += $::pc{partEnhance};
        }
        push @propaties,
        "//命中$_=({$::pc{'weapon'.$_.'Class'}}+({器用}+{器用増強}"
        .($::pc{'weapon'.$_.'Own'}?"+2":"")
        .")/6+"
        .( ($::pc{'weapon'.$_.'Acc'}||0) + $accMod )
        .")";
      }
      # 威力・C値
      push @propaties, "//威力$_=$::pc{'weapon'.$_.'Rate'}";
      push @propaties, "//C値$_=$::pc{'weapon'.$_.'Crit'}";
      # ダメージ
      if(!$::pc{'weapon'.$_.'Class'} || $::pc{'weapon'.$_.'Class'} eq '自動計算しない'){ push @propaties, "//追加D$_=$::pc{'weapon'.$_.'Dmg'}"; }
      else {
        my $dmgMod = 0;
        if(!$partNum || $partNum eq $::pc{partCore}) {
          $dmgMod += $::pc{'mastery' . ucfirst($data::weapon_id{ $category }) };
          if($category eq 'ガン（物理）'){ $dmgMod += $::pc{masteryGun}; }
          if($::pc{"weapon${_}Note"} =~ /〈魔器〉/){ $dmgMod += $::pc{masteryArtisan}; }
        }
        else {
          if($category eq '格闘'){ $dmgMod += $::pc{masteryGrapple}; }
          elsif($category && $::pc{race} eq 'ディアボロ' && $::pc{level} >= 6){
            $dmgMod += $::pc{'mastery' . ucfirst($data::weapon_id{$category}) };
          }
        }
        my $basetext;
        if   ($category eq 'クロスボウ'){ $basetext = "{$::pc{'weapon'.$_.'Class'}}"; }
        elsif($category eq 'ガン'      ){ $basetext = "{魔動機術}"; }
        else { $basetext = "{$::pc{'weapon'.$_.'Class'}}+({筋力}+{筋力増強})/6"; }
        $basetext .= addNum($dmgMod);
        push @propaties, "//追加D$_=(${basetext}+".($::pc{'weapon'.$_.'Dmg'}||0).")";
      }

      push @propaties, '';
    }
    
    foreach my $i (1..$::pc{defenseNum}){
      next if ($::pc{"defenseTotal${i}Eva"} eq '');

      my $class = $::pc{"evasionClass${i}"};
      my $id = $data::class{$class}{id};
      my $partNum = $::pc{"evasionPart$i"};
      my $partName = $::pc{"evasionPart${i}Name"} = $::pc{"part${partNum}Name"};
      my $evaMod = 0;
      my $own_agi;
      my $hasChecked = 0;
      foreach my $j (1..$::pc{armourNum}){
        if($::pc{"defTotal${i}CheckArmour${j}"}){
          $evaMod += $::pc{"armour${j}Eva"};
          $own_agi = $::pc{"armour${j}Category"} eq '盾' && $::pc{"armour${j}Own"} ? '+2' : '';
          $hasChecked++;
        }
      }
      next if !$hasChecked && !$class;
      
      if(!$partNum || $partNum eq $::pc{partCore}) {
        $evaMod += $::pc{evasiveManeuver} + $::pc{mindsEye};
        if($::pc{evasiveManeuver} == 2 && $id ne 'Fen' && $id ne 'Bat'){ $evaMod -= 1 }
        if($::pc{mindsEye} && $id ne 'Fen'){ $evaMod -= $::pc{mindsEye} }
      }
      else {
        $evaMod += $::pc{partEnhance};
      }
      if($partName eq '邪眼'){
        $evaMod += 2;
      }
      push @propaties, "//回避${i}=("
        .($class ? "{$class}+({敏捷}+{敏捷増強}${own_agi})/6+" : '')
        .$evaMod
        .")";
      push @propaties, "//防護${i}=".($::pc{"defenseTotal${i}Def"} || 0);
    }
    
  }
  ## 魔物
  elsif($type eq 'm') {
    push @propaties, "### ■パラメータ";
    push @propaties, "//LV=$::pc{lv}";
    push @propaties, '';
    if($::pc{mount}){
        if($::pc{lv}){
          my $i = ($::pc{lv} - $::pc{lvMin} +1);
          my $num = $i > 1 ? "1-$i" : '1';
          push @propaties, "//生命抵抗=$::pc{'status'.$num.'Vit'}";
          push @propaties, "//精神抵抗=$::pc{'status'.$num.'Mnd'}";
        }
    }
    else {
      push @propaties, "//生命抵抗=$::pc{vitResist}";
      push @propaties, "//精神抵抗=$::pc{mndResist}";
    }
    
    push @propaties, '';
    foreach (1 .. $::pc{statusNum}){
      my $num = $_;
      if($::pc{mount}){
        if($::pc{lv}){
          my $i = ($::pc{lv} - $::pc{lvMin} +1);
          $_ .= $i > 1 ? "-$i" : '';
        }
      }
      push @propaties, "//部位$num=$::pc{'status'.$num.'Style'}";
      push @propaties, "//命中$num=$::pc{'status'.$_.'Accuracy'}" if $::pc{'status'.$_.'Accuracy'} ne '';
      push @propaties, "//ダメージ$num=$::pc{'status'.$_.'Damage'}" if $::pc{'status'.$_.'Damage'} ne '';
      push @propaties, "//回避$num=$::pc{'status'.$_.'Evasion'}" if $::pc{'status'.$_.'Evasion'} ne '';
      push @propaties, '';
    }
    my $skills = $::pc{skills};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/\|/｜/g;
    $skills =~ s/<br>/\n/g;
    $skills =~ s/^(?:$skill_mark)+(.+?)(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)[(（][0-9]+[）)]/push @propaties, "\/\/$1=$2";/megi;

    $skills =~ s/^
      (?<head>
        (?:$skill_mark)+
        (?<name>.+)
        [\/／]
        (
          (?<dice> (?<value>[0-9]+)  [(（]  [0-9]+  [）)]  )
          |
          [0-9]+
        )
      .+?)
      \s
      (?<note>[\s\S]*?)
      (?=^$skill_mark|^●|\z)
      /push @propaties, "\/\/$+{name}=$+{value}";push @propaties, skillNoteP($+{name},$+{note});/megix;
  }
  
  return @propaties;

  sub skillNoteP {
    my $name = shift;
    my $note = shift;
    $note =~ tr#＋－×÷#+\-*/#;
    my $out;
    $note =~ s/「?(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "\/\/${name}ダメージ=$+{dice}\n";/egi;
    return $out;
  }
}

1;