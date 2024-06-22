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
    my $base = "分類名:$pc{taxa}　出身地:$pc{home}　根源:$pc{origin}　経緯:$pc{background}";
    my $clan = "クラン:$pc{clanName}　クランへの感情:$pc{clanEmotion}";
    my $address = "住所:$pc{address}";
    my $level = "強度:$pc{level}";
    my $physical = "【身体】$pc{statusPhysical} ";
    my $special  = "【異質】$pc{statusSpecial} ";
    my $social   = "【社会】$pc{statusSocial} ";
    foreach my $num (1..$pc{attributeRow}){
      $physical .= "《$pc{'attributePhysical'.$num}》" if $pc{'attributePhysical'.$num};
      $special  .= "《$pc{'attributeSpecial'.$num}》" if $pc{'attributeSpecial'.$num};
      $social   .= "《$pc{'attributeSocial'.$num}》" if $pc{'attributeSocial'.$num};
    }
    
    $pc{sheetDescriptionS} = $base."　".$address;
    $pc{sheetDescriptionM} = $base."　".$address."\n".$clan."\n".$level."\n".$physical."\n".$special."\n".$social;
    
    ## ユニット（コマ）用ステータス
    $pc{unitStatus} = createUnitStatus(\%pc);
  }

  return \%pc;
}

1;