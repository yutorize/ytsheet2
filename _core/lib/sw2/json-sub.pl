################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

require $set::data_class;

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  if   ($type eq 'm'){  }
  elsif($type eq 'i'){  }
  elsif($type eq 'a'){  }
  else {
    %pc = data_update_chara(\%pc);
    # 簡易プロフィール
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
  }
  # 防護点
  if($pc{'defenseTotalAllDef'} eq ''){
    $pc{'defenseTotalAllDef'} = $pc{'defenseTotal1Def'} ne '' ? $pc{'defenseTotal1Def'}
                              : $pc{'defenseTotal2Def'} ne '' ? $pc{'defenseTotal2Def'}
                              : $pc{'defenseTotal3Def'} ne '' ? $pc{'defenseTotal3Def'}
                              : 0;
  }
  return \%pc;
}

1;