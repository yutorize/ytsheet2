################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

require $set::data_class;

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  my $target = $_[2];
  $pc{'gameVersion'} = $::SW2_0 ? '2.0' : '2.5';
  ### 魔物 --------------------------------------------------
  if ($pc{type} eq 'm'){
    my @n2a = ('','A' .. 'Z');

    my $vitresist = "$pc{vitResist}\($pc{vitResistFix}\)";
    my $mndresist = "$pc{mndResist}\($pc{mndResistFix}\)";
    if($pc{statusNum} > 1){ # 2部位以上
      foreach my $i (1 .. $pc{statusNum}){
        if($pc{mount}){
          if($pc{lv}){
            my $ii = ($pc{lv} - $pc{lvMin} +1);
            $i .= $ii > 1 ? "-$ii" : '';
          }
        }
        if (!$pc{mount} || $pc{"status${i}Vit"} =~ /\d/) {
          $vitresist = $pc{mount} ? $pc{"status${i}Vit"} : $pc{vitResist} . ' (' . $pc{vitResistFix} . ')';
          $mndresist = $pc{mount} ? $pc{"status${i}Mnd"} : $pc{mndResist} . ' (' . $pc{mndResistFix} . ')';
        }
      }
    }
    else { # 1部位
      my $i = 1;
      if($pc{mount}){
        if($pc{lv}){
          my $ii = ($pc{lv} - $pc{lvMin} +1);
          $i .= $ii > 1 ? "-$ii" : '';
        }
      }
      $vitresist = $pc{mount} ? $pc{"status${i}Vit"} : $pc{vitResist} . ' (' . $pc{vitResistFix} . ')';
      $mndresist = $pc{mount} ? $pc{"status${i}Mnd"} : $pc{mndResist} . ' (' . $pc{mndResistFix} . ')';
    }

    my $taxa = "分類:$pc{taxa}";
    my $data1 = "知能:$pc{intellect}　知覚:$pc{perception}".($pc{mount}?'':"　反応:$pc{disposition}");
       $data1 .= "　穢れ:$pc{sin}" if $pc{sin};
    my $data2  = "言語:$pc{language}".($pc{mount}?'':"　生息地:$pc{habitat}");
    my $data3  = ($pc{mount}?'':"先制値:$pc{initiative}　")."生命抵抗力:${vitresist}　精神抵抗力:${mndresist}";
    $pc{sheetDescriptionS} = $taxa."\n".$data3;
    $pc{sheetDescriptionM} = $taxa."　".$data1."\n".$data2."\n".$data3;
    
    if($pc{statusNum} > 1){ $pc{unitExceptStatus} = { 'HP'=>1,'MP'=>1,'防護'=>1 } }
  }
  ### キャラクター --------------------------------------------------
  else {
    %pc = data_update_chara(\%pc) if $pc{ver};
    ## 簡易プロフィール
    my @classes;
    foreach (@data::class_names){
      push(@classes, { "NAME" => $_, "LV" => $pc{'lv'.$data::class{$_}{id}} } );
    }
    @classes = sort{$b->{LV} <=> $a->{LV}} @classes;
    my $class_text;
    foreach my $data (@classes){
      $class_text .= ($class_text ? '／' : '') . $data->{NAME} . $data->{LV} if $data->{LV} > 0;
    }
    my $rank = $pc{rank};
    $rank .= $pc{rankStar} if $pc{rank} eq '〈始まりの剣〉★' && $pc{rankStar} > 1;
    my $rankBarbaros = $pc{rankBarbaros};
    $rankBarbaros .= $pc{rankStarBarbaros} if $pc{rankBarbaros} eq '〈イグニス〉★' && $pc{rankStarBarbaros} > 1;
    my @ranks = ();
    push(@ranks, $rank) if $rank;
    push(@ranks, $rankBarbaros) if $rankBarbaros;
    push(@ranks, '－') unless @ranks;
    my $base = "種族:$pc{race}　性別:$pc{gender}　年齢:$pc{age}";
    my $sub  = "ランク:".join('／', @ranks)."　信仰:".($pc{faith}||'－')."　穢れ:".($pc{sin}||0);
    my $classes = "技能:${class_text}";
    foreach ('A' .. 'F') {
      $pc{"sttAddTotal${_}"} += $pc{"sttEquip${_}"};
    }
    my $status  = "能力値:器用$pc{sttDex}".($pc{sttAddTotalA}?"+$pc{sttAddTotalA}":'')."\[$pc{bonusDex}\]"
                .      "／敏捷$pc{sttAgi}".($pc{sttAddTotalB}?"+$pc{sttAddTotalB}":'')."\[$pc{bonusAgi}\]"
                .      "／筋力$pc{sttStr}".($pc{sttAddTotalC}?"+$pc{sttAddTotalC}":'')."\[$pc{bonusStr}\]"
                .      "／生命$pc{sttVit}".($pc{sttAddTotalD}?"+$pc{sttAddTotalD}":'')."\[$pc{bonusVit}\]"
                .      "／知力$pc{sttInt}".($pc{sttAddTotalE}?"+$pc{sttAddTotalE}":'')."\[$pc{bonusInt}\]"
                .      "／精神$pc{sttMnd}".($pc{sttAddTotalF}?"+$pc{sttAddTotalF}":'')."\[$pc{bonusMnd}\]";
    $pc{sheetDescriptionS} = $base."\n".$classes;
    $pc{sheetDescriptionM} = $base."\n".$sub."\n".$classes."\n".$status;
  }

  ## ユニット（コマ）用ステータス --------------------------------------------------
  if ($pc{type} eq 'm' && $target eq 'ccfolia') {
    $pc{unitStatus} = createUnitStatus(\%pc, $target);
    #$pc{sheetDescriptionM} .= "\n".$pc{unitStatus}->{'メモ'} if $pc{unitStatus}->{'メモ'};
    my @memo = grep { exists $_->{'メモ'} } @{$pc{unitStatus}};
    $pc{sheetDescriptionM} .= "\n$memo[0]->{'メモ'}" if @memo && @memo[0]->{'メモ'};
    my @array = grep { !exists $_->{'メモ'} } @{$pc{unitStatus}};
    $pc{unitStatus} = \@array;
  }
  else {
    $pc{unitStatus} = createUnitStatus(\%pc, $target);
  }
  
  return \%pc;
}

1;