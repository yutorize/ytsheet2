################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

my %skill2Stt;
foreach my $stt (keys %set::skill){
  foreach my $label (@{$set::skill{$stt}}){
    $skill2Stt{$label} = $set::sttE2J{$stt};
  }
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
  
  if(!$type){
    # 基本判定
    $text .= "### ■判定\n";
    my %added; my %skill2stt;
    foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
      my $i = 1;
      foreach my $label (@{$set::skill{$stt}}){
        next if $label =~ /:$/ && !$::pc{"skill${stt}${i}LabelBranch"};
        $label .= $::pc{"skill${stt}${i}LabelBranch"};
        $text .= "{$label}D+{$set::sttE2J{$stt}} ${label}判定\n";
        $added{$label} = 1;
        $skill2stt{$label} = $set::sttE2J{$stt};
        $i++;
      }
    }
    if($::pc{weaponTotalSkill}){
    $text .= "\n";
      my $skillLabel = $::pc{weaponTotalSkill} =~ s/^〈(.+?)〉$/$1/r;
      $text .= "{$skillLabel}D+{$skill2stt{$skillLabel}} 命中判定\n";
      $text .= "$::pc{weaponTotalAtk} ダメージ\n";
    }
    $text .= "###\n" if $bot{YTC} || $bot{TKY};
    
    # 部隊込み判定
    my $f = $::pc{forceLead} || 1;
    if($::pc{"force${f}Type"}){
      $text .= "\n";
      $text .= "### ■判定（部隊修正込み）\n";
      my %added; my %skill2stt;
      foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
        my $i = 1;
        foreach my $label (@{$set::skill{$stt}}){
          $label .= $::pc{"skill${stt}${i}LabelBranch"};
          next if $added{$label};
          $text .= "{$label}D+{$set::sttE2J{$stt}}+{部隊$set::sttE2J{$stt}} ${label}判定\n";
          $added{$label} = 1;
          $skill2stt{$label} = $set::sttE2J{$stt};
          $i++;
        }
      }
      if($::pc{weaponTotalSkill}){
        $text .= "\n";
        my $skillLabel = $::pc{weaponTotalSkill} =~ s/^〈(.+?)〉$/$1/r;
        $text .= "{$skillLabel}D+{$skill2stt{$skillLabel}}+{部隊$skill2stt{$skillLabel}} 命中判定\n";
        $text .= "$::pc{weaponTotalAtk}+{部隊攻撃} ダメージ\n";
      }
      $text .= "###\n" if $bot{YTC} || $bot{TKY};
    }
    $text .= "\n";
    # アクションセット
    $text .= "### ■アクションセット\n";
    foreach (1..$::pc{actionSetNum}){
      next if !$::pc{"actionSet${_}Skill"};
      my $stt = $::pc{"actionSet${_}Check"} || $skill2Stt{$::pc{"actionSet${_}Skill"}};
      my $acc = "({".$::pc{"actionSet${_}Skill"}."}"
        .addNum($::pc{"actionSet${_}Dice"})
        .")D+"
        ."{$stt}"
        .addNum($::pc{"actionSet${_}Mod"})
        ." 【". $::pc{"actionSet${_}Name"} . "】:"
        . join("＋", grep { !/^\s*$/ } ($::pc{"actionSet${_}Minor"},$::pc{"actionSet${_}Major"},$::pc{"actionSet${_}Other"}));

      my $dmg = $::pc{"actionSet${_}Dmg"}." 【". $::pc{"actionSet${_}Name"} . "】ダメージ" if $::pc{"actionSet${_}Dmg"};

      $text .= "$acc\n";
      $text .= "$dmg\n";

      if($::pc{"force${f}Type"}){
        $acc =~ s/ /+{部隊$stt} /;
        $dmg =~ s/ /+{部隊攻撃} /;
        $text .= $acc."（部隊修正込み）\n";
        $text .= $dmg."（部隊修正込み）\n";
      }
      $text .= "\n";
    }
    $text .= "###\n" if $bot{TKY};
    $text .= "\n";
    # リアクションセット
    $text .= "### ■リアクションセット:\n";
    foreach (1..$::pc{actionSetNum}){
      next if !$::pc{"reactionSet${_}Skill"};
      $text .= "({".$::pc{"reactionSet${_}Skill"}."}"
        .addNum($::pc{"reactionSet${_}Dice"})
        .")D+"
        ."{".($::pc{"reactionSet${_}Check"} || $skill2Stt{$::pc{"reactionSet${_}Skill"}})."}"
        .addNum($::pc{"reactionSet${_}Mod"})
        ." 【". $::pc{"reactionSet${_}Name"} . "】:"
        . join("＋", grep { !/^\s*$/ } ($::pc{"reactionSet${_}Reaction"},$::pc{"actionSet${_}Other"}))
        ."\n";
    }
    $text .= "###\n" if $bot{YTC} || $bot{TKY};
  }
  
  return $text;
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
      if($text =~ s/\{$_\}/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//レベル=$::pc{level}";
    push @propaties, "//筋力=$::pc{sttStrCheckTotal}";
    push @propaties, "//反射=$::pc{sttRefCheckTotal}";
    push @propaties, "//感覚=$::pc{sttPerCheckTotal}";
    push @propaties, "//知力=$::pc{sttIntCheckTotal}";
    push @propaties, "//精神=$::pc{sttMndCheckTotal}";
    push @propaties, "//共感=$::pc{sttEmpCheckTotal}";
    my $f = $::pc{forceLead} || 1;
    if($::pc{"force${f}Type"}){
      push @propaties, "//部隊筋力=".($::pc{"force${f}Str"}||0);
      push @propaties, "//部隊反射=".($::pc{"force${f}Ref"}||0);
      push @propaties, "//部隊感覚=".($::pc{"force${f}Per"}||0);
      push @propaties, "//部隊知力=".($::pc{"force${f}Int"}||0);
      push @propaties, "//部隊精神=".($::pc{"force${f}Mnd"}||0);
      push @propaties, "//部隊共感=".($::pc{"force${f}Emp"}||0);
      push @propaties, "//部隊攻撃=".($::pc{"force${f}Atk"}||0);
    }
    my %added;
    foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
      my $i = 1;
      foreach my $label (@{$set::skill{$stt}}){
        $label .= $::pc{"skill${stt}${i}LabelBranch"};
        my $lv = $::pc{"skill${stt}${i}Lv"};
        next if $added{$label};
        push(@propaties, "//$label=$lv");
        $added{$label} = 1;
        $i++;
      }
    }
    #push @propaties, "### ■代入パラメータ";
  }
  
  return @propaties;
}

1;