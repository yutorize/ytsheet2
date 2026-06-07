################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;

sub loadPartnerData {
  my $set_url = shift;
  my $file;

  ## 同じゆとシートⅡ
  my $self = CGI->new()->url;
  if($set_url =~ m"^$self\?id=(.+?)(?:$|&)"){
    my %pc;

    my $id = $1;
    my ($file, $type, $author) = findSheet($id);
    unless($file) { $pc{error} = "存在しないシート"; return %pc; }

    my @lines = readSheetFileLines($set::char_dir, $file, 'data.cgi');
    unless(@lines){ $pc{error} = "開けないデータ"; return %pc; }
    foreach (@lines){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    if($pc{image}){
      $pc{imageURL} = "./?id=$id&mode=image&cache=$pc{imageUpdate}";
      my $imagePath = "${set::char_dir}${file}/image.$pc{image}";
      $pc{imagePath} = $imagePath if -f $imagePath;
      $pc{imageData} = readSheetFileBinary($set::char_dir, $file, "image.$pc{image}");
    }
    $pc{convertSource} = '同じゆとシートⅡ';
    return %pc;
  }
  ## 他のゆとシートⅡ
  {
    my %pc = fetchJson($set_url.'&mode=json');
    $_ = escapeThanSign($_) foreach values %pc;
    if($pc{result} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{convertSource} = '別のゆとシートⅡ';
      return %pc;
    }
    else {
      return;
    }
  }
}

## タグ：全角スペース・英数を半角に変換 --------------------------------------------------
sub convertTags {
  my $tags = shift;
  $tags =~ tr/　/ /;
  $tags =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  $tags =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
  $tags =~ tr/ / /s;
  return $tags
}

1;
