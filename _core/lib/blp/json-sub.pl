################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  
  %pc = data_update_chara(\%pc);
  
  ### ロイス数 --------------------------------------------------
  my @dloises; $pc{'loisHave'} = 0; $pc{'loisMax'} = 0; $pc{'titusHave'} = 0; $pc{'sublimated'} = 0;
  foreach my $num (1..7){
    if($pc{"lois${num}Relation"} =~ /[DＤ]ロイス|^[DＤ]$/){
      $pc{"lois${num}Name"} =~ s#/#／#g;
      push(@dloises, $pc{"lois${num}Name"});
    }
    else {
      if($pc{"lois${num}State"} =~ /タイタス/){
        $pc{'titusHave'}++;
      }
      elsif($pc{"lois${num}State"} =~ /昇華/){
        $pc{'sublimated'}++;
      }
      else{
        $pc{'loisMax'}++;
        $pc{'loisHave'}++ if($pc{"lois${num}Name"});
      }
    }
  }
  ### 簡易プロフィール --------------------------------------------------
  my @classes;
  foreach (@data::class_names){
    push(@classes, { "NAME" => $_, "LV" => $pc{'lv'.$data::class{$_}{'id'}} } );
  }
  @classes = sort{$b->{'LV'} <=> $a->{'LV'}} @classes;
  my $class_text;
  foreach my $data (@classes){
    $class_text .= ($class_text ? '／' : '') . $data->{'NAME'} . $data->{'LV'} if $data->{'LV'} > 0;
  }
  my $factor = "ファクター:$pc{'factor'}／$pc{'factorCore'}／$pc{'factorStyle'}";
  my $base    = "性別:$pc{'gender'}　年齢:$pc{'age'}".($pc{'ageApp'}?"（外見年齢：$pc{'ageApp'}）":"");
  my $missing = ($pc{'factor'} eq '吸血鬼' ? "欠落" : "喪失").":$pc{'missing'}";
  my $belong  = "所属:$pc{'belong'}";
  my $scar    = $pc{'scarName'} ? "傷号:$pc{'scarName'}" : '';
  
  $pc{'sheetDescriptionS'} = $factor."\n".$base."\n".$missing."　".$scar;
  $pc{'sheetDescriptionM'} = $factor."\n".$base."\n".$belong."\n".$missing.($scar?"\n$scar":'');
  
  return \%pc;
}

1;