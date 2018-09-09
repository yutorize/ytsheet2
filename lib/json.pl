################## 外部アプリ連携 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
#use JSON;

my $data_dir;
if(param('type') eq 'm'){ $data_dir = $set::mons_dir; }
if(param('type') eq 'i'){ $data_dir = $set::item_dir; }
else                    { $data_dir = $set::char_dir; }

### コールバック関数読み込み #########################################################################
my $callback = param('callback');

### バックアップ情報読み込み #########################################################################
my $backup = param('backup');

### キャラクターデータ読み込み #######################################################################
my $id = param('id');
my $file;

open (my $FH, '<', $set::listfile) or die;
while (<$FH>) {
  my @data = (split /<>/, $_)[0..1];
  if ($data[0] eq $id) {
    $file = $data[1];
    last;
  }
}
close($FH);

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
    $$hash{$keys} =~ s/"/\\"/g; # いらないかも。念の為。
    $output .= '"'.${keys}.'":"'.$$hash{$keys}.'",';
  }
  $output =~ s/,$//; # 末尾のカンマを消す
  return "\{$output\}";
}

1;
