################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

sub data_get {
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

sub data_convert {
  my $set_url = shift;
  my $file;
  
  ## キャラクターシート倉庫
  if($set_url =~ m"^https?://character-sheets\.appspot\.com/bloodpath/edit.html"){
    $set_url =~ s/edit\.html\?/display\?ajax=1&/;
    my $data = data_get($set_url) or error 'キャラクターシート倉庫のデータが取得できませんでした';
    my %in = %{ decode_json(encode('utf8', (join '', $data))) };
    
    return convertSoukoToYtsheet(\%in);
  }
  ## ゆとシートⅡ
  {
    my $data = data_get($set_url.'&mode=json') or error 'コンバート元のデータが取得できませんでした';
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

sub data_partner_get {
  my $set_url = shift;
  my $file;
  
  ## キャラクターシート倉庫
  if($set_url =~ m"^https?://character-sheets\.appspot\.com/bloodpath/edit.html"){
    $set_url =~ s/edit\.html\?/display\?ajax=1&/;
    my $data = data_get($set_url) or return;
    my %in = %{ decode_json(encode('utf8', (join '', $data))) };
    
    return convertSoukoToYtsheet(\%in);
  }
  ## ゆとシートⅡ
  {
    my $data = data_get($set_url.'&mode=json') or return;
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

### キャラクターシート倉庫 --------------------------------------------------
sub convertSoukoToYtsheet {
  my %in = %{$_[0]};
  ## 単純変換
  my %pc = (
    'convertSource' => 'キャラクターシート倉庫',
    
    'playerName' => $in{'base'}{'player'},
    
    'characterName' => $in{'base'}{'name'},
    'characterNameRuby' => $in{'base'}{'nameKana'},
    
    'factor' => $in{'base'}{'factor'},
    'belong' => $in{'base'}{'belongs'},    
    'past' => $in{'base'}{'past'},
    'background' => $in{'base'}{'background'},
    'missing' => $in{'base'}{'missing'} || $in{'base'}{'loss'},
    'appearance' => $in{'base'}{'appearance'},
    'dwelling' => $in{'base'}{'dwelling'},   
    'weapon' => $in{'base'}{'weapon'},
    
    'partner1Auto' => 1,
    'partner2Auto' => 1,
    
    'freeNote' => $in{'base'}{'memo'},
  );
  
  my $prof_rep = '^(.{1,6}(?:[(（].+?[）)])?)(?:[\/／:：。]|\s)(.*?)$|^(.{1,6})[(（](.{5,})[）)]$';
  if($pc{'belong'}     =~ s/$prof_rep//){ $pc{'belong'}     = $1 || $3; $pc{'belongNote'}     = $2 || $4; }
  if($pc{'past'}       =~ s/$prof_rep//){ $pc{'past'}       = $1 || $3; $pc{'pastNote'}       = $2 || $4; }
  if($pc{'background'} =~ s/$prof_rep//){ $pc{'background'} = $1 || $3; $pc{'backgroundNote'} = $2 || $4; }
  if($pc{'missing'}    =~ s/$prof_rep//){ $pc{'missing'}    = $1 || $3; $pc{'missingNote'}    = $2 || $4; }
  if($pc{'appearance'} =~ s/$prof_rep//){ $pc{'appearance'} = $1 || $3; $pc{'appearanceNote'} = $2 || $4; }
  if($pc{'dwelling'}   =~ s/$prof_rep//){ $pc{'dwelling'}   = $1 || $3; $pc{'dwellingNote'}   = $2 || $4; }
  if($pc{'weapon'}     =~ s/$prof_rep//){ $pc{'weapon'}     = $1 || $3; $pc{'weaponNote'}     = $2 || $4; }
  
  
  if($pc{'factor'} eq '人間'){
    $pc{'age'}    = $in{'base'}{'human'}{'age'}{'real'};
    $pc{'gender'} = $in{'base'}{'human'}{'sex'},
    $pc{'levelPreGrow'} = $in{'factor'}{'human'}{'level'};
    $pc{'factorCore'}   = $in{'factor'}{'human'}{'faith'};
    $pc{'factorStyle'}  = $in{'factor'}{'human'}{'job'};
    $pc{'statusMain1'}  = $in{'factor'}{'human'}{'spade'};
    $pc{'statusMain2'}  = $in{'factor'}{'human'}{'clover'};
    $pc{'enduranceAdd'}  = $in{'factor'}{'human'}{'endurance'}  - ($pc{'statusMain1'}*2+$pc{'statusMain2'});
    $pc{'initiativeAdd'} = $in{'factor'}{'human'}{'initiative'} - ($pc{'statusMain2'}  +10);
  }
  elsif($pc{'factor'} eq '吸血鬼'){
    $pc{'age'}    = $in{'base'}{'vampire'}{'age'}{'real'};
    $pc{'ageApp'} = $in{'base'}{'vampire'}{'age'}{'appearance'};
    $pc{'gender'} = $in{'base'}{'vampire'}{'sex'},
    $pc{'levelPreGrow'} = $in{'factor'}{'vampire'}{'level'};
    $pc{'factorCore'}   = $in{'factor'}{'vampire'}{'origin'};
    $pc{'factorStyle'}  = $in{'factor'}{'vampire'}{'style'};
    $pc{'statusMain1'}  = $in{'factor'}{'vampire'}{'heart'};
    $pc{'statusMain2'}  = $in{'factor'}{'vampire'}{'diamond'};
    $pc{'enduranceAdd'}  = $in{'factor'}{'vampire'}{'endurance'}  - ($pc{'statusMain1'}+20);
    $pc{'initiativeAdd'} = $in{'factor'}{'vampire'}{'initiative'} - ($pc{'statusMain2'}+ 4);
  }
  $pc{'endurancePreGrow'} = 0;
  while ($pc{'enduranceAdd'} - 5 >= 0) {
    $pc{'endurancePreGrow'} += 5;
    $pc{'enduranceAdd'}     -= 5;
  }
  $pc{'initiativePreGrow'} = 0;
  while ($pc{'initiativeAdd'} - 2 >= 0) {
    $pc{'initiativePreGrow'} += 2;
    $pc{'initiativeAdd'}     -= 2;
  }
  
  $pc{'partner1Url'}     = $in{'partner1'}{'url'};
  $pc{'partner1Name'}    = $in{'partner1'}{'name'},
  $pc{'partner1Factor'}  = $in{'partner1'}{'factordetail'},
  $pc{'partner1Age'}  = $in{'partner1'}{'age'},
  $pc{'partner1Missing'} = $in{'partner1'}{'missingloss'},
  $pc{'fromPartner1SealPosition'} = $in{'partner1'}{'mark'}{'position'};
  $pc{'fromPartner1SealShape'}    = $in{'partner1'}{'mark'}{'shape'};
  $pc{'fromPartner1Emotion1'}     = $in{'partner1'}{'mark'}{'emotion1'};
  $pc{'fromPartner1Emotion2'}     = $in{'partner1'}{'mark'}{'emotion2'};
  $pc{'partner1Promise'} = $in{'partner1'}{'promise'};
  
  ## 血威
  my $i = 1;
  foreach (@{$in{'bloodskills'}}){
    @$_{'name'}      =~ s/\n/ /;
    @$_{'timing'}    =~ s/\n//;
    @$_{'target'}    =~ s/\n//;
    @$_{'explain'}   =~ s/\n/ /;
    $pc{"bloodarts${i}Name"}     = @$_{'name'};
    $pc{"bloodarts${i}Timing"}   = @$_{'timing'};
    $pc{"bloodarts${i}Target"}   = @$_{'target'};
    $pc{"bloodarts${i}Note"}     = @$_{'explain'};
    $i++;
  }
  ## 特技
  my $i = 1;
  foreach (@{$in{'skills'}}){
    @$_{'name'}      =~ s/\n/ /;
    @$_{'timing'}    =~ s/\n//;
    @$_{'target'}    =~ s/\n//;
    @$_{'cost'}      =~ s/\n//;
    @$_{'condition'} =~ s/\n//;
    @$_{'explain'}   =~ s/\n/ /;
    $pc{"arts${i}Name"}     = @$_{'name'};
    $pc{"arts${i}Timing"}   = @$_{'timing'};
    $pc{"arts${i}Target"}   = @$_{'target'};
    $pc{"arts${i}Cost"}     = @$_{'cost'};
    $pc{"arts${i}Limited"}  = @$_{'condition'};
    $pc{"arts${i}Note"}     = @$_{'explain'};
    $i++;
  }
  $pc{'artsNum'} = $i-1;
  ## 履歴
  $pc{'historyNum'} = 3;
  ## 〆
  $pc{'ver'} = 0;
  return %pc;
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