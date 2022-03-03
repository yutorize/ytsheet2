################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

sub urlDataGet {
  my $url = shift;
  my $ua  = LWP::UserAgent->new;
  my $res = $ua->get($url);
  if ($res->is_success) {
    return $res->decoded_content;
  }
  else {
    return undef;
  }
}

sub dataConvert {
  my $set_url = shift;
  my $file;

  ## ゆとシートⅡ
  {
    my $data = urlDataGet($set_url.'&mode=json') or error 'コンバート元のデータが取得できませんでした';
    if($data !~ /^{/){ error 'JSONデータが取得できませんでした' }
    my %pc = %{ decode_json(join '', $data) };
    if($pc{'result'} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{'convertSource'} = '別のゆとシートⅡ';
      return %pc;
    }
    elsif($pc{'result'}) {
      error 'コンバート元のゆとシートⅡでエラーがありました<br>'.$pc{'result'};
    }
    else {
      error '有効なデータが取得できませんでした';
    }
  }
}

sub dataPartnerGet {
  my $set_url = shift;
  my $file;

  ## 同じゆとシートⅡ
  my $self = CGI->new()->url;
  if($set_url =~ m"^$self\?id=(.+?)(?:$|&)"){
    my $id = $1;
    my ($file, $type, $author) = getfile_open($id);
    my %pc;
    open my $IN, '<', "${set::char_dir}${file}/data.cgi";
    while (<$IN>){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    close($IN);
    if($pc{'image'}){
      $pc{'imageURL'} = url()."${set::char_dir}${file}/image.$pc{'image'}";
    }
    $pc{'convertSource'} = '同じゆとシートⅡ';
    return %pc;
  }
  ## 他のゆとシートⅡ
  {
    my $data = urlDataGet($set_url.'&mode=json') or return;
    if($data !~ /^{/){ return }
    my %pc = %{ decode_json(join '', $data) };
    if($pc{'result'} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{'convertSource'} = '別のゆとシートⅡ';
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