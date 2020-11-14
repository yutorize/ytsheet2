################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  
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
  my $base = "性別:$pc{'gender'}　年齢:$pc{'age'}";
  my $sub  = "身長:$pc{'height'}　体重:$pc{'weight'}";
  my $works = "ワークス:$pc{'works'}　カヴァー:$pc{'cover'}";
  my $syndrome = "シンドローム:$pc{'syndrome1'}"
               . ($pc{'syndrome2'}?"／$pc{'syndrome2'}":'')
               . ($pc{'syndrome3'}?"／$pc{'syndrome3'}":'');
  my $dlois = 'Dロイス:'.join('／', @dloises);
  
  $pc{'sheetDescriptionS'} = $base."\n".$works."\n".$syndrome;
  $pc{'sheetDescriptionM'} = $base."　".$sub."\n".$works."\n".$syndrome."\n".$dlois;
  
  return \%pc;
}

1;