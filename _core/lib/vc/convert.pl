################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

require $set::data_class;
require $set::data_races;

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
    $data = escapeThanSign($data);
    my %pc = utf8::is_utf8($data) ? %{ decode_json(encode('utf8', (join '', $data))) } : %{ decode_json(join '', $data) };
    if($pc{result} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{convertSource} = '別のゆとシートⅡ';
      return %pc;
    }
    elsif($pc{result}) {
      error 'コンバート元のゆとシートⅡでエラーがありました<br>>'.$pc{result};
    }
    else {
      error '有効なデータが取得できませんでした';
    }
  }
}

1;