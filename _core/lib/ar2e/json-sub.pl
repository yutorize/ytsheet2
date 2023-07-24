################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  
  %pc = data_update_chara(\%pc);
  
  ## 誓約
  my @geises;
  foreach my $num (1..$pc{geisesNum}){
    if($pc{"geis${num}Name"}){
      push(@geises, $pc{"geis${num}Name"});
    }
  }
  ## 簡易プロフィール
  my $base  = "性別:$pc{gender}　年齢:$pc{age}\n種族:$pc{race}";
  my $class = "メインクラス:$pc{classMain}　サポートクラス:$pc{classSupport}\n　称号クラス:$pc{classTitle}";
  my $geis  = (@geises ? '誓約:'.join('／', @geises) : '');
  
  $pc{sheetDescriptionS} = $base."\n".$class."\n";
  $pc{sheetDescriptionM} = $base."\n".$class."\n".($geis?"\n$geis":'');
  
  ## ゆとチャユニット用ステータス
  $pc{unitStatus} = [
    { 'HP' => $pc{hpTotal}.'/'.$pc{hpTotal} },
    { 'MP' => $pc{mpTotal}.'/'.$pc{mpTotal} },
    { 'フェイト' => $pc{fateTotal}.'/'.$pc{fateTotal} },
  ];
  
  return \%pc;
}

1;