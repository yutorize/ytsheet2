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
sub magicPows {
  my %pows = (
    'Sor' => [10,20],
    'Con' => [ 0],
    'Wiz' => [],
    'Pri' => [10],
    'Mag' => [],
    'Fai' => [10],
    'Dru' => [],
    'Dem' => [10,20],
    'Gri' => [10,20],
    'Bar' => [10],
  );
  my %heals = (
    'Con' => [ 0],
    'Pri' => [10],
    'Gri' => [20],
    'Bar' => [ 0,10,20],
  );
  if($::pc{'lvSor'} >=  5){ push(@{$pows{'Sor'}}, 30) }
  if($::pc{'lvSor'} >=  8){ push(@{$pows{'Sor'}}, 40) }
  if($::pc{'lvSor'} >= 11){ push(@{$pows{'Sor'}}, 50) }
  if($::pc{'lvSor'} >= 14){ push(@{$pows{'Sor'}}, 60) }
  if($::pc{'lvSor'} >= 15){ push(@{$pows{'Sor'}},100) }
  if($::pc{'lvCon'} >=  8){ push(@{$pows{'Con'}}, 20) }
  if($::pc{'lvCon'} >=  9){ push(@{$pows{'Con'}}, 30) }
  if($::pc{'lvCon'} >= 15){ push(@{$pows{'Con'}}, 60) }
  if(min($::pc{'lvSor'},$::pc{'lvCon'}) >=  8){ push(@{$pows{'Wiz'}}, 10) }
  if(min($::pc{'lvSor'},$::pc{'lvCon'}) >=  4){ push(@{$pows{'Wiz'}}, 20) }
  if(min($::pc{'lvSor'},$::pc{'lvCon'}) >= 10){ push(@{$pows{'Wiz'}}, 30) }
  if(min($::pc{'lvSor'},$::pc{'lvCon'}) >= 13){ push(@{$pows{'Wiz'}}, 70) }
  if($::pc{'lvPri'} >=  5){ push(@{$pows{'Pri'}}, 20) }
  if($::pc{'lvPri'} >=  9){ push(@{$pows{'Pri'}}, 30) }
  if($::pc{'lvFai'} >=  5){ push(@{$pows{'Fai'}}, 20) }
  if($::pc{'lvFai'} >= 10){ push(@{$pows{'Fai'}}, 40) }
  if($::pc{'lvFai'} >= 11){ push(@{$pows{'Fai'}}, 50) }
  if($::pc{'lvFai'} >= 14){ push(@{$pows{'Fai'}}, 60) }
  if($::pc{'lvMag'} >=  5){ push(@{$pows{'Mag'}}, 30) }
  if($::pc{'lvMag'} >= 15){ push(@{$pows{'Mag'}}, 90) }
  if($::pc{'lvDru'} >=  4){ push(@{$pows{'Dru'}}, 10,20) }
  if($::pc{'lvDru'} >= 13){ push(@{$pows{'Dru'}}, 30) }
  if($::pc{'lvDru'} >= 15){ push(@{$pows{'Dru'}}, 50) }
  if($::pc{'lvDem'} >=  5){ push(@{$pows{'Dem'}}, 30); push(@{$pows{'Dem'}}, 40); push(@{$pows{'Dem'}}, 50) }
  if($::pc{'lvGri'} >=  4){ push(@{$pows{'Gri'}}, 30) }
  if($::pc{'lvGri'} >=  7){ push(@{$pows{'Gri'}}, 40); push(@{$pows{'Gri'}}, 50) }
  if($::pc{'lvGri'} >= 10){ push(@{$pows{'Gri'}}, 60) }
  if($::pc{'lvGri'} >= 13){ push(@{$pows{'Gri'}}, 80); push(@{$pows{'Gri'}},100) }
  if($::pc{'lvBar'} >=  5){ push(@{$pows{'Bar'}}, 20) }
  if($::pc{'lvBar'} >= 10){ push(@{$pows{'Bar'}}, 30) }
  
  if($::pc{'lvCon'} >= 11){ push(@{$heals{'Con'}}, 30) }
  if($::pc{'lvPri'} >=  5){ push(@{$heals{'Pri'}}, 30) }
  if($::pc{'lvPri'} >= 10){ push(@{$heals{'Pri'}}, 50) }
  if($::pc{'lvPri'} >= 13){ push(@{$heals{'Pri'}}, 70) }
  if($::pc{'lvGri'} >=  7){ push(@{$heals{'Gri'}}, 40) }
  if($::pc{'lvGri'} >= 13){ push(@{$heals{'Gri'}},100) }
  if($::pc{'lvBar'} >=  5){ push(@{$heals{'Bar'}}, 30) }
  if($::pc{'lvBar'} >= 10){ push(@{$heals{'Bar'}}, 40) }
  
  return (\%pows, \%heals);
}

