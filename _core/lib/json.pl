################## 外部アプリ連携 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;


### コールバック関数読み込み #########################################################################
my $callback = $::in{callback};

### バックアップ情報読み込み #########################################################################
my $log = $::in{log};

### キャラクターデータ読み込み #######################################################################
my $id  = $::in{id};
my $url = $::in{url};

my ($file, $type, $author);
my %pc = ();
if($id){
  ($file, $type, $author) = findSheet($id);

  changeFileByType($type);
  my $dir = $set::char_dir;

  my $datatype = ($::in{log}) ? 'logs' : 'data';
  foreach (readSheetRecordLines $dir, $file, $datatype, $::in{log}){
    chomp $_;
    my ($key, $value) = split(/<>/, $_, 2);
    $pc{$key} = $value;
  }
  
  if($pc{forbidden}){
    my $LOGIN_ID = check;
    if($::in{log}){
      ($pc{protect}, $pc{forbidden}) = getProtectType("${dir}${file}/data.cgi");
    }
    unless(
      ($pc{protect} eq 'none') || 
      ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
    ){
      error("403:閲覧権限がありません。");
    }
  }
  
  my $imageMaxCount = $pc{imageMaxCount} = $set::image_maxcount || 1;
  foreach my $n (1 .. $imageMaxCount){
    my $suffix = imageSuffix($n);
    $pc{"imageURL$suffix"} = url().qq|?id=$id&mode=image&imageNo=$n&cache=$pc{"imageUpdate$suffix"}| if $pc{"image$suffix"};
  }
  if(!$pc{image} && $pc{mainImage} > 1){ # 複数画像未対応verへの対応
    my $suffix = imageSuffix($pc{mainImage});
    foreach my $key (qw/image imageUpdate imageURL imageFit imagePercent imagePositionX imagePositionY imageCopyright imageCopyrightURL words wordsX wordsY/){
      $pc{$key} = $pc{"$key$suffix"};
    }
  }

  $pc{sheetURL} = url()."?id=${id}";
}
elsif($::in{url}){
  eval { require $set::lib_convert; };
  %pc = importSheetData($::in{url});
  $type = $pc{type};
  if(!$pc{ver}){
    require $set::lib_calc_char;
    %pc = dataCalc(\%pc);
  }
  foreach(keys %pc){
    $pc{$_} = escapePcData($pc{$_});
    delete $pc{$_} if($pc{$_} eq '');
  }
}


if($pc{ver} ne '') {
  $pc{result} = "OK";
  if(defined &upgradeData){
    %pc = upgradeData(\%pc, $type);
  }
  elsif(defined &upgradeCharaData){
    %pc = upgradeCharaData(\%pc);
  }

  if($set::lib_json_sub){
    require $set::lib_json_sub;
    %pc = %{ addJsonData(\%pc , $type , $::in{target} || '') };
  }
  delete $pc{IP};
}
else {
  if($log eq "") {
    error "404:リクエストされたシートは見つかりませんでした。(id: ${id})";
  } else {
    error "404:リクエストされたシートは見つかりませんでした。(id: ${id}, log: ${log})";
  }
}

### 出力 #############################################################################################
my $json = JSON::PP->new->canonical(1)->encode( \%pc );
print "Access-Control-Allow-Origin: *\n";
if($callback eq "") {
  print "Content-type: application/json\n\n";
  print $json;
} else {
  print "Content-type: text/javascript\n\n";
  print $callback;
  print "(";
  print $json;
  print ")";
}

#sub to_json {
#  my $hash = shift;
#  my $output;
#  foreach my $keys (keys %{$hash}) {
#    $$hash{$keys} =~ s/\\/\\\\/g;
#    $$hash{$keys} =~ s/"/\"/g;
#    $output .= '"'.${keys}.'":"'.$$hash{$keys}.'",';
#  }
#  $output =~ s/,$//; # 末尾のカンマを消す
#  return "\{$output\}";
#}

1;
