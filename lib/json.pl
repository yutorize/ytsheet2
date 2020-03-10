################## 外部アプリ連携 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
#use JSON;


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
} else {
  if($backup eq "") {
    $pc{result} = "リクエストされたシートは見つかりませんでした。 id: ${id}";
  } else {
    $pc{result} = "リクエストされたシートは見つかりませんでした。 id: ${id}, backup: ${backup}";
  }
}

### 出力 #############################################################################################

if($callback eq "") {
  print "Content-type: application/json\n\n";
  print to_json( \%pc );
} else {
  print "Content-type: text/javascript\n\n";
  print $callback;
  print "(";
  print to_json( \%pc );
  print ")";
}

sub to_json {
  my $hash = shift;
  my $output;
  foreach my $keys (keys %{$hash}) {
    $$hash{$keys} =~ s/\\/\\\\/g;
    $$hash{$keys} =~ s/"/\"/g;
    $output .= '"'.${keys}.'":"'.$$hash{$keys}.'",';
  }
  $output =~ s/,$//; # 末尾のカンマを消す
  return "\{$output\}";
}

1;
