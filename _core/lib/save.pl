################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

if($::in{base64mode}){
  use MIME::Base64;
  foreach(keys %::in){
    next if $_ eq 'mode';
    next if !$_;
    next if $_ =~ /^imageFile[0-9]*$/;
    $::in{$_} = decode('utf8', decode_base64($::in{$_}) );
  }
}
else {
  foreach(keys %::in){
    next if $_ =~ /^imageFile[0-9]*$/;
    $::in{$_} = decode('utf8', param($_))
  }
}

changeFileByType($::in{type});

our $mode_save = 1;

our $mode = $::in{mode};
our $pass = $::in{pass};
our $newId;
(our $edit_ver = $::in{ver}) =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;

## 管理者モード判定
my $hasMasterKey;
if(($set::masterid && $LOGIN_ID eq $set::masterid) || ($set::masterkey && $pass eq $set::masterkey)){
  $hasMasterKey = 1;
}

## パスワードチェック
if($::in{protect} eq 'password' && !$hasMasterKey){
  if ($pass eq ''){ error('400:パスワードが入力されていません。'); }
  else {
    if ($pass =~ /[^0-9A-Za-z\.\-\/]/) { error('400:パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです。'); }
  }
}
## 新規作成時処理
if ($mode eq 'make'){
  ##ログインチェック
  if($set::user_reqd && !$LOGIN_ID) {
    error('401:ログインしていません。');
  }
  
  ## 登録キーチェック
  if(!$set::user_reqd && $set::registerkey && $set::registerkey ne $::in{registerkey}){
    error('400:登録キーが一致しません。');
  }
  
  open (my $LIST, '<', $set::passfile);
  my %ids = map { (/^([^<]+)</)[0] => 1; } <$LIST>;
  close ($LIST);
  if(open (my $DEL, '<', $set::data_dir.'/deleted.cgi')){
    $ids{ (/^([^<]+)</)[0] } = 1 while <$DEL>;
    close ($DEL);
  }
  ## ID生成
  if($set::id_type && $LOGIN_ID){
    my $type = (exists $set::lib_type{$::in{type}}) ? $::in{type} : '';
    my $i = 0;
    while (1) {
      $i++;
      $newId = $LOGIN_ID.'-'.$type.sprintf("%03d",$i);
      last unless $ids{$newId};
    }
  }
  else {
    while (1) {
      $newId = randomId(6);
      last unless $ids{$newId};
    }
  }
}

### データ処理 #################################################################################
my %pc = %::in;
delete $pc{imageFile};
delete @pc{ grep { /^imageFile[0-9]+$/ } keys %pc };
delete @pc{ grep { /^editing/ } keys %pc };
if($main::newId){ $pc{id} = $main::newId; }
## 現在時刻
our $now = time;
## 最終更新
$pc{updateTime} = epocToDate($now);

## ファイル名取得
our $file;
if($mode eq 'make'){
  $pc{birthTime} = $file = $now;
}
elsif($mode eq 'save'){
  $file = (authSheet($pc{id},$pc{pass},$LOGIN_ID))[0];
  if(!$file){ error('404:シートが存在しないか、編集権限がありません。'); }
}

our $updatedLine;
require $set::lib_calc_char;
my $dataDir = $set::char_dir;

## 保存数チェック
my $max_files = 32000;
if($mode eq 'make' && $pc{protect} ne 'account'){
  opendir my $dh, "${dataDir}anonymous/";
  my $num_files = () = readdir($dh);
  if($num_files-2 >= $max_files){
    error('503:現在、サーバーの許容量の都合により、ユーザーアカウントに紐づけされていないシートを新規作成できません。\nアカウント登録・ログインをし、編集保護設定で「アカウントに紐付ける」を選択して保存してください。\nすでにログイン中であっても、「アカウントに紐づける」設定での保存しかできません。');
    require $set::lib_edit; exit;
  }
}
if($mode eq 'save' && $pc{protect} ne 'account' && $pc{protectOld} eq 'account'){
  opendir my $dh, "${dataDir}anonymous/";
  my $num_files = () = readdir($dh);
  if($num_files-2 >= $max_files){
    error('503:現在、サーバーの許容量の都合により、ユーザーアカウントに紐づけされていないシートを新規作成できません。\nアカウントに紐づけないデータをこれ以上増やせないため、紐づけ済みのシートの保護設定を変更できません。');
  }
}