my $skill_mark = "[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;";

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{'YTC'} = 1; }
  elsif($tool eq 'bcdice'){ $bot{'BCD'} = 1; }
  ## ＰＣ
  if(!$type){
    # 基本判定
    $text .= "### ■非戦闘系\n";
    $text .= "2d6+{冒険者}+{器用B} 冒険者＋器用\n";
    $text .= "2d6+{冒険者}+{敏捷B} 冒険者＋敏捷\n";
    $text .= "2d6+{冒険者}+{筋力B} 冒険者＋筋力\n";
    $text .= "2d6+{冒険者}+{知力B} 冒険者＋知力\n";
    foreach my $class (@class_names){
      my $c_id = $data::class{$class}{'id'};
      next if !$data::class{$class}{'package'} || !$::pc{'lv'.$c_id};
      my %data = %{$data::class{$class}{'package'}};
      foreach my $p_id (sort{$data{$a}{'stt'} cmp $data{$b}{'stt'} || $data{$a} cmp $data{$b}} keys %data){
        my $name = $class.$data{$p_id}{'name'};
        $text .= "2d6+{$name} $name\n";
        if($data{$p_id}{'monsterLore'} && $::pc{'monsterLoreAdd'}){ $text .= "2d6+{$name}+$::pc{'monsterLoreAdd'} 魔物知識\n"; }
        if($data{$p_id}{'initiative' } && $::pc{'initiativeAdd' }){ $text .= "2d6+{$name}+$::pc{'initiativeAdd' } 先制\n"; }
      }
    }
    $text .= "\n";
    
    $text .= "### ■魔法系\n";
    # 魔法
    my ($pows, $heals) = magicPows();
    my %pows  = %{$pows};
    my %heals = %{$heals};
    
    $text .= "//魔力修正=".($::pc{'magicPowerAdd'}||0)."\n";
    $text .= "//行使修正=".($::pc{'magicCastAdd'}||0)."\n";
    $text .= "//魔法C=10\n";
    $text .= "//魔法D修正=".($::pc{'magicDamageAdd'}||0)."\n";
    foreach my $name (@class_names){
      next if !($data::class{$name}{'magic'}{'jName'} || $data::class{$name}{'craft'}{'stt'});
      my $id   = $data::class{$name}{'id'};
      my $name = $data::class{$name}{'magic'}{'jName'} || $data::class{$name}{'craft'}{'jName'};
      next if !$::pc{'lv'.$id};
      
      $text .= "2d6+{$name}";
      if   ($name =~ /魔/){ $text .= "+{魔力修正}+{行使修正} ${name}行使\n"; }
      elsif($name =~ /歌/){ $text .= " 呪歌演奏\n"; }
      else                { $text .= " ${name}\n"; }
      
      foreach my $pow (@{$pows{$id}}) {
        if($id eq 'Bar'){ $pow += $::pc{'finaleEnhance'} || 0; }
        $text .= "k${pow}[{魔法C}]+{$name}".($name =~ /魔/?'+{魔力修正}':'').addNum($::pc{'magicDamageAdd'.$id})."+{魔法D修正} ダメージ".($bot{'BCD'}?"／${name}":"")."\n";
        if ($bot{'YTC'}) { $text .= "k${pow}[13]+{$name}" . ($name =~ /魔/?'+{魔力修正}':'') . "//" . addNum($::pc{'magicDamageAdd'.$id}) . "+{魔法D修正} 半減\n"; }
        if ($bot{'BCD'}) { $text .= "k${pow}[13]+{$name}" . ($name =~ /魔/?'+{魔力修正}':'') . "h+("  . ($::pc{'magicDamageAdd'.$id} || 0) . "+{魔法D修正}) 半減／${name}\n"; }
      }
      if($id eq 'Dru'){
        if($bot{'YTC'}){
          $text .= "kソーンバッシュ+{$name}+{魔力修正} ダメージ\n"     if($::pc{'lvDru'} >=  3);
          $text .= "kコングスマッシュ+{$name}+{魔力修正} ダメージ\n"   if($::pc{'lvDru'} >=  7);
          $text .= "kボアラッシュ+{$name}+{魔力修正} ダメージ\n"       if($::pc{'lvDru'} >=  9);
          $text .= "kマルサーヴラプレス+{$name}+{魔力修正} ダメージ\n" if($::pc{'lvDru'} >= 10);
          $text .= "kルナアタック+{$name}+{魔力修正} ダメージ\n"       if($::pc{'lvDru'} >= 13);
          $text .= "kダブルストンプ+{$name}+{魔力修正} ダメージ\n"     if($::pc{'lvDru'} >= 15);
        }
        elsif ($bot{'BCD'}) {
          $text .= "Dru[4,7,13]+{$name}+{魔力修正} ダメージ／ソーンバッシュ\n"   if($::pc{'lvDru'} >=  3);
          $text .= "Dru[12,15,18]+{$name}+{魔力修正} ダメージ／コングスマッシュ\n" if($::pc{'lvDru'} >=  7);
          $text .= "Dru[13,16,19]+{$name}+{魔力修正} ダメージ／ボアラッシュ\n" if($::pc{'lvDru'} >=  9);
          $text .= "Dru[18,21,24]+{$name}+{魔力修正} ダメージ／マルサーヴラプレス\n" if($::pc{'lvDru'} >= 10);
          $text .= "Dru[18,21,36]+{$name}+{魔力修正} ダメージ／ルナアタック\n" if($::pc{'lvDru'} >= 13);
          $text .= "Dru[24,27,30]+{$name}+{魔力修正} ダメージ／ダブルストンプ\n" if($::pc{'lvDru'} >= 15);
        }
      }
      
      foreach my $pow (@{$heals{$id}}) {
        $text .= "k${pow}[13]+{$name}".($name =~ /魔/?'+{魔力修正}':'')." 回復量".($bot{'BCD'}?"／${name}":"")."\n"
      }
      $text .= "\n";
    }
    
    # 攻撃
    $text .= "### ■武器攻撃系\n";
    $text .= "//命中修正=0\n";
    $text .= "//C修正=0\n";
    $text .= "//追加D修正=0\n";
    $text .= "//必殺効果=0\n";
    $text .= "//クリレイ=0\n";
    
    foreach (1 .. $::pc{'weaponNum'}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      
      $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
      $text .= "2d6+{命中$_}+{命中修正}";
      $text .= " 命中力／$::pc{'weapon'.$_.'Name'}\n";
      
      $::pc{'weapon'.$_.'Crit'} =~ s/⑦|➆/7/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑧|➇/8/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑨|➈/9/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑩|➉/10/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑪/11/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑫/12/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑬/13/;
      if   ($bot{'YTC'} ){ $text .= "k$::pc{'weapon'.$_.'Rate'}\[$::pc{'weapon'.$_.'Crit'}+{C修正}\]+{追加D$_}+{追加D修正}{出目修正}"; }
      elsif($bot{'BCD'} ){ $text .= "k$::pc{'weapon'.$_.'Rate'}\[($::pc{'weapon'.$_.'Crit'}+{C修正})\]+{追加D$_}+{追加D修正}{出目修正}"; }
      
      if($::pc{'weapon'.$_.'Name'} =~ /首切/ || $::pc{'weapon'.$_.'Note'} =~ /首切/){
        $text .= $bot{'YTC'} ? '首切' : $bot{'BCD'} ? 'r5' : '';
      }
      $text .= " ダメージ";
      $text .= "／$::pc{'weapon'.$_.'Name'}" if $bot{'BCD'};
      $text .= "\n";
      $text .= "\n";
    }
    $text .= "//出目修正=\$+{クリレイ}\#{必殺効果}\n";
    # 抵抗回避
    $text .= "### ■抵抗回避\n";
    $text .= "//生命抵抗修正=0\n";
    $text .= "//精神抵抗修正=0\n";
    $text .= "//回避修正=0\n";
    $text .= "2d6+{生命抵抗}+{生命抵抗修正} 生命抵抗力\n";
    $text .= "2d6+{精神抵抗}+{精神抵抗修正} 精神抵抗力\n";
    $text .= "2d6+{回避1}+{回避修正} 回避力".($::pc{'defenseTotal1Note'}?"／$::pc{'defenseTotal1Note'}":'')."\n";
    $text .= "2d6+{回避2}+{回避修正} 回避力".($::pc{'defenseTotal2Note'}?"／$::pc{'defenseTotal2Note'}":'')."\n" if $::pc{'defenseTotal2Eva'} ne '';
    $text .= "2d6+{回避3}+{回避修正} 回避力".($::pc{'defenseTotal3Note'}?"／$::pc{'defenseTotal3Note'}":'')."\n" if $::pc{'defenseTotal3Eva'} ne '';
    $text .= "\n";
    
    #
    $text .= "###\n";
  }
  ## 魔物
  elsif($type eq 'm') {
    $text .= "//生命抵抗修正=0\n";
    $text .= "//精神抵抗修正=0\n";
    $text .= "//回避修正=0\n";
    $text .= "2d6+{生命抵抗}+{生命抵抗修正} 生命抵抗力\n";
    $text .= "2d6+{精神抵抗}+{精神抵抗修正} 精神抵抗力\n";
    foreach (1 .. $::pc{'statusNum'}){
      (my $part   = $::pc{'status'.$_.'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
      $text .= "2d6+{回避$_}+{回避修正} 回避／".$part."\n" if $::pc{'status'.$_.'Evasion'} ne '';
    }
    $text .= "\n";

    $text .= "//命中修正=0\n";
    $text .= "//打撃修正=0\n";
    foreach (1 .. $::pc{'statusNum'}){
      (my $part   = $::pc{'status'.$_.'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
      (my $weapon = $::pc{'status'.$_.'Style'}) =~ s/^(.+?)[（(].+?[)）]$/$1/;
      if($part ne $weapon){ $weapon = $::pc{'status'.$_.'Style'}; }
      $text .= "2d6+{命中$_}+{命中修正} 命中力／$weapon\n" if $::pc{'status'.$_.'Accuracy'} ne '';
      $text .= "{ダメージ$_}+{打撃修正} ダメージ／".$weapon."\n" if $::pc{'status'.$_.'Damage'} ne '';
      $text .= "\n";
    }
    my $skills = $::pc{'skills'};
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
      /$text .= "2d6+{$+{name}} $+{name}\n\n";/megix;
    
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
            .($+{base} ne '' ?"2d6+{$+{name}} ".convertMark($+{mark})."$+{name}$+{other}\n":'')
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
    $note =~ s/「?(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "{${name}ダメージ} $+{elm}$+{dmg}ダメージ\n".($half?"{${name}ダメージ}\/\/2 $+{elm}$+{dmg}ダメージ（半減）\n":'');/smegi if $bot{'YTC'};
    $note =~ s/「?(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "{${name}ダメージ} $+{elm}$+{dmg}ダメージ／${name}\n".($half?"({${name}ダメージ})\/2U $+{elm}$+{dmg}ダメージ（半減）／${name}\n":'');/smegi if $bot{'BCD'};
    return $out;
  }
  sub convertMark {
    my $text = shift;
    return $text if $bot{'BCD'}; #BCDは変換しない
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
### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  
  my $text = palettePreset($tool,$type);
  my %propaty;
  foreach (paletteProperties($type)){
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
  'A' => '器用',
  'B' => '敏捷',
  'C' => '筋力',
  'D' => '生命',
  'E' => '知力',
  'F' => '精神',
);
sub paletteProperties {
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//器用度=$::pc{'sttDex'}".($::pc{'sttAddA'}?"+$::pc{'sttAddA'}":"");
    push @propaties, "//敏捷度=$::pc{'sttAgi'}".($::pc{'sttAddB'}?"+$::pc{'sttAddB'}":"");
    push @propaties, "//筋力=$::pc{'sttStr'}".($::pc{'sttAddC'}?"+$::pc{'sttAddC'}":"");
    push @propaties, "//生命力=$::pc{'sttVit'}".($::pc{'sttAddD'}?"+$::pc{'sttAddD'}":"");
    push @propaties, "//知力=$::pc{'sttInt'}".($::pc{'sttAddE'}?"+$::pc{'sttAddE'}":"");
    push @propaties, "//精神力=$::pc{'sttMnd'}".($::pc{'sttAddF'}?"+$::pc{'sttAddF'}":"");
    push @propaties, "### ■技能レベル";
    push @propaties, "//冒険者レベル=$::pc{'level'}";
    my @classes_en;
    foreach my $name (@class_names){
      my $id = $data::class{$name}{'id'};
      next if !$::pc{'lv'.$id};
      push @propaties, "//$name=$::pc{'lv'.$id}";
      push @classes_en, "//".uc($id)."={$name}";
    }
    push @propaties, '';
    push @propaties, "### ■代入パラメータ";
    push @propaties, "//器用={器用度}";
    push @propaties, "//敏捷={敏捷度}";
    push @propaties, "//生命={生命力}";
    push @propaties, "//精神={精神力}";
    push @propaties, "//器用B=(({器用})/6)";
    push @propaties, "//敏捷B=(({敏捷})/6)";
    push @propaties, "//筋力B=(({筋力})/6)";
    push @propaties, "//生命B=(({生命})/6)";
    push @propaties, "//知力B=(({知力})/6)";
    push @propaties, "//精神B=(({精神})/6)";
    push @propaties, "//DEX={器用}";
    push @propaties, "//AGI={敏捷}";
    push @propaties, "//STR={筋力}";
    push @propaties, "//VIT={生命}";
    push @propaties, "//INT={知力}";
    push @propaties, "//MND={精神}";
    push @propaties, "//dexB={器用B}";
    push @propaties, "//agiB={敏捷B}";
    push @propaties, "//strB={筋力B}";
    push @propaties, "//vitB={生命B}";
    push @propaties, "//intB={知力B}";
    push @propaties, "//mndB={精神B}";
    push @propaties, @classes_en;
    push @propaties, '';
    push @propaties, "//生命抵抗=({冒険者}+{生命B})".($::pc{'vitResistAddTotal'}?"+$::pc{'vitResistAddTotal'}":"");
    push @propaties, "//精神抵抗=({冒険者}+{精神B})".($::pc{'mndResistAddTotal'}?"+$::pc{'mndResistAddTotal'}":"");
    push @propaties, "//最大HP=$::pc{'hpTotal'}";
    push @propaties, "//最大MP=$::pc{'mpTotal'}";
    push @propaties, '';
    push @propaties, "//冒険者={冒険者レベル}";
    push @propaties, "//LV={冒険者}";
    push @propaties, '';
    #push @propaties, "//魔物知識=$::pc{'monsterLore'}" if $::pc{'monsterLore'};
    #push @propaties, "//先制力=$::pc{'initiative'}" if $::pc{'initiative'};
    foreach my $class (@class_names){
      my $c_id = $data::class{$class}{'id'};
      next if !$data::class{$class}{'package'} || !$::pc{'lv'.$c_id};
      my %data = %{$data::class{$class}{'package'}};
      foreach my $p_id (sort{$data{$a}{'stt'} cmp $data{$b}{'stt'} || $data{$a} cmp $data{$b}} keys %data){
        my $name = $class.$data{$p_id}{'name'};
        my $stt  = $stt_id_to_name{$data{$p_id}{'stt'}};
        push @propaties, "//$name=\{$class\}+\{${stt}B\}".($::pc{'pack'.$c_id.$p_id.'Add'} ? '+'.$::pc{'pack'.$c_id.$p_id.'Add'} : '');
      }
    }
    push @propaties, '';
    
    foreach my $name (@class_names){
      next if !($data::class{$name}{'magic'}{'jName'} || $data::class{$name}{'craft'}{'stt'});
      my $id = $data::class{$name}{'id'};
      next if !$::pc{'lv'.$id};
      my $magic = $data::class{$name}{'magic'}{'jName'} || $data::class{$name}{'craft'}{'jName'};
      my $stt = $data::class{$name}{'craft'}{'stt'} || '知力';
      my $own = $::pc{'magicPowerOwn'.$id} ? "+2" : "";
      my $add;
      if($data::class{$name}{'magic'}{'jName'}){
        $add .= addNum $::pc{'magicPowerEnhance'};
        $add .= addNum $::pc{'magicPowerAdd'.$id};
      }
      elsif($id eq 'Alc') {
        $add .= addNum($::pc{'alchemyEnhance'});
      }
      push @propaties, "//".$magic."=({".$name."}+({".$stt."}".$own.")/6)".$add;
    }
    push @propaties, '';
    
    foreach (1 .. $::pc{'weaponNum'}){
      next if $::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Usage'}.$::pc{'weapon'.$_.'Reqd'}.
              $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.$::pc{'weapon'.$_.'Crit'}.
              $::pc{'weapon'.$_.'Dmg'}.$::pc{'weapon'.$_.'Own'}.$::pc{'weapon'.$_.'Note'}
              eq '';
      $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
      $::pc{'weapon'.$_.'Crit'} =~ s/⑦|➆/7/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑧|➇/8/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑨|➈/9/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑩|➉/10/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑪/11/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑫/12/;
      $::pc{'weapon'.$_.'Crit'} =~ s/⑬/13/;

      push @propaties, "//武器$_=$::pc{'weapon'.$_.'Name'}";

      if(!$::pc{'weapon'.$_.'Class'} || $::pc{'weapon'.$_.'Class'} eq '自動計算しない'){ push @propaties, "//命中$_=$::pc{'weapon'.$_.'Acc'}"; }
      else { push @propaties, "//命中$_=({$::pc{'weapon'.$_.'Class'}}+({器用}".($::pc{'weapon'.$_.'Own'}?"+2":"").")/6+".($::pc{'weapon'.$_.'Acc'}||0).")"; }

      push @propaties, "//威力$_=$::pc{'weapon'.$_.'Rate'}";
      push @propaties, "//C値$_=$::pc{'weapon'.$_.'Crit'}";

      if(!$::pc{'weapon'.$_.'Class'} || $::pc{'weapon'.$_.'Class'} eq '自動計算しない'){ push @propaties, "//追加D$_=$::pc{'weapon'.$_.'Dmg'}"; }
      else {
        my $basetext;
        if   ($::pc{'weapon'.$_.'Category'} eq 'クロスボウ'){ $basetext = "{$::pc{'weapon'.$_.'Class'}}"; }
        elsif($::pc{'weapon'.$_.'Category'} eq 'ガン'      ){ $basetext = "{魔動機術}"; }
        else { $basetext = "{$::pc{'weapon'.$_.'Class'}}+({筋力})/6"; }
        my $mastery = $::pc{'mastery' . ucfirst($data::weapon_id{ $::pc{'weapon'.$_.'Category'} }) };
           $basetext .= $mastery ? "+$mastery" : '';
        push @propaties, "//追加D$_=(${basetext}+".($::pc{'weapon'.$_.'Dmg'}||0).")";
      }

      push @propaties, '';
    }
    
    foreach my $i (1..3){
      next if ($::pc{"defenseTotal${i}Eva"} eq '');
      my $own_agi = $::pc{"defTotal${i}CheckShield1"} && $::pc{'shield1Own'} ? '+2' : '';
      push @propaties, "//回避${i}=("
        .($::pc{'evasionClass'} ? "{$::pc{'evasionClass'}}+({敏捷}${own_agi})/6+" : '')
        .($::pc{'evasiveManeuver'}
          + ($::pc{"defTotal${i}CheckArmour1"}   ? $::pc{'armour1Eva'} : 0)
          + ($::pc{"defTotal${i}CheckShield1"}   ? $::pc{'shield1Eva'} : 0)
          + ($::pc{"defTotal${i}CheckDefOther1"} ? $::pc{'defOther1Eva'} : 0)
          + ($::pc{"defTotal${i}CheckDefOther2"} ? $::pc{'defOther2Eva'} : 0)
          + ($::pc{"defTotal${i}CheckDefOther3"} ? $::pc{'defOther3Eva'} : 0)
        )
        .")";
    }
    push @propaties, "//防護1=".($::pc{'defenseTotal1Def'} || $::pc{'defenseTotalAllDef'} || 0);
    push @propaties, "//防護2=$::pc{'defenseTotal2Def'}" if $::pc{'defenseTotal2Def'} ne '';
    push @propaties, "//防護3=$::pc{'defenseTotal3Def'}" if $::pc{'defenseTotal3Def'} ne '';
    
  }
  ## 魔物
  elsif($type eq 'm') {
    push @propaties, "### ■パラメータ";
    push @propaties, "//LV=$::pc{'lv'}";
    push @propaties, '';
    push @propaties, "//生命抵抗=$::pc{'vitResist'}";
    push @propaties, "//精神抵抗=$::pc{'mndResist'}";
    
    push @propaties, '';
    foreach (1 .. $::pc{'statusNum'}){
      push @propaties, "//部位$_=$::pc{'status'.$_.'Style'}";
      push @propaties, "//命中$_=$::pc{'status'.$_.'Accuracy'}" if $::pc{'status'.$_.'Accuracy'} ne '';
      push @propaties, "//ダメージ$_=$::pc{'status'.$_.'Damage'}" if $::pc{'status'.$_.'Damage'} ne '';
      push @propaties, "//回避$_=$::pc{'status'.$_.'Evasion'}" if $::pc{'status'.$_.'Evasion'} ne '';
      push @propaties, '';
    }
    my $skills = $::pc{'skills'};
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