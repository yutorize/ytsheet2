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

my ($file, $type,$author);
my %pc = ();
if($id){
  ($file, $type, $author) = getfile_open($id);

  changeFileByType($type);
  my $dir = $set::char_dir;

  my $datatype = ($::in{log}) ? 'logs' : 'data';
  my $hit = 0;
  open my $IN, '<', "${dir}${file}/${datatype}.cgi" or error('データがありません');
  while (<$IN>){
    if($datatype eq 'logs'){
      if (index($_, "=") == 0){
        if (index($_, "=$::in{log}=") == 0){ $hit = 1; next; }
        if ($hit){ last; }
      }
      if (!$hit) { next; }
    }
    chomp $_;
    my ($key, $value) = split(/<>/, $_, 2);
    $pc{$key} = $value;
  }
  close($IN);
  if($datatype eq 'logs' && !$hit){ error("過去ログ（$::in{log}）が見つかりません。"); }
  
  if($pc{forbidden}){
    my $LOGIN_ID = check;
    if($::in{log}){
      ($pc{protect}, $pc{forbidden}) = getProtectType("${dir}${file}/data.cgi");
    }
    unless(
      ($pc{protect} eq 'none') || 
      ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
    ){
      infoJson('error',"閲覧権限がありません。");
    }
  }
  
  if($pc{image}){
    $pc{imageURL} = url()."?id=$id&mode=image&cache=$pc{imageUpdate}";
  }

  $pc{sheetURL} = url()."?id=${id}";
}
elsif($::in{url}){
  require $set::lib_convert;
  %pc = dataConvert($::in{url});
  $type = $pc{type};
  if(!$pc{ver}){
    require $set::lib_calc_char;
    %pc = data_calc(\%pc);
  }
  foreach(keys %pc){
    $pc{$_} = pcEscape($pc{$_});
    delete $pc{$_} if($pc{$_} eq '');
  }
}


if($pc{ver} ne '') {
  $pc{result} = "OK";
  if($set::lib_json_sub){
    require $set::lib_json_sub;
    %pc = %{ addJsonData(\%pc , $type , $::in{target} || '') };
  }
  delete $pc{IP};
}
else {
  if($log eq "") {
    $pc{result} = "リクエストされたシートは見つかりませんでした。(id: ${id})";
  } else {
    $pc{result} = "リクエストされたシートは見つかりませんでした。(id: ${id}, log: ${log})";
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