### 画像アップロード --------------------------------------------------
my $imageMaxCount = $set::image_maxcount || 1;
$imageMaxCount = 1 if $imageMaxCount < 1;
my %oldext;
my %imageData;
my %imageSizeOk;
my %imageAccepted;
my %imageDelete;
for my $imageNo (1 .. $imageMaxCount){
  my $suffix = imageSuffix($imageNo);
  my $imageKey = "image$suffix";
  my $deleteKey = "imageDelete$suffix";
  my $fileKey = "imageFile$suffix";
  my $updateKey = "imageUpdate$suffix";
  if($pc{$deleteKey}){
    $imageDelete{$imageNo} = 1;
    $oldext{$imageNo} = $pc{$imageKey};
    $pc{$imageKey} = '';
    $pc{mainImage} = '' if ($pc{mainImage} || 1) == $imageNo;
  }
  next if !$::in{$fileKey};

  my $mime;
  my $imagefile = $::in{$fileKey}; # ファイル名の取得
  $mime = uploadInfo($imagefile)->{'Content-Type'}; # MIMEタイプの取得

  # ファイルの受け取り
  my $buffer;
  while(my $bytesread = read($imagefile, $buffer, 2048)) {
    $imageData{$imageNo} .= $buffer;
  }
  # サイズチェック
  my $max_size = ( $set::image_maxsize ? $set::image_maxsize : 1024 * 1024 );
  if (length($imageData{$imageNo}) <= $max_size){ $imageSizeOk{$imageNo} = 1; }

  # MIME-type -> 拡張子
  my $ext; 
  if    ($mime eq "image/gif")   { $ext ="gif"; } #GIF
  elsif ($mime eq "image/jpeg")  { $ext ="jpg"; } #JPG
  elsif ($mime eq "image/pjpeg") { $ext ="jpg"; } #JPG
  elsif ($mime eq "image/png")   { $ext ="png"; } #PNG
  elsif ($mime eq "image/x-png") { $ext ="png"; } #PNG
  elsif ($mime eq "image/webp")  { $ext ="webp"; } #WebP

  # 通して良しなら
  if($imageSizeOk{$imageNo} && $ext){
    $oldext{$imageNo} = $pc{$imageKey} || $oldext{$imageNo};
    $pc{$imageKey} = $ext;
    $pc{$updateKey} = time;
    $imageAccepted{$imageNo} = 1;
    $pc{mainImage} ||= $imageNo;
  }
}
$pc{mainImage} = 1 if !$pc{mainImage} || $pc{mainImage} !~ /^[0-9]+$/ || $pc{mainImage} > $imageMaxCount;
if(!$pc{'image'.imageSuffix($pc{mainImage})}){
  for my $imageNo (1 .. $imageMaxCount){
    if($pc{'image'.imageSuffix($imageNo)}){ $pc{mainImage} = $imageNo; last; }
  }
}
for my $imageNo (1 .. $imageMaxCount){
  delete $pc{'imageDelete'.imageSuffix($imageNo)};
}


## データ計算 --------------------------------------------------
%pc = dataCalc(\%pc);


