################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  
  %pc = data_update_chara(\%pc);

  ### 簡易プロフィール
  my @classes;
  foreach (@data::class_names){
    push(@classes, { "NAME" => $_, "LV" => $pc{'lv'.$data::class{$_}{id}} } );
  }
  @classes = sort{$b->{LV} <=> $a->{LV}} @classes;
  my $class_text;
  foreach my $data (@classes){
    $class_text .= ($class_text ? '／' : '') . $data->{NAME} . $data->{LV} if $data->{LV} > 0;
  }
  my $factor = "ファクター:$pc{factor}／$pc{factorCore}／$pc{factorStyle}";
  my $base    = "性別:$pc{gender}　年齢:$pc{age}".($pc{ageApp}?"（外見年齢：$pc{ageApp}）":"");
  my $missing = ($pc{factor} eq '吸血鬼' ? "欠落" : "喪失").":$pc{missing}";
  my $belong  = "所属:$pc{belong}";
  my $scar    = $pc{scarName} ? "傷号:$pc{scarName}" : '';
  
  $pc{sheetDescriptionS} = $factor."\n".$base."\n".$missing."　".$scar;
  $pc{sheetDescriptionM} = $factor."\n".$base."\n".$belong."\n".$missing.($scar?"\n$scar":'');
  
  ## ゆとチャユニット用ステータス
  $pc{unitStatus} = [
    { '耐久値' => $pc{endurance} },
    { '作戦力' => $pc{operation} },
    { '励起値' => 0 },
  ];

  return \%pc;
}

1;