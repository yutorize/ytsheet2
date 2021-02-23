################## 外部アプリ連携 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;


### コールバック関数読み込み #########################################################################
my $callback = param('callback');

### バックアップ情報読み込み #########################################################################
my $backup = param('backup');

### キャラクターデータ読み込み #######################################################################
my $id = param('id');
my ($file, $type) = getfile_open($id);

my $data_dir;
   if($type eq 'm'){ $data_dir = $set::mons_dir; }
elsif($type eq 'i'){ $data_dir = $set::item_dir; }
else               { $data_dir = $set::char_dir; }

my %pc = ();
my $IN;

if($backup eq "") {
  open $IN, '<', "${data_dir}${file}/data.cgi" or "";
} else {
  open $IN, '<', "${data_dir}${file}/backup/${backup}.cgi" or "";
}

$_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
close($IN);

if($pc{updateTime}) {
  $pc{result} = "OK";
  if($set::lib_json_sub){
    require $set::lib_json_sub;
    %pc = %{ addJsonData(\%pc , $type) };
  }
} else {
  if($backup eq "") {
    $pc{result} = "リクエストされたシートは見つかりませんでした。(id: ${id})";
  } else {
    $pc{result} = "リクエストされたシートは見つかりませんでした。(id: ${id}, backup: ${backup})";
  }
}
if($pc{'image'}){
  $pc{'imageURL'} = url()."${data_dir}${file}/image.$pc{'image'}";
}

### 出力 #############################################################################################
my $json = JSON::PP->new->canonical(1)->encode( \%pc );
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
