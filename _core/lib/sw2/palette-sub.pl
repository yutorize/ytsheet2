################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;
require $set::data_items;
my @classNames;
foreach(@data::class_names){
  push(@classNames, $_);
  if($_ eq 'コンジャラー'){ push(@classNames, 'ウィザード'); }
}
my %classData; my @classCasterNames;
sub setupPaletteData {
  addFreeClassData(\%::pc, \%classData, \@classNames, \@classCasterNames);
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
  Aby => {
    0   =>  1,
    10  =>  3,
    20  =>  0,
    30  =>  7,
    40  =>  9,
    50  => 13,
    60  => 11,
    70  => 13,
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
  Bib => {
    10  => '.+－猛毒の霧－|その他の(1ランクすべて|[12345]ランク以下すべて)',
    20  => '.+－破滅の槍－|その他の(1ランクすべて|[12345]ランク以下すべて)',
    30  => '.+－貫く光条－|その他の(2ランクすべて|[2345]ランク以下すべて)',
    40  => '.+－大気爆発－|その他の(3ランクすべて|[345]ランク以下すべて)',
    50  => '.+－断罪の槍－|その他の(3ランクすべて|[345]ランク以下すべて)',
    60  => '.+－闇を裂く閃光－|その他の(4ランクすべて|[45]ランク以下すべて)',
    80  => '.+－死の嵐－|その他の5ランク(以下)?すべて',
    100 => '.+－神殺の槍－|その他の5ランク(以下)?すべて',
  },
  Bar => {
    10  => '終律：春の強風|終律：冬の寒風',
    20  => '終律：獣の咆吼|終律：蛇穴の苦鳴',
    30  => '終律：火竜の舞|終律：水竜の轟',
  },
  Dar => {
    20  => '破邪光弾',
    40  => '破邪光弾',
    30  => '破邪光槍',
    60  => '破邪光槍',
  },
  Wlk => {
     0 => 1,
    10 => 1,
    20 => 3,
    30 => 5,
  }
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
  Mag => {
    50  =>  9,
  },
  Aby => {
    0   =>  2,
    20  =>  6,
    40  =>  6,
    70  => 10,
  },
  Gri => {
    20  =>  1,
    40  =>  7,
    100 => 13,
  },
  Bib => {
    20  => '.+－肉体修復－|その他の(1ランクすべて|[12345]ランク以下すべて)',
    40  => '.+－再生起動－|その他の(3ランクすべて|[345]ランク以下すべて)',
    100 => '.+－聖魔の光束－|その他の5ランク(以下)?すべて',
  },
  Bar => {
    0   => '終律：秋の実り',
    10  => '終律：華の宴',
    20  => '終律：夏の生命|終律：蒼月の光',
    30  => '終律：草原の息吹',
    40  => '終律：白日の暖',
  },
  Wlk => {
     0 => 2,
  }
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

my $skillMarkRE = "\\[[常準主補宣]\\]|[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;";

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
  my %sym;
  $sym{'@'}  = $bot{YTC} ? '@'  : ':';
  $sym{'//'} = $bot{YTC} ? '//' : 'H';
  sub setChoice {
    my $num = shift;
    my $data = shift;
    if($bot{YTC}){ return $num.'@'.$data }
    else { return "choice($data)" }
  }
  ## ＰＣ
  if(!$type){
    $text .= appendPaletteInsert('');
    # 基本判定
    $text .= "### ■非戦闘系";
    $text .= "・魔物知識" if $::pc{monsterLore};
    $text .= "・先制" if $::pc{initiative};
    $text .= "\n";
    foreach my $statusName ('器用', '敏捷', '筋力', '生命', '知力','精神') {
      $text .= "2d+{冒険者}+{${statusName}B} 冒険者＋${statusName}\n";
    }
    foreach my $class (@classNames){
      my $c_id = $classData{$class}{id};
      next if !$classData{$class}{package} || !$::pc{'lv'.$c_id};
      my %data = %{$classData{$class}{package}};
      foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data){
        if ($data{$p_id}{unlockCraft}) {
          my $craftEName = $classData{$class}{craft}{eName};
          my $craftNum = $::pc{"lv${c_id}"} + ($::pc{"${craftEName}Addition"} // 0);

          # 条件となる技芸を習得していなければ出力しない.
          next unless grep { $::pc{"craft@{[ucfirst($craftEName)]}${_}"} eq $data{$p_id}{unlockCraft} } (1 .. $craftNum);
        }

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

    # 薬草・ポーション
    {
      my @drugsLines = ();
      my $headline = '';
      my $items = $::pc{items};
      $items =~ tr/０-９＋/0-9+/;

      foreach (reverse @data::drugs) { # 〈ヒーリングポーション+1〉を〈ヒーリングポーション〉より先に解決するために逆順
        my %drug = %{$_};
        my $drugName = $drug{name};
        my $drugCategory = $drug{category};

        next unless $items =~ s/\Q${drugName}\E//g;

        my $rate = $drug{rate};
        $rate = "k${rate}" if $rate ne '';

        my $critical = $bot{BCD} && $rate ? '[13]' : '';

        my $fixedValue = '';

        if ($::pc{lvRan} > 0) {
          $fixedValue .= '{レンジャー}';
          $fixedValue .= '+{器用B}' if $drugCategory eq '薬草';
          $fixedValue .= '+{知力B}' if $drugCategory eq 'ポーション';
        }

        if ($drug{add} ne '') {
          if ($drug{add} =~ /^\d/) { # 追加値が単純な数値（〈ヒーリングポーション+1〉）
            $fixedValue .= $fixedValue ne '' ? addNum($drug{add}) : $drug{add};
          }
          else { # 追加値が単純な数値でないケース（〈テインテッドポーション〉）
            $fixedValue .= ($fixedValue ne '' ? '+' : '') . $drug{add};
          }
        }

        my $line = "${rate}${critical}";

        if ($fixedValue ne '') {
          $line .= '+' if $line ne '';
          $line .= $fixedValue;
        }

        if ($line && $line !~ /^k/) { # 威力がなければ計算コマンドにする（〈魔香水〉）
          if ($bot{YTC}) {
            $line .= '=';
          }
          elsif ($bot{BCD}) {
            $line = "C(${line})";
          }
          else {
            next;
          }
        }

        if($line){
          $line .= " 〈${drugName}〉";
          push(@drugsLines, $line);
        }

        if ($headline !~ /\Q${drugCategory}\E/) {
          $headline .= '・' if $headline ne '';
          $headline .= $drugCategory;
        }
      }

      if (@drugsLines) {
        my $drugTexts = join("\n", reverse @drugsLines); # 手前のループを逆順で回した分を相殺するために reverse
        $text .= "### ■${headline}\n${drugTexts}\n###\n";
      }
    }

    # 宣言特技
    require $set::data_feats;
    my @declarationFeats = ();
    foreach (setAcquiredFeatsLvs(\%::pc)) {
      my $level = $_;
      last if $level ne '1+' && $level > $::pc{level};
      my $featName = $::pc{"combatFeatsLv${level}"};
      next unless $featName;
      my $category = getFeatCategoryByName($featName);
      next if $category !~ /宣/;
      my $marks = '[宣]';
      $marks .= '[準]' if $category =~ /準/;
      push(@declarationFeats, [$marks, $featName]);
    }
    foreach (1 .. $::pc{mysticArtsNum}) {
      my $artsName = $::pc{"mysticArts${_}"};
      my $marks = '';
      $marks .= $& while $artsName =~ s/\[.]//;
      next if $marks !~ /宣|準/;
      next unless $artsName;
      push(@declarationFeats, [$marks, $artsName]);
    }
    if (@declarationFeats) {
      $text .= "###\n" if $bot{TKY};
      $text .= "\n### ■宣言特技\n";
      foreach (@declarationFeats) {
        (my $marks, my $featName) = @{$_};
        $text .= "${marks}《${featName}》\n";
      }
      $text .= "\n";
    }
    $text .= appendPaletteInsert('feats');

    # 魔法
    my $magicText;
  
    foreach my $class (@classNames){
      next if !($classData{$class}{magic}{jName} || $classData{$class}{craft}{stt});
      my $id   = $classData{$class}{id};
      my $name = $classData{$class}{magic}{jName} || $classData{$class}{craft}{jName};
      my $power = $classData{$class}{craft}{power} || $name;
      next if !$::pc{'lv'.$id};
      
      my %dmgTexts;
      foreach my $paNum (0 .. $::pc{paletteMagicNum}){
        next if($paNum && !($::pc{'paletteMagic'.$paNum.'Name'} && $::pc{'paletteMagic'.$paNum.'Check'.$id}));

        my $txt;

        my $activeName  = $::pc{'paletteMagic'.$paNum.'Name'} ? "＋$::pc{'paletteMagic'.$paNum.'Name'}" : '';
        my $activePower = $::pc{'paletteMagic'.$paNum.'Power'} ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Power'}") : '';
        my $activeCrit  = $::pc{'paletteMagic'.$paNum.'Crit' } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Crit' }") : '';
        my $activeRate  = $::pc{'paletteMagic'.$paNum.'Rate' } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Rate' }") : '';
        my $activeDmg   = $::pc{'paletteMagic'.$paNum.'Dmg'  } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Dmg'  }") : '';
        my $activeRoll  = $::pc{'paletteMagic'.$paNum.'Roll' } ? '#'.optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Roll' }") : '';

        my $magicPower = "{$power}" . ($name =~ /魔/ ? $activePower :"");

        sub modifyRate {
          my $base = shift;
          my $offset = shift;

          if ($offset ne '') {
            my $expression = "${base}+(${offset})";

            if ($offset =~ /^[-+\d()]+$/) {
              # 単純な数値なら計算してしまう（威力の上限・下限を考慮するため）.
              my $modified = s_eval($expression);
              $modified = 0 if $modified < 0;
              $modified = 100 if $modified > 100;
              return $modified;
            }
            else {
              # 計算できない場合は式として表現しておく.
              return "(${expression})";
            }
          }

          return $base;
        }
        
        my $half;
        my $lastModifiedRate;
        foreach my $pow (sort {$a <=> $b} keys %{$pows{$id}}) {
          if($pows{$id}{$pow} =~ /^[0-9]+$/){
            next if($pows{$id}{$pow} > $::pc{'lv'.$id} && $id ne 'Fai');
            next if($id eq 'Wiz' && $pows{$id}{$pow} > min($::pc{lvSor},$::pc{lvCon}));
            next if($id eq 'Fai' && $pows{$id}{$pow} > fairyRank($::pc{lvFai},$::pc{fairyContractEarth},$::pc{fairyContractWater},$::pc{fairyContractFire },$::pc{fairyContractWind },$::pc{fairyContractLight},$::pc{fairyContractDark }));
            next if($id eq 'Fai' && $pow == 80 && $::pc{lvFai} < 15);
          }
          else {
            my $eName = $classData{$class}{magic}{eName} || $classData{$class}{craft}{eName};
            my $exist;
            foreach(1 .. $::pc{'lv'.$id}+$::pc{$eName.'Addition'}){
              if($::pc{'magic'.ucfirst($eName).$_} =~ /^($pows{$id}{$pow})$/){ $exist = 1; last; }
              if($::pc{'craft'.ucfirst($eName).$_} =~ /^($pows{$id}{$pow})$/){ $exist = 1; last; }
            }
            if(!$exist && $class eq 'ビブリオマンサー'){
              foreach(1 .. $::pc{bibliomancyTemporaryNum}){
                if($::pc{'magicBibliomancyTemporary'.$_} =~ /^($pows{$id}{$pow})$/){ $exist = 1; last; }
              }
            }
            next if !$exist;
          }
          if($id eq 'Bar'){ $pow += $::pc{finaleEnhance} || 0; }

          my $modifiedRate = modifyRate($pow, $activeRate);
          next if $modifiedRate eq $lastModifiedRate;

          $txt .= "k${modifiedRate}\[{魔法C}$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id})."+{魔法D修正}$activeDmg${activeRoll} ダメージ\n";
          if ($id eq 'Sor' && $pow == 30 && $::pc{lvSor} >= 12) {
            $txt .= "k${modifiedRate}\[10$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id})."+{物理魔法D修正}$activeDmg${activeRoll} 物理ダメージ\n";
          }
          if ($id eq 'Fai' && $::pc{fairyContractEarth} && ($pow == 10 || $pow == 50)) {
            $txt .= "k${modifiedRate}\[12$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id})."+{物理魔法D修正}$activeDmg${activeRoll} 物理ダメージ\n";
          }
          my $halfCrit = $activeName =~ /(?:クリティカル|テアリング)キャスト(?!(?:1|I(?:[^I]|$)|Ⅰ))/i ? "{魔法C}$activeCrit" : "13";
          if ($bot{YTC}) { $half .= "k${modifiedRate}\[$halfCrit]+$magicPower" . "//" . addNum($::pc{'magicDamageAdd'.$id}) . "+{魔法D修正}$activeDmg${activeRoll} 半減\n"; }
          if ($bot{BCD}) { $half .= "k${modifiedRate}\[$halfCrit]+$magicPower" . "h+("  . ($::pc{'magicDamageAdd'.$id} || '') . "+{魔法D修正}$activeDmg)${activeRoll} 半減\n"; }

          $lastModifiedRate = $modifiedRate;
        }
        $txt .= $half;
        if($id eq 'Dru'){
          my $druidBase = "$magicPower+{物理魔法D修正} 物理ダメージ";
          if($bot{YTC}){
            $txt .= "kウルフバイト+$druidBase\n"       if($::pc{lvDru} >=  1);
            $txt .= "kソーンバッシュ+$druidBase\n"     if($::pc{lvDru} >=  3);
            $txt .= "kコングスマッシュ+$druidBase\n"   if($::pc{lvDru} >=  7);
            $txt .= "kボアラッシュ+$druidBase\n"       if($::pc{lvDru} >=  9);
            $txt .= "kマルサーヴラプレス+$druidBase\n" if($::pc{lvDru} >= 10);
            $txt .= "kルナアタック+$druidBase\n"       if($::pc{lvDru} >= 13);
            $txt .= "kダブルストンプ+$druidBase\n"     if($::pc{lvDru} >= 15);
          }
          elsif ($bot{BCD}) {
            $txt .= "Dru[0,3,6]+$druidBase／【ウルフバイト】\n"          if($::pc{lvDru} >=  1);
            $txt .= "Dru[4,7,13]+$druidBase／【ソーンバッシュ】\n"       if($::pc{lvDru} >=  3);
            $txt .= "Dru[12,15,18]+$druidBase／【コングスマッシュ】\n"   if($::pc{lvDru} >=  7);
            $txt .= "Dru[13,16,19]+$druidBase／【ボアラッシュ】\n"       if($::pc{lvDru} >=  9);
            $txt .= "Dru[18,21,24]+$druidBase／【マルサーヴラプレス】\n" if($::pc{lvDru} >= 10);
            $txt .= "Dru[18,21,36]+$druidBase／【ルナアタック】\n"       if($::pc{lvDru} >= 13);
            $txt .= "Dru[24,27,30]+$druidBase／【ダブルストンプ】\n"     if($::pc{lvDru} >= 15);
          }
        }

        if ($id eq 'Aby' && $::pc{'lv'.$id} >= 7) {
          foreach my $count (1 .. 2) {
            $txt .= makeChoiceCommand($count, ['雷', '純エネルギー', '衝撃', '断空', '毒', '呪い'], \%bot);
          }
        }

        $lastModifiedRate = undef;
        foreach my $pow (sort {$a <=> $b} keys %{$heals{$id}}) {
          if($heals{$id}{$pow} =~ /^[0-9]+$/){
            next if($::pc{'lv'.$id} < $heals{$id}{$pow});
          }
          else {
            my $eName = $classData{$class}{magic}{eName} || $classData{$class}{craft}{eName};
            my $exist;
            foreach(1 .. $::pc{'lv'.$id}+$::pc{$eName.'Addition'}){
              if($::pc{'magic'.ucfirst($eName).$_} =~ /^($heals{$id}{$pow})$/){ $exist = 1; last; }
              if($::pc{'craft'.ucfirst($eName).$_} =~ /^($heals{$id}{$pow})$/){ $exist = 1; last; }
            }
            if(!$exist && $class eq 'ビブリオマンサー'){
              foreach(1 .. $::pc{bibliomancyTemporaryNum}){
                if($::pc{'magicBibliomancyTemporary'.$_} =~ /^($pows{$id}{$pow})$/){ $exist = 1; last; }
              }
            }
            next if !$exist;
          }

          my $modifiedRate = modifyRate($pow, $activeRate);
          next if $modifiedRate eq $lastModifiedRate;

          $txt .= "k${modifiedRate}\[13]+$magicPower+{回復量修正}${activeRoll} 回復量\n";

          $lastModifiedRate = $modifiedRate;
        }

        $txt =~ s/^(k[0-9]+)\[(.+?)\]/$1\[($2)\]/gm if $bot{BCD};
        $dmgTexts{$paNum} = $txt;
      }
      
      foreach my $paNum (0 .. $::pc{paletteMagicNum}){
        next if($paNum && !($::pc{'paletteMagic'.$paNum.'Name'} && $::pc{'paletteMagic'.$paNum.'Check'.$id}));
        
        my $activeName  = $::pc{'paletteMagic'.$paNum.'Name'} ? "＋$::pc{'paletteMagic'.$paNum.'Name'}" : '';
        my $activePower = $::pc{'paletteMagic'.$paNum.'Power'} ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Power'}") : '';
        my $activeCast  = $::pc{'paletteMagic'.$paNum.'Cast' } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Cast' }") : '';

        $magicText .= "2d+{$power}";
        if   ($name =~ /魔/){ $magicText .= "$activePower+{行使修正}$activeCast ${name}行使$activeName\n"; }
        elsif($name =~ /歌/){ $magicText .= " @{[$::SW2_0 ? '呪歌' : '']}演奏\n"; }
        else                { $magicText .= " ${name}\n"; }
        
        if($dmgTexts{$paNum + 1} && $dmgTexts{$paNum} eq $dmgTexts{$paNum + 1}){
          next;
        }
        if($dmgTexts{$paNum} eq $dmgTexts{$paNum - 1}){
          $activeName = $::pc{'paletteMagic'.($paNum - 1).'Name'} ? "＋$::pc{'paletteMagic'.($paNum - 1).'Name'}" : '';
        }
        my $actionName = $name;
        $actionName = '終律' if !$::SW2_0 && $actionName eq '呪歌';
        $magicText .= $bot{BCD} ? ($dmgTexts{$paNum} =~ s/(ダメージ|半減)(\n|／)/$1／$actionName$activeName$2/gr) : $dmgTexts{$paNum};
        $magicText .= "\n";
      }
    }
    if($magicText){
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■魔法系\n";
      $text .= "<<BUFF-VAR:魔法系>>";
    }
    $text .= $magicText;
    
    $text .= appendPaletteInsert('magic');

    # 攻撃
    foreach (1 .. $::pc{weaponNum}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■武器攻撃系\n";
      $text .= "<<BUFF-VAR:武器攻撃系>>";
      last;
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
        $::pc{'weapon'.$_.'Dmg'}   eq $::pc{'weapon'.($_-1).'Dmg'}   &&
        $::pc{'weapon'.$_.'Class'} eq $::pc{'weapon'.($_-1).'Class'} &&
        $::pc{'weapon'.$_.'Category'} eq $::pc{'weapon'.($_-1).'Category'}
      );
      $::pc{'weapon'.$_.'Name'} ||= $::pc{'weapon'.($_-1).'Name'};
      if($::pc{'weapon'.$_.'Name'} eq $::pc{'weapon'.($_-1).'Name'}){
        $::pc{'weapon'.$_.'Note'} ||= $::pc{'weapon'.($_-1).'Note'}
      }
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
            $text .= "\]+";
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
        $text .= "〈$::pc{'weapon'.$_.'Category'}〉" if $::pc{'weapon'.$_.'Usage'} =~ /H投/i && $::pc{'weapon'.$_.'Category'};
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
    my %hasClass;
    my @hasClass = grep { ! $hasClass{ $::pc{"evasionClass$_"} }++ } (1 .. $::pc{defenseNum});
    foreach my $i (1..$::pc{defenseNum}){
      my $hasChecked = 0;
      foreach my $j (1..$::pc{armourNum}){
        $hasChecked++ if($::pc{"defTotal${i}CheckArmour${j}"});
      }
      next if !$hasChecked && !$::pc{"evasionClass${i}"};

      $text .= "2d+";
      $text .= $::pc{paletteUseVar} ? "{回避${i}}" : $::pc{"defenseTotal${i}Eva"};
      $text .= "+{回避修正} 回避力";
      $text .= '（' . $::pc{"evasionClass${i}"} . '）' if @hasClass > 1;
      $text .= ($::pc{"defenseTotal${i}Note"}?"／$::pc{'defenseTotal'.$i.'Note'}":'')."\n";
    }
    $text .= appendPaletteInsert('defense');
    
    #
    $text .= "###\n" if $bot{YTC} || $bot{TKY};
    # バフ変数セット
    if($text =~ /<<BUFF-VAR:魔法系>>/){
      my $vars;
      $vars .= "//魔力修正=".($::pc{magicPowerAdd}+$::pc{magicPowerEquip})."\n" if $text =~ /{魔力修正}|行使/;
      $vars .= "//行使修正=".($::pc{magicPowerAdd}+$::pc{magicPowerEquip})."\n" if $text =~ /{行使修正}/;
      $vars .= "//魔法C=10\n" if $text =~ /{魔法C}/;
      $vars .= "//魔法D修正=".($::pc{magicDamageAdd}+$::pc{magicDamageEquip})."\n" if $text =~ /{魔法D修正}/;
      $vars .= "//物理魔法D修正=".($::pc{magicDamageAdd}||0)."\n" if $text =~ /{物理魔法D修正}/;
      $vars .= "//回復量修正=0\n" if $text =~ /{回復量修正}/;
      $text =~ s/<<BUFF-VAR:魔法系>>/$vars/;
    }
    if($text =~ /<<BUFF-VAR:武器攻撃系>>/){
      my $vars;
      $vars .= "//命中修正=0\n" if $text =~ /{命中修正}/;
      $vars .= "//C修正=0\n" if $text =~ /{C修正}/;
      $vars .= "//追加D修正=0\n" if $text =~ /{追加D修正}/;
      $vars .= "//必殺効果=0\n" if $text =~ /{必殺効果}/;
      $vars .= "//クリレイ=0\n" if $text =~ /{クリレイ}/;
      $vars .= "//ガン追加D修正=0\n" if $text =~ /{ガン追加D修正}/;
      $text =~ s/<<BUFF-VAR:武器攻撃系>>/$vars/;
    }
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
      $part = '' if $::pc{partsNum} == 1;
      $part = "／$part" if $part ne '';
      $text .= "2d+{回避$_}+{回避修正} 回避".$part."\n" if $::pc{'status'.$_.'Evasion'} ne '';
    }
    $text .= "\n";

    $text .= "//命中修正=0\n";
    $text .= "//打撃修正=0\n";
    foreach (1 .. $::pc{statusNum}){
      (my $part   = $::pc{'status'.$_.'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
      (my $weapon = $::pc{'status'.$_.'Style'}) =~ s/^(.+?)[（(].+?[)）]$/$1/;
      if($part ne $weapon){ $weapon = $::pc{'status'.$_.'Style'}; }
      $weapon = '' if $::pc{partsNum} == 1;
      $weapon = "／$weapon" if $weapon ne '';
      $text .= "2d+{命中$_}+{命中修正} 命中力$weapon\n" if $::pc{'status'.$_.'Accuracy'} ne '';
      $text .= "{ダメージ$_}+{打撃修正} ダメージ".$weapon."\n" if $::pc{'status'.$_.'Damage'} ne '';
      $text .= "\n" if $::pc{'status'.$_.'Accuracy'} ne '' || $::pc{'status'.$_.'Damage'} ne '';
    }
    my $skills = $::pc{skills};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/\|/｜/g;
    $skills =~ s/<br>/\n/gi;
    $skills = convertFairyAttribute($skills) if $::pc{taxa} eq '妖精';
    $skills =~ s/^
      (?:$skillMarkRE)+
      (?<name>.+?)
      (?:限定)?
      (?: [0-9]+(?:レベル|LV)|\(.+\) )*
      [\/／]
      (?:魔力)
      ([0-9]+)
      [(（][0-9]+[）)]
      /$text .= "2d+{$+{name}} $+{name}\n\n";/megix;
    
    $skills =~ s/^
      (?<head>
        (?<mark>(?:$skillMarkRE)+)
        (?<name>.+)
        [\/／]
        (
          (
            (?<dice>(?<base>[0-9]+)  [(（]  (?<fix>[0-9]+)  [）)]  )
            |
            (?<fix>[0-9]+)
          )
          (?<other>.+?)
         |
         (?<fix>必中)
        )
      )
      (?:
        \s
        (?<note>[\s\S]*?)
      )?
      (?=^$skillMarkRE|^●|\z)
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
    push @propaties, "//器用度増強=".($::pc{sttAddA}+$::pc{sttEquipA});
    push @propaties, "//敏捷度増強=".($::pc{sttAddB}+$::pc{sttEquipB});
    push @propaties, "//筋力増強="  .($::pc{sttAddC}+$::pc{sttEquipC});
    push @propaties, "//生命力増強=".($::pc{sttAddD}+$::pc{sttEquipD});
    push @propaties, "//知力増強="  .($::pc{sttAddE}+$::pc{sttEquipE});
    push @propaties, "//精神力増強=".($::pc{sttAddF}+$::pc{sttEquipF});
    push @propaties, "//穢れ=".($::pc{sin}||0);
    push @propaties, "###" if $tool eq 'tekey';
    push @propaties, "### ■技能レベル";
    push @propaties, "//冒険者レベル=$::pc{level}";
    my @classes_en;
    foreach my $name (@classNames){
      my $id = $classData{$name}{id};
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
    push @propaties, "//器用増強={器用度増強}";
    push @propaties, "//敏捷増強={敏捷度増強}";
    push @propaties, "//生命増強={生命力増強}";
    push @propaties, "//精神増強={精神力増強}";
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
    foreach my $class (@classNames){
      my $c_id = $classData{$class}{id};
      next if !$classData{$class}{package} || !$::pc{'lv'.$c_id};
      my %data = %{$classData{$class}{package}};
      foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data){
        my $name = $class.$data{$p_id}{name};
        my $stt  = $stt_id_to_name{$data{$p_id}{stt}};
        my $add  = $::pc{'pack'.$c_id.$p_id.'Add'} + $::pc{'pack'.$c_id.$p_id.'Auto'};
        push @propaties, "//$name=\{$class\}+\{${stt}B\}".addNum($add);
      }
    }
    push @propaties, '';
    
    foreach my $class (@classNames){
      next if !($classData{$class}{magic}{jName} || $classData{$class}{craft}{stt});
      my $id = $classData{$class}{id};
      next if !$::pc{'lv'.$id};
      my $name = $classData{$class}{craft}{power} || $classData{$class}{magic}{jName} || $classData{$class}{craft}{jName};
      my $stt = $classData{$class}{craft}{stt} || '知力';
      my $own = $::pc{'magicPowerOwn'.$id} ? "+2" : "";
      my $add;
      if($classData{$class}{magic}{jName}){
        $add .= addNum $::pc{magicPowerEnhance};
        $add .= addNum $::pc{'magicPowerAdd'.$id};
        $add .= addNum $::pc{raceAbilityMagicPower};
        $add .= addNum $::pc{'raceAbilityMagicPower'.$id};
        $add .= $::pc{paletteUseBuff} ? "+{魔力修正}" : addNum($::pc{magicPowerAdd}+$::pc{magicPowerEquip});
      }
      elsif($id eq 'Alc') {
        $add .= addNum($::pc{alchemyEnhance});
      }
      push @propaties, "//$name=({$class}+({$stt}+{$stt\増強}$own)/6)$add";
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
        if($classData{$class}{accUnlock}{acc} eq 'power'){
          push @propaties,
            "//命中$_=({".($classData{$class}{craft}{power} || $classData{$class}{craft}{power}).'}'
            ."+"
            .( ($::pc{'weapon'.$_.'Acc'}||0) + $accMod )
            .")";
        }
        else {
          push @propaties,
            "//命中$_=({$::pc{'weapon'.$_.'Class'}}+({器用}+{器用増強}"
            .($::pc{'weapon'.$_.'Own'}?"+2":"")
            .")/6+"
            .( ($::pc{'weapon'.$_.'Acc'}||0) + $accMod )
            .")";
        }
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
          if($category eq '投擲'){ $dmgMod += $::pc{mightyShot}; } # 【剛力弾】
        }
        else {
          if($category eq '格闘'){ $dmgMod += $::pc{masteryGrapple}; }
          elsif($category && $::pc{race} eq 'ディアボロ' && $::pc{level} >= 6){
            $dmgMod += $::pc{'mastery' . ucfirst($data::weapon_id{$category}) };
          }
        }
        my $basetext;
        if   ($category eq 'クロスボウ'){ $basetext = $::SW2_0 ? '' : "{$::pc{'weapon'.$_.'Class'}}"; }
        elsif($category eq 'ガン'      ){ $basetext = "{魔動機術}"; }
        elsif($classData{$class}{accUnlock}{dmg} eq 'power'){ $basetext = '{'.($classData{$class}{magic}{jName} || $classData{$class}{craft}{power} || $classData{$class}{craft}{jName}).'}' }
        else { $basetext = "{$::pc{'weapon'.$_.'Class'}}+({筋力}+{筋力増強})/6"; }
        $basetext .= addNum($dmgMod);
        push @propaties, "//追加D$_=(${basetext}+".($::pc{'weapon'.$_.'Dmg'}||0).")";
      }

      push @propaties, '';
    }
    
    foreach my $i (1..$::pc{defenseNum}){
      next if ($::pc{"defenseTotal${i}Eva"} eq '');

      my $class = $::pc{"evasionClass${i}"};
      my $id = $classData{$class}{id};
      my $partNum = $::pc{"evasionPart$i"};
      my $partName = $::pc{"evasionPart${i}Name"} = $::pc{"part${partNum}Name"};
      my $evaMod = $::pc{evaEquip};
      my $ownAgi;
      my $hasChecked = 0;
      foreach my $j (1..$::pc{armourNum}){
        if($::pc{"defTotal${i}CheckArmour${j}"}){
          $evaMod += $::pc{"armour${j}Eva"};
          $ownAgi = '+2' if $::pc{"armour${j}Category"} eq '盾' && $::pc{"armour${j}Own"};
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
        .($class ? "{$class}+({敏捷}+{敏捷増強}${ownAgi})/6+" : '')
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
    $skills = convertFairyAttribute($skills) if $::pc{taxa} eq '妖精';
    $skills =~ s/^(?:$skillMarkRE)+(.+?)(?:限定)?(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)[(（][0-9]+[）)]/push @propaties, "\/\/$1=$2";/megi;

    $skills =~ s/^
      (?<head>
        (?:$skillMarkRE)+
        (?<name>.+)
        [\/／]
        (
          (
            (?<dice> (?<value>[0-9]+)  [(（]  [0-9]+  [）)]  )
            |
            [0-9]+
          )
          .+?
          |
          必中
        )
      )
      (?:
        \s
        (?<note>[\s\S]*?)
      )?
      (?=^$skillMarkRE|^●|\z)
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

sub convertFairyAttribute {
  my $skills = shift;
  $skills =~ s/^
      [○◯〇]
      (?:古代種[\/／])?
      属性[:：]
      ([土水・氷炎風光闇&＆]+)
      [\/／]
      (魔力\d+[(（]\d+[）)])
      (\n|$)
      /▶妖精魔法($1)／$2$3/x;
  return $skills;
}

1;
