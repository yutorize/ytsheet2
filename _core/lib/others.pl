################## その他の処理 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

my $mode = $::in{mode};

### バックアップ命名 #################################################################################
if($mode eq 'bu-naming'){
  my $id   = $::in{id};
  my $pass = $::in{pass};
  my $date = $::in{date} || 'latest';
  my $name = escapePcData( decode('utf8',$::in{'log-name'}) );

  ## パスワードチェック
  (my $file, my $type, my $user) = authSheet($id,$pass,$LOGIN_ID);
  if(!$file){ error('403:パスワードが間違っているか、編集権限がありません。'); }
  changeFileByType($type);

  ## ディレクトリ
  my $fileDir = $set::char_dir .($user ? "_${user}/${file}" : $file);

  ## 読込
  sysopen (my $FH, "${fileDir}/log-list.cgi", O_RDWR) or error('500:ログ一覧が開けません。'.$fileDir);
  flock($FH, 2);
  my @list = <$FH>;
  
  ## 保存
  seek($FH, 0, 0);
  foreach my $line (@list) {
    if(index($line, $date) == 0){
      chomp $line;
      my($_date, $_epoc, undef) = split(/<>/, $line);
      print $FH "${_date}<>${_epoc}<>${name}\n";
    }
    else { print $FH $line; }
  }
  truncate($FH, tell($FH));
  close($FH);

  ## キャラシートへ移動／編集画面に戻る
  if($date eq 'latest'){ print "Location: ./?id=${id}\n\n"; }
  else                 { print "Location: ./?id=${id}&log=${date}\n\n"; }
}
### 画像リダイレクト #################################################################################
elsif($mode eq 'image' || $mode eq 'ogp-image'){
  my $id = $::in{id};
  my ($file,$type,$user) = findSheet($id);
  changeFileByType($type);
  my $datadir = $set::char_dir;

  if(!$file){ error "404:データがありません。" }
  my %pc;
  open(my $DATA, '<', "./${datadir}/${file}/data.cgi") or error("500:データが開けませんでした。");
  while(<$DATA>){
    if($_ =~ /^(image.*?)<>(.*?)\n/){ $pc{$1} = $2; }
  }
  close($DATA);

  my $ext = $pc{image};
  
  my %mime = (
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    png  => 'image/png',
    gif  => 'image/gif',
    webp => 'image/webp',
  );

  my $path = "./${datadir}/${file}/image.${ext}";
  
  my $imageExists;
  if(-f $path){
    $imageExists = 1;
  }
  else {
    foreach (qw(png jpg jpeg gif webp)) {
      if(-f "./${datadir}/${file}/image.$_") {
        $path = "./${datadir}/${file}/image.$_";
        $ext = $_;
        $imageExists = 1;
        last;
      }
    }
  }
  unless($imageExists){ error "404:画像ファイルが存在しませんでした。" }
  
  my $mimeType = $mime{lc $ext};

  if($mode eq 'ogp-image'){
    $pc{src} = $path;
    outputOgpImage(%pc);
  }

  open(my $IMG, '<', $path) or error("500:画像ファイルが開けませんでした。");
  my $size = -s $IMG;
  binmode $IMG;
  binmode STDOUT;
  print "Content-type: $mimeType\n";
  print "Content-Length: $size\n";
  print "Cache-Control: public, max-age=604800\n";
  print "Content-Disposition: inline; filename=\"ytsheet_$::in{id}.$ext\"\n";
  print "\n";
  while (read($IMG, my $buf, 65536)) { print $buf; }
  close($IMG);

  exit;
}

### OGP用画像表示 ####################################################################################
sub outputOgpImage {
  my $canUseMagick = 0;
  my $canUseWebp   = 0;
  eval {
    require Image::Magick;
    my @formats = Image::Magick->QueryFormat();
    $canUseMagick = 1;
    $canUseWebp = grep { uc($_) eq 'WEBP' } @formats;
  };
  return if !$canUseMagick;

  my (%opt) = @_;
  my $src     = $opt{src};
  my $fit     = $opt{imageFit} // 'cover';
  my $percent = ($opt{imagePercent} // 100);
  my $posX    = ($opt{imagePositionX} // '50');
  my $posY    = ($opt{imagePositionY} // '50');

  my $W = 630;
  my $H = 630;

  ## ベース
  my $BASE = Image::Magick->new(
    size => "${W}x${H}",
  );
  $BASE->Read('xc:#f5f5f5');

  ## 元画像
  my $IMG = Image::Magick->new;

  my $error = $IMG->Read($src);
  die $error if $error;

  my ($iw, $ih) = $IMG->Get('width','height');

  my ($nw, $nh);
  ## background-size 相当
  if ($fit eq 'contain') {
    my $scale = ($iw / $W > $ih / $H)
      ? $W / $iw
      : $H / $ih;
    $nw = int($iw * $scale);
    $nh = int($ih * $scale);
  }
  elsif ($fit eq 'cover') {
    my $scale = ($iw / $W < $ih / $H)
      ? $W / $iw
      : $H / $ih;
    $nw = int($iw * $scale);
    $nh = int($ih * $scale);
  }
  elsif ($fit eq 'percentX') {
    $nw = int($W * ($percent / 100));
    $nh = int($ih * ($nw / $iw));
  }
  elsif ($fit eq 'percentY') {
    $nh = int($H * (($percent * 1.2) / 100));
    $nw = int($iw * ($nh / $ih));
  }
  else {
    $nw = $iw;
    $nh = $ih;
  }

  ## リサイズ
  $IMG->Resize(
    width  => $nw,
    height => $nh,
  );

  ## position 計算
  my $px = $posX / 100;
  my $py = $posY / 100;

  my $x = int(($W - $nw) * $px);
  my $y = int(($H - $nh) * ($py * 0.9)); # 上寄せ気味

  ## 合成
  $BASE->Composite(
    image   => $IMG,
    compose => 'Over',
    x       => $x,
    y       => $y,
  );

  ## 出力
  my $ext = $canUseWebp ? 'webp' : 'jpeg';
  my $blob = $BASE->ImageToBlob( magick => $ext );

  print "Content-Type: image/$ext\n";
  print "Cache-Control: public, max-age=60480\n\n";
  binmode STDOUT;
  print $blob;
  exit;
}

1;