### 保存 #############################################################################################
## 二重投稿チェック
if ($mode eq 'make'){
  my $_token = $::in{_token};
  if(!checkToken($_token)){
    error('400:セッションの有効期限が切れたか、二重投稿です。一覧やマイリストを確認してください。');
  }
}
### 個別データ保存 --------------------------------------------------
delete $pc{ver};
delete $pc{pass};
delete $pc{_token};
delete $pc{registerkey};
$pc{IP} = $ENV{'REMOTE_ADDR'};
### passfile --------------------------------------------------
if (!-d $set::data_dir){ mkdir $set::data_dir or error("500:データディレクトリ($set::data_dir)の作成に失敗しました。"); }
ensureHtaccessDenied($set::data_dir);
if (!-d $dataDir){ mkdir $dataDir or error("500:データディレクトリ($dataDir)の作成に失敗しました。"); }
my $userDir;
## 新規
if($mode eq 'make'){
  $userDir = appendPassFile($pc{id},$pass,$LOGIN_ID,$pc{protect},$now);
  dataSave('make', $dataDir, $file, $pc{protect}, $userDir, {
    imageData     => \%imageData,
    imageAccepted => \%imageAccepted,
    imageDelete   => \%imageDelete,
  });
}
## 更新
elsif($mode eq 'save'){
  if($pc{protect} ne $pc{protectOld} || $hasMasterKey){
    $userDir = updatePassFile($pc{id},$pass,$LOGIN_ID,$pc{protect},$dataDir);
  }
  else {
    $userDir = ($pc{protect} eq 'account' && $LOGIN_ID) ? "_${LOGIN_ID}/" : 'anonymous/';
  }
  dataSave('save', $dataDir, $file, $pc{protect}, $userDir, {
    imageData     => \%imageData,
    imageAccepted => \%imageAccepted,
    imageDelete   => \%imageDelete,
  });
}
### 一覧データ更新 --------------------------------------------------
updateListFile($updatedLine);

### 画像アップデート --------------------------------------------------
my %newImageData;
for my $imageNo (1 .. $imageMaxCount){
  my $suffix = imageSuffix($imageNo);
  my $imageKey = "image$suffix";
  if($imageDelete{$imageNo} && $oldext{$imageNo}){
    deleteSheetFile("${dataDir}${userDir}", $file, "image$suffix.$oldext{$imageNo}"); # ファイルを削除
    $newImageData{$imageNo} = { ext => '', update => '' };
  }
  if($imageSizeOk{$imageNo} && $pc{$imageKey}){
    if($oldext{$imageNo} && $oldext{$imageNo} ne $pc{$imageKey}){
      deleteSheetFile("${dataDir}${userDir}", $file, "image$suffix.$oldext{$imageNo}"); # 前のファイルを削除
    }
    updateSheetFile("${dataDir}${userDir}", $file, "image$suffix.$pc{$imageKey}", $imageData{$imageNo});
    $newImageData{$imageNo} = { ext => $pc{$imageKey}, update => $pc{"imageUpdate$suffix"} };
  }
}


### 保存後処理 ######################################################################################
### キャラシートへ移動／編集画面に戻る --------------------------------------------------
if($edit_ver < 1.18012){
  print "Location: ./?id=".($newId || $pc{id})."\n\n";
  exit;
}
if($mode eq 'make'){
  infoJson('make',$newId);
}
else {
  infoJson('ok','保存しました。', { newImageData => \%newImageData })
}


