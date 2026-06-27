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
  my $sheetDir = $user ? "_${user}/" : 'anonymous/';
  my $fileDir = $set::char_dir . $sheetDir . $file;

  ## 読込・保存
  my @list = readSheetFileLines($set::char_dir . $sheetDir, $file, 'log-list.cgi');
  my $logList = '';
  foreach my $line (@list) {
    if(index($line, $date) == 0){
      chomp $line;
      my($_date, $_epoc, undef) = split(/<>/, $line);
      $logList .= "${_date}<>${_epoc}<>${name}\n";
    }
    else { $logList .= $line; }
  }
  updateSheetFile($set::char_dir . $sheetDir, $file, 'log-list.cgi', $logList);

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
  foreach (readSheetFileLines($datadir, $file, 'data.cgi')){
    if($_ =~ /^((?:mainImage)|(?:image.*?))<>(.*?)\n/){ $pc{$1} = $2; }
  }

  my $imageNo = $::in{imageNo} || $pc{mainImage} || 1;
  $imageNo = 1 if $imageNo !~ /^[0-9]+$/ || $imageNo < 1 || $imageNo > ($set::image_maxcount || 1);
  my $suffix = imageSuffix($imageNo);
  my $ext = $pc{"image$suffix"};
  
  my %mime = (
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    png  => 'image/png',
    gif  => 'image/gif',
    webp => 'image/webp',
  );

  my $path = "./${datadir}/${file}/image$suffix.${ext}";
  my $imageData;
  
  my $imageExists;
  if($ext){
    $imageData = readSheetFileBinary($datadir, $file, "image$suffix.$ext");
    $imageExists = 1 if defined $imageData;
  }
  if(!$imageExists){
    foreach (qw(png jpg jpeg gif webp)) {
      $imageData = readSheetFileBinary($datadir, $file, "image$suffix.$_");
      if(defined $imageData) {
        $path = "./${datadir}/${file}/image$suffix.$_";
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
    $pc{imageData} = $imageData;
    $pc{imageMainSuffix} = $suffix;
    outputOgpImage(%pc);
  }

  binmode STDOUT;
  print "Content-type: $mimeType\n";
  print "Content-Length: ".length($imageData)."\n";
  print "Cache-Control: public, max-age=604800\n";
  print "Content-Disposition: inline; filename=\"ytsheet_$::in{id}.$ext\"\n";
  print "\n";
  print $imageData;

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
  my $src       = $opt{src};
  my $imageData = $opt{imageData};

  my $main      = $opt{imageMainSuffix} // 1;
  my $fit       = $opt{"imageFit$main"} // 'cover';
  my $percent   = ($opt{"imagePercent$main"} // 100);
  my $posX      = ($opt{"imagePositionX$main"} // '50');
  my $posY      = ($opt{"imagePositionY$main"} // '50');

  my $W = 630;
  my $H = 630;

  ## ベース
  my $BASE = Image::Magick->new(
    size => "${W}x${H}",
  );
  $BASE->Read('xc:#f5f5f5');

  ## 元画像
  my $IMG = Image::Magick->new;

  my $error = defined $imageData
    ? $IMG->BlobToImage($imageData)
    : $IMG->Read($src);
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
