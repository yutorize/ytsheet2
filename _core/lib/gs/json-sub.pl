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
  if ($pc{type} eq 'm'){

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
    my $base = "種族:$pc{race}　性別:$pc{gender}　年齢:$pc{age}";
    my $sub  = "ランク:".($pc{rank}||'－')."　信仰:".($pc{faith}||'－');
    my $classes = "職業:${class_text}";
    $pc{sheetDescriptionS} = $base."\n".$classes;
    $pc{sheetDescriptionM} = $base."\n".$sub."\n".$classes."\n";
  }
  
  ## ユニット（コマ）用ステータス
  $pc{unitStatus} = createUnitStatus(\%pc);
  
  return \%pc;
}

1;