### サブルーチン ###################################################################################
sub dataSave {
  my $mode = shift;
  my $dir  = shift;
  my $file = shift;
  my $protect = shift;
  my $userDir = shift;
  my $imageOpt = shift || {};
  my $archiveImageData     = $imageOpt->{imageData}     || {};
  my $archiveImageAccepted = $imageOpt->{imageAccepted} || {};
  my $archiveImageDelete   = $imageOpt->{imageDelete}   || {};

  if (!-d "${dir}${userDir}"){
    mkdir "${dir}${userDir}" or error("500:データディレクトリの作成に失敗しました。");
  }
  if (!-d "${dir}${userDir}${file}"){
    if($mode eq 'save' && -d "${dir}${file}"){ #v1.14/v1.20のコンバート処理
      move("${dir}${file}", "${dir}${userDir}${file}") or error("500:データディレクトリの移動に失敗しました。");
    }
    else {
      mkdir "${dir}${userDir}${file}" or error("500:データファイルの作成に失敗しました。");
    }
  }
  $dir .= $userDir;

  my $logListContent = '';
  my $logsContent = readSheetFile($dir, $file, 'logs.cgi') // '';

  ## バックアップ作成
  if($mode eq 'save'){
    my $lately_term    = 60*60*24;
    my $interval_long  = 60 * ($set::log_interval_long  || 60);
    my $interval_short = 60 * ($set::log_interval_short || 15);
    
    my $latest_epoc;
    my %logName;
    my %logSave;
    my @logList;
    my $delete_flag;
    if(!sheetFileExists($dir, $file, 'log-list.cgi')){ checkLogFile("${dir}${file}") }
    foreach (readSheetFileLines $dir, $file, 'log-list.cgi'){
      chomp;
      my ($date, $epoc, $name) = split('<>', $_, 3);
      if($name){ $logName{$date} = $name; }
      if($date eq 'latest'){
        $latest_epoc = $epoc;
      }
      else {
        push(@logList, { date => $date, epoc => $epoc, name => $name });
      }
    }
    $latest_epoc ||= sheetFileMTime($dir, $file, 'data.cgi');
    my $latest_date = epocToDateQuery($latest_epoc);
    
    if($now - $latest_epoc > 3){ #3秒未満の連続更新は処理を飛ばす
      my $before_saved = 0;
      foreach my $i (0 .. $#logList){
        my $epoc = $logList[$i]{epoc};
        my $next = $logList[$i+1]{epoc} || $latest_epoc;
        if (
          $now - $epoc <= $lately_term ||
          $logList[$i]{name} ne '' ||
          $next - $epoc >= $interval_long ||
          ($next - $epoc >= $interval_short &&
           $epoc - $before_saved >= $interval_long)
        ){
          $before_saved = $epoc;
          $logSave{ $logList[$i]{date} } = $epoc;
        }
        else {
          $delete_flag = 1
        }
      }

      # set::log_max 以上を削除
      if($set::log_max && scalar(keys %logSave) >= $set::log_max){
        my $max_over = scalar(keys %logSave)+1 - $set::log_max;
        foreach (sort keys %logSave){
          if($max_over <= 0){ last; }
          if(!exists $logName{$_}){ delete $logSave{$_}; $delete_flag = 1; $max_over--; }
        }
      }

      my $dataContent = readSheetFile($dir, $file, 'data.cgi') // '';
      # data => logs (削除あり)
      if($delete_flag){
        my @lines = split(/(?<=\n)/, $logsContent);
        $logsContent = '';
        my $cut = 0;
        foreach (@lines) {
          if (index($_, "=") == 0){
            $cut = 0;
            if($_ =~ /^=(.+?)=/){
              if(!$logSave{$1}){ $cut = 1; }
            }
          }
          $logsContent .= $_ if !$cut;
        }
      }

      $logsContent .= "=${latest_date}=\n";
      $logsContent .= $dataContent;
      $logsContent .= "\n" if $dataContent ne '' && $dataContent !~ /\n\z/;
      
      $logListContent .= "$_<>$logSave{$_}<>$logName{$_}\n" foreach (sort keys %logSave);
      $logListContent .= "${latest_date}<>${latest_epoc}<>$logName{latest}\n";
      $logListContent .= "latest<>${now}<>\n";
    }
    else {
      $logListContent = readSheetFile($dir, $file, 'log-list.cgi') // '';
    }
  }
  elsif($mode eq 'make'){
    $logListContent = "latest<>${now}<>\n";
  }

  ## data.cgi保存／更新
  my $dataContent = "ver<>$main::ver\n";
  foreach (sort keys %pc){
    if($pc{$_} ne "") { $dataContent .= "$_<>$pc{$_}\n"; }
  }

  my %archive = (
    'data.cgi'     => $dataContent,
    'logs.cgi'     => $logsContent,
    'log-list.cgi' => $logListContent,
  );
  foreach my $ext (qw(png jpg jpeg gif webp)){
    foreach my $imageNo (1 .. ($set::image_maxcount || 1)){
      my $suffix = imageSuffix($imageNo);
      my $imageKey = "image$suffix";
      if($archiveImageAccepted->{$imageNo}){
        next if $pc{$imageKey} ne $ext;
        $archive{"image$suffix.$ext"} = $archiveImageData->{$imageNo};
        next;
      }
      next if $archiveImageDelete->{$imageNo};
      my $image = readSheetFileBinary($dir, $file, "image$suffix.$ext");
      $archive{"image$suffix.$ext"} = $image if defined $image;
    }
  }
  saveSheetArchive($dir, $file, \%archive);
}

