################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  
  %pc = data_update_chara(\%pc);
  
  ### 簡易プロフィール --------------------------------------------------
  my $base  = "種族:$pc{'race'}クラス:$pc{'class'}\nスタイル:$pc{'style1'}／$pc{'style2'}";
  my $class = "バイタリティ:$pc{'vitality'}　テクニック:$pc{'technic'}　クレバー:$pc{'clever'}　カリスマ:$pc{'carisma'}";
  
  $pc{'sheetDescriptionS'} = $base."\n".$class."\n";
  $pc{'sheetDescriptionM'} = $base."\n".$class."\n";
  
  ## ゆとチャユニット用ステータス
  $pc{'unitStatus'} = [
    { 'HP' => $pc{'hpMax'}.'/'.$pc{'hpMax'} },
    { 'スタミナ' => $pc{'staminaMax'}.'/'.$pc{'staminaMax'} },
    { '回避値' => $pc{'battleTotalEva'} },
    { '物防値' => $pc{'battleTotalDef'} },
    { '魔防値' => $pc{'battleTotalMdf'} },
  ];
  
  return \%pc;
}

1;