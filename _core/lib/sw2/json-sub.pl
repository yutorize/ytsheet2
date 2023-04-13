################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

require $set::data_class;

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  ### 魔物 --------------------------------------------------
  if ($pc{'type'} eq 'm'){
    ## ゆとチャユニット用ステータス
    my $vitresist = "$pc{'vitResist'}\($pc{'vitResistFix'}\)";
    my $mndresist = "$pc{'mndResist'}\($pc{'mndResistFix'}\)";
    my @n2a = ('','A' .. 'Z');
    if($pc{'statusNum'} > 1){ # 2部位以上
      my @hp; my @mp; my @def;
      my %multiple;
      foreach my $i (1 .. $pc{'statusNum'}){
        ($pc{"part${i}"} = $pc{"status${i}Style"}) =~ s/^.+[(（)](.+?)[)）]$/$1/;
        $multiple{ $pc{"part${i}"} }++;
      }
      my %count;
      foreach my $i (1 .. $pc{'statusNum'}){
        my $partname = $pc{"part${i}"};
        if($pc{'mount'}){
          if($pc{'lv'}){
            my $ii = ($pc{'lv'} - $pc{'lvMin'} +1);
            $i .= $ii > 1 ? "-$ii" : '';
          }
        }
        if($multiple{ $pc{"part${i}"} } > 1){
          $count{ $pc{"part${i}"} }++;
          $pc{"part${i}"} .= $n2a[ $count{ $pc{"part${i}"} } ];
        }
        push(@hp , {$partname.':HP' => $pc{"status${i}Hp"}.'/'.$pc{"status${i}Hp"}});
        push(@mp , {$partname.':MP' => $pc{"status${i}Mp"}.'/'.$pc{"status${i}Mp"}});
        push(@def, $partname.$pc{"status${i}Defense"});
        $vitresist = $pc{"status${i}Vit"};
        $mndresist = $pc{"status${i}Mnd"};
      }
      $pc{'unitStatus'} = [ @hp,'|', @mp,'|', {'メモ' => '防護:'.join('／',@def)}];
      $pc{'unitExceptStatus'} = { 'HP'=>1,'MP'=>1,'防護'=>1 }
    }
    else { # 1部位
      my $i = 1;
      if($pc{'mount'}){
        if($pc{'lv'}){
          my $ii = ($pc{'lv'} - $pc{'lvMin'} +1);
          $i .= $ii > 1 ? "-$ii" : '';
        }
      }
      $pc{'unitStatus'} = [
        { 'HP' => $pc{"status${i}Hp"}.'/'.$pc{"status${i}Hp"} },
        { 'MP' => $pc{"status${i}Mp"}.'/'.$pc{"status${i}Mp"} },
        { '防護' => $pc{"status${i}Defense"} },
      ];
      $vitresist = $pc{"status${i}Vit"};
      $mndresist = $pc{"status${i}Mnd"};
    }
    my $taxa = "分類:$pc{'taxa'}";
    my $data1 = "知能:$pc{'intellect'}　知覚:$pc{'perception'}".($pc{'mount'}?'':"　反応:$pc{'disposition'}");
       $data1 .= "　穢れ:$pc{'sin'}" if $pc{'sin'};
    my $data2  = "言語:$pc{'language'}".($pc{'mount'}?'':"　生息地:$pc{'habitat'}");
    my $data3  = "弱点:$pc{'weakness'}\n".($pc{'mount'}?'':"先制値:$pc{'initiative'}　")."生命抵抗力:${vitresist}　精神抵抗力:${mndresist}";
    $pc{'sheetDescriptionS'} = $taxa."\n".$data3;
    $pc{'sheetDescriptionM'} = $taxa."　".$data1."\n".$data2."\n".$data3;
  }
  ### キャラクター --------------------------------------------------
  else {
    %pc = data_update_chara(\%pc);
    ## 簡易プロフィール
    my @classes;
    foreach (@data::class_names){
      push(@classes, { "NAME" => $_, "LV" => $pc{'lv'.$data::class{$_}{'id'}} } );
    }
    @classes = sort{$b->{'LV'} <=> $a->{'LV'}} @classes;
    my $class_text;
    foreach my $data (@classes){
      $class_text .= ($class_text ? '／' : '') . $data->{'NAME'} . $data->{'LV'} if $data->{'LV'} > 0;
    }
    my $base = "種族:$pc{'race'}　性別:$pc{'gender'}　年齢:$pc{'age'}";
    my $sub  = "ランク:".($pc{'rank'}||'－')."　信仰:".($pc{'faith'}||'－')."　穢れ:".($pc{'sin'}||0);
    my $classes = "技能:${class_text}";
    my $status  = "能力値:器用$pc{'sttDex'}".($pc{'sttAddA'}?"+$pc{'sttAddA'}":'')."\[$pc{'bonusDex'}\]"
                .      "／敏捷$pc{'sttAgi'}".($pc{'sttAddB'}?"+$pc{'sttAddB'}":'')."\[$pc{'bonusAgi'}\]"
                .      "／筋力$pc{'sttStr'}".($pc{'sttAddC'}?"+$pc{'sttAddC'}":'')."\[$pc{'bonusStr'}\]"
                .      "／生命$pc{'sttVit'}".($pc{'sttAddD'}?"+$pc{'sttAddD'}":'')."\[$pc{'bonusVit'}\]"
                .      "／知力$pc{'sttInt'}".($pc{'sttAddE'}?"+$pc{'sttAddE'}":'')."\[$pc{'bonusInt'}\]"
                .      "／精神$pc{'sttMnd'}".($pc{'sttAddF'}?"+$pc{'sttAddF'}":'')."\[$pc{'bonusMnd'}\]";
    $pc{'sheetDescriptionS'} = $base."\n".$classes;
    $pc{'sheetDescriptionM'} = $base."\n".$sub."\n".$classes."\n".$status;
    ## 防護点
    if($pc{'defenseTotalAllDef'} eq ''){
      $pc{'defenseTotalAllDef'} = $pc{'defenseTotal1Def'} ne '' ? $pc{'defenseTotal1Def'}
                                : $pc{'defenseTotal2Def'} ne '' ? $pc{'defenseTotal2Def'}
                                : $pc{'defenseTotal3Def'} ne '' ? $pc{'defenseTotal3Def'}
                                : 0;
    }
    ## ゆとチャユニット用ステータス
    $pc{'unitStatus'} = [
      { 'HP' => $pc{'hpTotal'}.'/'.$pc{'hpTotal'} },
      { 'MP' => $pc{'mpTotal'}.'/'.$pc{'mpTotal'} },
      { '防護' => $pc{'defenseTotalAllDef'} },
    ];
  }
  
  return \%pc;
}

1;