sub appendPassFile {
  my ($id, $pass ,$LOGIN_ID, $protect, $now) = @_;
  
  my $userDir;
  appendFile($set::passfile, sub {
    my ($WRITE) = @_;
    # 衝突チェック
    if(open (my $READ, '<', $set::passfile)){
      foreach (<$READ>){
        if ($_ =~ /^(?:[^<]*<>){2}$now</){
          close($READ);
          error('409:新規作成が衝突しました。再度保存してください。');
        }
      }
      close($READ);
    }
    # パスワードハッシュ化＆ディレクトリ確定
    my $passwrite;
    if   ($protect eq 'account' && $LOGIN_ID){ $passwrite = '['.$LOGIN_ID.']'; $userDir = '_'.$LOGIN_ID.'/'; }
    elsif($protect eq 'password')            { $passwrite = encrypt($pass); }
    $userDir ||= 'anonymous/';
    # 書込（追記）
    print $WRITE "$id<>$passwrite<>$now<>".$::in{type}."<>\n";
  });

  return $userDir;
}

sub updatePassFile {
  my ($id, $pass ,$LOGIN_ID, $protect, $dir) = @_;
  
  my $userDir;
  overwriteFile($set::passfile, sub {
    my ($READ, $WRITE) = @_;
    # パスファイル読込
    my @lines = <$READ>;
    close($READ);
    # データチェック
    my $move; my $oldDir; my $newDir; my $sheet;
    foreach (@lines){
      if(index($_, "$id<") == 0){
        my @data = split /<>/;
        $sheet = $data[2];
        my $passwrite = $data[1];
        if($passwrite =~ /^\[(.+?)\]$/){ $oldDir = '_'.$1.'/'; }
        if   ($protect eq 'account')  {
          if($passwrite !~ /^\[.+?\]$/) {
            $passwrite = '['.$LOGIN_ID.']';
            $move = 1;
            $newDir = '_'.$LOGIN_ID.'/';
          }
        }
        elsif($protect eq 'password') {
          if(!$passwrite || $passwrite =~ /^\[.+?\]$/) { $passwrite = encrypt($pass); }
          if($oldDir) { $move = 1; }
        }
        elsif($protect eq 'none') {
          $passwrite = '';
          if($oldDir) { $move = 1; }
        }
        $_ = "$data[0]<>$passwrite<>$data[2]<>$data[3]<>\n";
      }
    }
    $oldDir ||= 'anonymous/';
    $newDir ||= 'anonymous/';
    if($move){
      if(!-d "${dir}${newDir}"){ mkdir "${dir}${newDir}" or return("500:データディレクトリの作成に失敗しました。//save".__LINE__); }
      if(-d "${dataDir}${oldDir}${sheet}"){
        move("${dataDir}${oldDir}${sheet}", "${dataDir}${newDir}${sheet}") or return("500:データディレクトリの移動に失敗しました。（${oldDir}⇒${newDir}）//save".__LINE__);
      }
      if(-f "${dataDir}${oldDir}${sheet}.zip"){
        move("${dataDir}${oldDir}${sheet}.zip", "${dataDir}${newDir}${sheet}.zip") or return("500:ZIPファイルの移動に失敗しました。（${oldDir}⇒${newDir}）//save".__LINE__);
      }
      $userDir = $newDir;
    }
    else {
      $userDir = $oldDir;
    }
    # 書込
    print $WRITE @lines;
  });

  return $userDir;
}

sub updateListFile {
  my $updatedLine  = shift;

  overwriteFile($set::listfile, sub {
    my ($READ, $WRITE) = @_;

    print $WRITE "$updatedLine\n";
    
    foreach (<$READ>){
      if(index($_, "$pc{id}<") == 0){ next; }
      else { print $WRITE $_; }
    }
  });
}

sub setUpdatatLineImage {
  my $pc = $_[0];
  my @data;

  foreach my $n (1 .. $set::image_maxcount){
    my $s = imageSuffix($n);
    if($pc->{"image$s"} && !$pc->{"imageHide$s"}){
      push(@data,
        $n.($pc->{"imageSpoiler$s"} ? escapeThanSign(qq|+$pc->{"imageSpoiler$s"}|) : '')
      );
    }
  }
  return join(',', @data);
}

1;
