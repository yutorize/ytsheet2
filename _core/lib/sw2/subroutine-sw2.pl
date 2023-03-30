use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-SW ##################################################################################

### クラス色分け --------------------------------------------------
sub class_color {
  my $text = shift;
  $text =~ s/((?:.*?)(?:[0-9]+))/<span>$1<\/span>/g;
  $text =~ s/<span>((?:ファイター|グラップラー|フェンサー|バトルダンサー)(?:[0-9]+?))<\/span>/<span class="melee">$1<\/span>/;
  $text =~ s/<span>((?:プリースト)(?:[0-9]+?))<\/span>/<span class="healer">$1<\/span>/;
  $text =~ s/<span>((?:スカウト|ウォーリーダー|レンジャー)(?:[0-9]+?))<\/span>/<span class="initiative">$1<\/span>/;
  $text =~ s/<span>((?:セージ)(?:[0-9]+?))<\/span>/<span class="knowledge">$1<\/span>/;
  return $text;
}

### タグ変換 --------------------------------------------------
sub tag_unescape {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  #$text =~ s/\{\{([0-9\+\-\*\/\%\(\) ]+?)\}\}/s_eval($1);/eg;
  
  $text =~ s#(―+)#<span class="d-dash">$1</span>#g;
  
  $text =~ s{[©]}{<i class="s-icon copyright">©</i>}gi;

  if($::in{'mode'} ne 'download'){
    $text =~ s/\[魔\]/<img alt="&#91;魔&#93;" class="i-icon" src="${set::icon_dir}wp_magic.png">/gi;
    $text =~ s/\[刃\]/<img alt="&#91;刃&#93;" class="i-icon" src="${set::icon_dir}wp_edge.png">/gi;
    $text =~ s/\[打\]/<img alt="&#91;打&#93;" class="i-icon" src="${set::icon_dir}wp_blow.png">/gi;
  }
  else {
    $text =~ s|\[魔\]|<img alt="&#91;魔&#93;" class="i-icon" src="data:image/webp;base64,UklGRqwAAABXRUJQVlA4TJ8AAAAvD8ADED9AqIGhhP5FvFQxEa6LmgCEILtJBvnkvBhvESIBCHf8jwZ44QAfzH8IQD8sZ2K6bB8tgeNGktymAZLSmz6E/R5A9z5wI6BJQfzavcsfUBAR/U/AwRmBrkMMOtVnMZxWXvYvc5Vfi8Gc57JPOM2vxTRxVS5767suXovlPnGH7G2uCU+wPO/h+bW57+GIwWvCGbqoHZxfuo7/BAAA">|gi;
    $text =~ s|\[刃\]|<img alt="&#91;刃&#93;" class="i-icon" src="data:image/webp;base64,UklGRmgAAABXRUJQVlA4TFwAAAAvD8ADECcgECD8r1ix5EMgQOhXpkaDgrQNmPq33J35D8B/Cs4KriLZDZv9EAIHgs2gAiCNzR+VyiGi/wGIWX8565unQe15VkDtBrkCr3ZDnhVQt41fgHwX6nojAA==">|gi;
    $text =~ s|\[打\]|<img alt="&#91;打&#93;" class="i-icon" src="data:image/webp;base64,UklGRnAAAABXRUJQVlA4TGMAAAAvD8ADEB+gkG0EODSdId0jEEgC2V9sEQVpG7C49roz/wF8ppPAprb2Ji8JxUO38jthZ84eCzQJHTURgQSmbiOi/4GE4Cs4f8Xxx4x/SfOVNJdDdkez1dghIZdQYvAKLJADIQAA">|gi;
  }
  
  $text =~ s/'''(.+?)'''/<span class="oblique">$1<\/span>/gi; # 斜体
  $text =~ s/''(.+?)''/<b>$1<\/b>/gi;  # 太字
  $text =~ s/%%(.+?)%%/<span class="strike">$1<\/span>/gi;  # 打ち消し線
  $text =~ s/__(.+?)__/<span class="underline">$1<\/span>/gi;  # 下線
  $text =~ s/\{\{(.+?)\}\}/<span style="color:transparent">$1<\/span>/gi;  # 透明
  $text =~ s/[|｜]([^|｜]+?)《(.+?)》/<ruby>$1<rp>(<\/rp><rt>$2<\/rt><rp>)<\/rp><\/ruby>/gi; # なろう式ルビ
  $text =~ s/《《(.+?)》》/<span class="text-em">$1<\/span>/gi; # カクヨム式傍点
  
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/&tag_link_url($2,$1)/egi; # リンク
  $text =~ s/(making|能力値作成(?:履歴)?#([0-9]+(?:-[0-9]+)?))/<a href="?&mode=making&num=$2">$1<\/a>/gi; # メイキングリンク
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/<a href="?id=$2">$1<\/a>/gi; # シート内リンク
  $text =~ s/(?<!href=")(https?:\/\/[^\s\<]+)/<a href="$1" target="_blank">$1<\/a>/gi; # 自動リンク
  
  $text =~ s/\n/<br>/gi;
  
  if($::SW2_0){
    $text =~ s/「((?:[○◯〇＞▶〆☆≫»□☐☑🗨▽▼]|&gt;&gt;)+)/"「".&text_convert_icon($1);/egi;
  } else {
    $text =~ s/「((?:[○◯〇△＞▶〆☆≫»□☐☑🗨]|&gt;&gt;)+)/"「".&text_convert_icon($1);/egi;
  }
  
  return $text;
}
sub text_convert_icon {
  my $text = $_[0];
  if($::SW2_0){
    $text =~ s{[○◯〇]}{<i class="s-icon passive">○</i>}gi;
    $text =~ s{[＞▶〆]}{<i class="s-icon major0">〆</i>}gi;
    $text =~ s{[☆≫»]|&gt;&gt;}{<i class="s-icon minor0">☆</i>}gi;
    $text =~ s{[□☐☑🗨]}{<i class="s-icon active0">☑</i>}gi;
    $text =~ s{[▽]}{<i class="s-icon condition">▽</i>}gi;
    $text =~ s{[▼]}{<i class="s-icon selection">▼</i>}gi;
  } else {
    $text =~ s{[○◯〇]}{<i class="s-icon passive">○</i>}gi;
    $text =~ s{[△]}{<i class="s-icon setup">△</i>}gi;
    $text =~ s{[＞▶〆]}{<i class="s-icon major">▶</i>}gi;
    $text =~ s{[☆≫»]|&gt;&gt;}{<i class="s-icon minor">≫</i>}gi;
    $text =~ s{[□☐☑🗨]}{<i class="s-icon active">☑</i>}gi;
  }
  
  return $text;
} 
sub tag_unescape_ytc {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  $text =~ s/\[魔\]/&#91;魔&#93;/gi;
  $text =~ s/\[刃\]/&#91;刃&#93;/gi;
  $text =~ s/\[打\]/&#91;打&#93;/gi;
  
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/$1/gi; # リンク削除
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/$1/gi; # シート内リンク削除
  
  $text =~ s/&#91;(.)&#93;/[$1]/g;
  
  $text =~ s/\n/<br>/gi;
  return $text;
}

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{'ver'};
  delete $pc{'updateMessage'};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($pc{'colorHeadBgA'}) {
    ($pc{'colorHeadBgH'}, $pc{'colorHeadBgS'}, $pc{'colorHeadBgL'}) = rgb_to_hsl($pc{'colorHeadBgR'},$pc{'colorHeadBgG'},$pc{'colorHeadBgB'});
    ($pc{'colorBaseBgH'}, $pc{'colorBaseBgS'}, undef) = rgb_to_hsl($pc{'colorBaseBgR'},$pc{'colorBaseBgG'},$pc{'colorBaseBgB'});
    $pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} * $pc{'colorBaseBgA'} * 10;
  }
  if($ver < 1.10){
    $pc{'fairyContractEarth'} = 1 if $pc{'ftElemental'} =~ /土|地/;
    $pc{'fairyContractWater'} = 1 if $pc{'ftElemental'} =~ /水|氷/;
    $pc{'fairyContractFire' } = 1 if $pc{'ftElemental'} =~ /火|炎/;
    $pc{'fairyContractWind' } = 1 if $pc{'ftElemental'} =~ /風|空/;
    $pc{'fairyContractLight'} = 1 if $pc{'ftElemental'} =~ /光/;
    $pc{'fairyContractDark' } = 1 if $pc{'ftElemental'} =~ /闇/;
  }
  if($ver < 1.11001){
    $pc{'paletteUseBuff'} = 1;
  }
  if($ver < 1.11004){
    $pc{'armour1Name'} = $pc{'armourName'};
    $pc{'armour1Reqd'} = $pc{'armourReqd'};
    $pc{'armour1Eva'}  = $pc{'armourEva'};
    $pc{'armour1Def'}  = $pc{'armourDef'};
    $pc{'armour1Own'}  = $pc{'armourOwn'};
    $pc{'armour1Note'} = $pc{'armourNote'};
    $pc{'shield1Name'} = $pc{'shieldName'};
    $pc{'shield1Reqd'} = $pc{'shieldReqd'};
    $pc{'shield1Eva'}  = $pc{'shieldEva'};
    $pc{'shield1Def'}  = $pc{'shieldDef'};
    $pc{'shield1Own'}  = $pc{'shieldOwn'};
    $pc{'shield1Note'} = $pc{'shieldNote'};
    $pc{'defOther1Name'} = $pc{'defOtherName'};
    $pc{'defOther1Reqd'} = $pc{'defOtherReqd'};
    $pc{'defOther1Eva'}  = $pc{'defOtherEva'};
    $pc{'defOther1Def'}  = $pc{'defOtherDef'};
    $pc{'defOther1Note'} = $pc{'defOtherNote'};
    $pc{"defenseTotal1Eva"} = $pc{"defenseTotalAllEva"};
    $pc{"defenseTotal1Def"} = $pc{"defenseTotalAllDef"};
    $pc{"defTotal1CheckArmour1"} = $pc{"defTotal1CheckShield1"} = $pc{"defTotal1CheckDefOther1"} = $pc{"defTotal1CheckDefOther2"} = $pc{"defTotal1CheckDefOther3"} = 1;
  }
  if($ver < 1.12022){
    $pc{'updateMessage'}{'ver.1.12.022'} = '「言語」欄が、セージ技能とバード技能による習得数をカウントする仕様になりました。<br>　このシートのデータは、自動的に、新仕様に合わせて項目を振り分けていますが、念の為、言語欄のチェックを推奨します。';
    foreach my $n (1 .. $pc{'languageNum'}){
      if($pc{'race'} =~ /人間/ && $pc{"language${n}"} =~ /地方語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
        last;
      }
    }
    foreach my $n (1 .. $pc{'languageNum'}){
      if(($pc{'lvDem'} || $pc{'lvGri'}) && $pc{"language${n}"} =~ /魔法文明語/){
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
      if($pc{'lvDem'} && $pc{"language${n}"} =~ /魔神語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
      }
      if(($pc{'lvSor'} || $pc{'lvCon'}) && $pc{"language${n}"} =~ /魔法文明語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
      if(($pc{'lvMag'} || $pc{'lvAlc'}) && $pc{"language${n}"} =~ /魔動機文明語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
      if($pc{'lvFai'} && $pc{"language${n}"} =~ /妖精語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
    }
    my $bard = 0;
    foreach my $n (reverse 1 .. $pc{'languageNum'}){
      last if $bard >= $pc{'lvBar'};
      if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'Bar'; $bard++; }
    }
    my $sage = 0;
    foreach my $n (reverse 1 .. $pc{'languageNum'}){
      last if $sage >= $pc{'lvSag'};
      if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'Sag'; $sage++; }
      last if $sage >= $pc{'lvSag'};
      if($pc{"language${n}Read"} == 1){ $pc{"language${n}Read"} = 'Sag'; $sage++; }
    }
    foreach my $n (1 .. $pc{'languageNum'}){
      if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'auto'; }
      if($pc{"language${n}Read"} == 1){ $pc{"language${n}Read"} = 'auto'; }
    }
  }
  if($ver < 1.13002){
    ($pc{'characterName'},$pc{'characterNameRuby'}) = split(':', $pc{'characterName'});
    ($pc{'aka'},$pc{'akaRuby'}) = split(':', $pc{'aka'});
  }
  if($ver < 1.15003){
    foreach my $i (0 .. $pc{'historyNum'}){
      $pc{'historyExpTotal'} += s_eval($pc{"history${i}Exp"});
      $pc{'historyMoneyTotal'} += s_eval($pc{"history${i}Money"});
      
      if   ($pc{"history${i}HonorType"} eq 'barbaros'){ $pc{'historyHonorBarbarosTotal'} += s_eval($pc{"history${i}Honor"}); }
      elsif($pc{"history${i}HonorType"} eq 'dragon'  ){ $pc{'historyHonorDragonTotal'}   += s_eval($pc{"history${i}Honor"}); }
      else {
        $pc{'historyHonorTotal'} += s_eval($pc{"history${i}Honor"});
      }
    }
    $pc{'historyGrowTotal'} = $pc{'sttPreGrowA'}  + $pc{'sttPreGrowB'}  + $pc{'sttPreGrowC'}  + $pc{'sttPreGrowD'}  + $pc{'sttPreGrowE'}  + $pc{'sttPreGrowF'}
                            + $pc{'sttHistGrowA'} + $pc{'sttHistGrowB'} + $pc{'sttHistGrowC'} + $pc{'sttHistGrowD'} + $pc{'sttHistGrowE'} + $pc{'sttHistGrowF'};
  }
  if($ver < 1.15009){
    foreach my $i (1 .. $pc{'lvWar'}){
      $pc{'craftCommand'.$i} =~ s/濤/涛/g;
      $pc{'craftCommand'.$i} =~ s/^軍師の知略$/陣率：軍師の知略/g;
      $pc{'packWarAgi'} = $pc{'lvWar'} + $pc{'bonusAgi'};
      $pc{'packWarInt'} = $pc{'lvWar'} + $pc{'bonusInt'};
    }
    if($pc{'lvSor'} && $pc{'lvCon'}){
      $pc{'lvWiz'} = max($pc{'lvSor'},$pc{'lvCon'});
      $pc{'magicPowerWiz'} = max($pc{'magicPowerSor'},$pc{'magicPowerCon'});
      $pc{'magicPowerOwnWiz'} = ($pc{'magicPowerOwnSor'} && $pc{'magicPowerOwnCon'}) ? 1 : 0;
    }
    else { $pc{'lvWiz'} = 0; }
  }
  if($ver < 1.16013){
    $pc{'historyMoneyTotal'} = $pc{'hisotryMoneyTotal'};
  }
  if($ver < 1.17014){
    $pc{'updateMessage'}{'ver.1.17.014'} = 'ルールブックに合わせ、<br>「性別」「年齢」の並びを「年齢」「性別」の順に変更、<br>「作成レギュレーション」「セッション履歴」における項目の並びを<br>「経験点・名誉点・所持金（ガメル）」から、<br>「経験点・所持金（ガメル）・名誉点」に変更しました。<br>記入の際はご注意ください。';
  }
  if($ver < 1.20109){
    $pc{'packWarIntAdd'} -= 1 if $pc{'packWarIntAdd'} > 0;
    $pc{'packWarIntAuto'} = 1;
  }
  $pc{'ver'} = $main::ver;
  $pc{'lasttimever'} = $ver;
  return %pc;
}
sub data_update_arts {
  my %pc = %{$_[0]};
  my $ver = $pc{'ver'};
  delete $pc{'updateMessage'};

  if($ver < 1.20000){
    foreach my $num (1..$pc{'schoolArtsNum'}){
      $pc{"schoolArts${num}Type"} = $pc{"schoolArts${num}Base"};
    }
  }

  $pc{'ver'} = $main::ver;
  $pc{'lasttimever'} = $ver;
  return %pc;
}

1;