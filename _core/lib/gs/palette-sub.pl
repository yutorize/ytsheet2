################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;
my @class_names;
foreach(@data::class_names){
  push(@class_names, $_);
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
    # 基本判定
    $text .= "### ■判定\n";
    $text .= "2d+{体力集中} 体力集中\n";
    $text .= "2d+{体力持久} 体力持久\n";
    $text .= "2d+{体力反射} 体力反射\n";
    $text .= "2d+{魂魄集中} 魂魄集中\n";
    $text .= "2d+{魂魄持久} 魂魄持久\n";
    $text .= "2d+{魂魄反射} 魂魄反射\n";
    $text .= "2d+{技量集中} 技量集中\n";
    $text .= "2d+{技量持久} 技量持久\n";
    $text .= "2d+{技量反射} 技量反射\n";
    $text .= "2d+{知力集中} 知力集中\n";
    $text .= "2d+{知力持久} 知力持久\n";
    $text .= "2d+{知力反射} 知力反射\n";
    
    # 呪文行使
    foreach my $name (grep { $data::class{$_}{type} =~ /spell/ } @data::class_names){
      next if !$::pc{'lv' . $data::class{$name}{id} };
      $text .= "\n";
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■呪文行使\n";
      $text .= "//行使修正=0\n";
      last;
    }
    foreach my $name (grep { $data::class{$_}{type} =~ /spell/ } @data::class_names){
      my $id = $data::class{$name}{id};
      next if !$::pc{'lv'.$id};
      $text .= "2d+{".abilityToName($data::class{$name}{cast})."}+{$name}".addNum($::pc{spellCastModValue})." $data::class{$name}{magic}呪文行使\n";
    }
    # 攻撃
    foreach (1 .. $::pc{weaponNum}){
      next if (
        $::pc{'weapon'.$_.'HitMod'}.$::pc{'weapon'.$_.'Power'}.$::pc{'weapon'.$_.'PowerMod'} eq ''
      );
      $text .= "\n";
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■武器攻撃系\n";
      $text .= "//命中修正=0\n";
      $text .= "//ダメージ修正=0\n";
      last;
    }
    foreach (1 .. $::pc{weaponNum}){
      next if (
        $::pc{'weapon'.$_.'HitMod'}.$::pc{'weapon'.$_.'Power'}.$::pc{'weapon'.$_.'PowerMod'} eq ''
      );
      next if (
        $::pc{'weapon'.$_.'Name'}     eq $::pc{'weapon'.($_-1).'Name'}   &&
        $::pc{'weapon'.$_.'HitMod'}   eq $::pc{'weapon'.($_-1).'HitMod'} &&
        $::pc{'weapon'.$_.'Power'}    eq $::pc{'weapon'.($_-1).'Power'}  &&
        $::pc{'weapon'.$_.'PowerMod'} eq $::pc{'weapon'.($_-1).'PowerMod'}
      );
      $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
      
      my $type  = $set::weapon_type{$::pc{'weapon'.$_.'Type'}};

      $text .= "2d+{技量集中}"
        .($::pc{'weapon'.$_.'Class'} ? "+{$::pc{'weapon'.$_.'Class'}}": '')
        .addNum($::pc{'hitScoreMod'.$type})
        ."+{命中修正}";
      $text .= " 命中／$::pc{'weapon'.$_.'Name'}$::pc{'weapon'.$_.'Usage'}\n";

      $text .= "$::pc{'weapon'.$_.'Power'}"
        .($::pc{'weapon'.$_.'Class'} ? "+{$::pc{'weapon'.$_.'Class'}}": '')
        .addNum($::pc{'weapon'.$_.'PowerMod'});
      $text .= " ダメージ／$::pc{'weapon'.$_.'Name'}$::pc{'weapon'.$_.'Usage'}+{ダメージ修正}\n";
      
      $text .= "\n";
    }

    # 回避・抵抗
    $text .= "###\n" if $bot{TKY};
    $text .= "### ■回避・抵抗\n";
    $text .= "//回避修正=0\n";
    $text .= "//盾受け修正=0\n";
    $text .= "//抵抗修正=0\n";
    $text .= "2d+{技量反射}+{$::pc{dodgeClass}}".addNum($::pc{dodgeModValue}).addNum($::pc{armor1DodgeMod})."+{回避修正} 回避\n";
    $text .= "2d+{技量反射}+{$::pc{dodgeClass}}".addNum($::pc{blockModValue}).addNum($::pc{shield1BlockMod})."+{盾受け修正} 盾受け\n";
    $text .= "2d+{魂魄反射}+{冒険者レベル}".addNum($::pc{statusResistMod})."+{抵抗修正} 呪文抵抗\n";
    
    #
    $text .= "###\n" if $bot{YTC} || $bot{TKY};
  }
  ## 魔物
  elsif($type eq 'm') {
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
      if($text =~ s/\Q{$_}\E/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  $text =~ s/[0-9]+\/6/int s_eval($&)/egi;
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//体力点=$::pc{ability1Str}";
    push @propaties, "//魂魄点=$::pc{ability1Psy}";
    push @propaties, "//技量点=$::pc{ability1Tec}";
    push @propaties, "//知力点=$::pc{ability1Int}";
    push @propaties, "//集中度=$::pc{ability2Foc}";
    push @propaties, "//持久度=$::pc{ability2Edu}";
    push @propaties, "//反射度=$::pc{ability2Ref}";
    push @propaties, "//体力集中={体力点}+{集中度}";
    push @propaties, "//体力持久={体力点}+{持久度}";
    push @propaties, "//体力反射={体力点}+{反射度}";
    push @propaties, "//魂魄集中={魂魄点}+{集中度}";
    push @propaties, "//魂魄持久={魂魄点}+{持久度}";
    push @propaties, "//魂魄反射={魂魄点}+{反射度}";
    push @propaties, "//技量集中={技量点}+{集中度}";
    push @propaties, "//技量持久={技量点}+{持久度}";
    push @propaties, "//技量反射={技量点}+{反射度}";
    push @propaties, "//知力集中={知力点}+{集中度}";
    push @propaties, "//知力持久={知力点}+{持久度}";
    push @propaties, "//知力反射={知力点}+{反射度}";
    push @propaties, "### ■レベル";
    push @propaties, "//冒険者レベル=$::pc{level}";
    foreach my $name (@class_names){
      my $id = $data::class{$name}{id};
      next if !$::pc{'lv'.$id};
      push @propaties, "//$name=$::pc{'lv'.$id}";
    }
  }
  ## 魔物
  elsif($type eq 'm') {
  }
  
  return @propaties;
}

1;