################## 外部アプリ連携 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use JSON;


### コールバック関数読み込み ##################################################
my $callback = param('callback');

### キャラクターデータ読み込み ##################################################
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
open my $IN, '<', "${set::data_dir}${file}/data.cgi" or error 'キャラクターシートがありません。';
$_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
close($IN);

### 置換
foreach (keys %pc) {
  $pc{$_} = tag_unescape($pc{$_});
  if($_ =~ /^(?:items|freeNote|freeHistory)$/){
  }
}

### 出力 #########################################################

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



#$pc{characterName};
#encode_json( $pc );
#decode( 'utf-8', encode_json( $tmp )); #decode( 'utf-8', $tmp );


### サブルーチン ##################################################
sub tag_unescape {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  
  $text =~ s/{{([0-9\+\-\*\/\%\(\) ]+?)}}/s_eval($1);/eg;
  
  $text =~ s|(―+)|&ddash($1);|eg;
  
  $text =~ s/[|｜](.+?)《(.*?)》/<ruby>$1<rp>(<\/rp><rt>$2<\/rt><rp>)<\/rp><\/ruby>/gi; # なろう式ルビ
  $text =~ s/&lt;br&gt;/<br>/gi;
  
  return $text;
}

1;
