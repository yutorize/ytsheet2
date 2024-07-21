################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  if ($pc{type} eq 'c'){
  }
  else {
    %pc = data_update_chara(\%pc) if $pc{ver};

    ### 簡易プロフィール --------------------------------------------------
    my $base  = "レベル:$pc{level}　クラス:$pc{class}　スタイル:$pc{style}\n";
    $base .= "ワークス:$pc{works}";
    if($pc{styleSub}){ $base .= "　サブスタイル:$pc{styleSub}" }
    my $profile = "所属国:$pc{country}\n性別:$pc{gender}　年齢:$pc{age}　身長:$pc{height}　体重:$pc{weight}";

    my $status;
    foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
      $status .= " " if $status;
      $status .= $set::sttE2J{$stt}.$pc{"stt${stt}Total"}."(".$pc{"stt${stt}CheckTotal"}.")";
      my $i = 1;
      foreach my $label (@{$set::skill{$stt}}){
        $pc{"skill${stt}${i}Label"} = $label.$::pc{"skill${stt}${i}LabelBranch"};
        $i++;
      }
      $pc{"skill${stt}Num"} = $i - 1;
    }
    
    $pc{sheetDescriptionS} = $base."\n".$profile."\n";
    $pc{sheetDescriptionM} = $base."\n".$profile."\n能力値(判定値):".$status."\n";
    
    ## ユニット（コマ）用ステータス
    $pc{unitStatus} = createUnitStatus(\%pc);
  }
  
  return \%pc;
}

1;