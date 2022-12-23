################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];
  
  %pc = data_update_chara(\%pc);
  
  ## ロイス数
  my @dloises; $pc{loisHave} = 0; $pc{loisMax} = 0; $pc{titusHave} = 0; $pc{sublimated} = 0;
  foreach my $num (1..7){
    if($pc{"lois${num}Relation"} =~ /[DＤEＥ]ロイス|^[DＤEＥ]$/){
      $pc{"lois${num}Name"} =~ s#/#／#g;
      push(@dloises, $pc{"lois${num}Name"});
    }
    else {
      if($pc{"lois${num}State"} =~ /タイタス/){
        $pc{titusHave}++;
      }
      elsif($pc{"lois${num}State"} =~ /昇華/){
        $pc{sublimated}++;
      }
      else{
        $pc{loisMax}++;
        $pc{loisHave}++ if($pc{"lois${num}Name"});
      }
    }
  }
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
  my $base = "性別:$pc{gender}　年齢:$pc{age}";
  my $sub  = "身長:$pc{height}　体重:$pc{weight}";
  my $works = "ワークス:$pc{works}　カヴァー:$pc{cover}";
  my $syndrome = "シンドローム:$pc{syndrome1}"
               . ($pc{syndrome2}?"／$pc{syndrome2}":'')
               . ($pc{syndrome3}?"／$pc{syndrome3}":'');
  my $dlois = (@dloises ? 'Dロイス:'.join('／', @dloises) : '');
  
  $pc{sheetDescriptionS} = $base."\n".$works."\n".$syndrome;
  $pc{sheetDescriptionM} = $base."　".$sub."\n".$works."\n".$syndrome.($dlois?"\n$dlois":'');
  
  ## ゆとチャユニット用ステータス
  $pc{unitStatus} = [
    { 'HP' => $pc{maxHpTotal}.'/'.$pc{maxHpTotal} },
    { '侵蝕' => $pc{baseEncroach} },
    { 'ロイス' => $pc{loisHave}.'/'.$pc{loisMax} },
    { '財産' => $pc{savingTotal} },
    { '行動' => $pc{initiativeTotal} },
  ];
  
  return \%pc;
}

1;