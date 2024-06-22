################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  
  %pc = data_update_chara(\%pc) if $pc{ver};
  
  ### 簡易プロフィール --------------------------------------------------
  my $base  = "種族:$pc{race}クラス:$pc{class}\nスタイル:$pc{style1}／$pc{style2}";
  my $class = "バイタリティ:$pc{vitality}　テクニック:$pc{technic}　クレバー:$pc{clever}　カリスマ:$pc{carisma}";
  
  $pc{sheetDescriptionS} = $base."\n".$class."\n";
  $pc{sheetDescriptionM} = $base."\n".$class."\n";
  
  ## ユニット（コマ）用ステータス
  $pc{unitStatus} = createUnitStatus(\%pc);
  
  return \%pc;
}

1;