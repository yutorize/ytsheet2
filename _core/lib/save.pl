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
    next if $_ =~ 'imageFile';
    $::in{$_} = decode('utf8', decode_base64($::in{$_}) );
  }
}
else {
  foreach(keys %::in){
    next if $_ =~ /^(?:imageFile|imageCompressed)$/;
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
delete $pc{imageCompressed};
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
  $file = (authSheet $pc{id},$pc{pass},$LOGIN_ID)[0];
  if(!$file){ error('404:シートが存在しないか、編集権限がありません。'); }
}

our $newline;
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

## データ計算
%pc = data_calc(\%pc);

### 画像アップロード --------------------------------------------------
my $oldext;
if($pc{imageDelete}){
  $oldext = $pc{image};
  $pc{image} = '';
}
use MIME::Base64;
my $imagedata; my $imageflag;
if($::in{imageCompressed} || $::in{imageFile}){
  my $mime;
  # 縮小済み
  if($::in{imageCompressed}){
    $imagedata = decode_base64( (split ',', $::in{imageCompressed})[1] );
    $mime = $::in{imageCompressedType};
  }
  # オリジナル
  elsif($::in{imageFile}){
    my $imagefile = $::in{imageFile}; # ファイル名の取得
    $mime = uploadInfo($imagefile)->{'Content-Type'}; # MIMEタイプの取得
    
    # ファイルの受け取り
    my $buffer;
    while(my $bytesread = read($imagefile, $buffer, 2048)) {
      $imagedata .= $buffer;
    }
  }
  # サイズチェック
  my $max_size = ( $set::image_maxsize ? $set::image_maxsize : 1024 * 1024 );
  if (length($imagedata) <= $max_size){ $imageflag = 1; }

  # MIME-type -> 拡張子
  my $ext; 
  if    ($mime eq "image/gif")   { $ext ="gif"; } #GIF
  elsif ($mime eq "image/jpeg")  { $ext ="jpg"; } #JPG
  elsif ($mime eq "image/pjpeg") { $ext ="jpg"; } #JPG
  elsif ($mime eq "image/png")   { $ext ="png"; } #PNG
  elsif ($mime eq "image/x-png") { $ext ="png"; } #PNG
  elsif ($mime eq "image/webp")  { $ext ="webp"; } #WebP

  # 通して良しなら
  if($imageflag && $ext){
    $oldext = $pc{image} || $oldext;
    $pc{image} = $ext;
    $pc{imageUpdate} = time;
  }
}


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
  dataSave('make', $dataDir, $file, $pc{protect}, $userDir);
}
## 更新
elsif($mode eq 'save'){
  if($pc{protect} ne $pc{protectOld} || $hasMasterKey){
    $userDir = updatePassFile($pc{id},$pass,$LOGIN_ID,$pc{protect},$dataDir);
  }
  else {
    $userDir = ($pc{protect} eq 'account' && $LOGIN_ID) ? "_${LOGIN_ID}/" : 'anonymous/';
  }
  dataSave('save', $dataDir, $file, $pc{protect}, $userDir);
}
### 一覧データ更新 --------------------------------------------------
updateListFile($newline);

### 画像アップ更新 --------------------------------------------------
if($pc{imageDelete} && $oldext){
  deleteSheetFile("${dataDir}${userDir}", $file, "image.$oldext"); # ファイルを削除
}
if($imageflag && $pc{image}){
  if($oldext && $oldext ne $pc{image}){
    deleteSheetFile("${dataDir}${userDir}", $file, "image.$oldext"); # 前のファイルを削除
  }
  updateSheetFile("${dataDir}${userDir}", $file, "image.$pc{image}", $imagedata);
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
  infoJson('ok','保存しました。')
}




### サブルーチン ###################################################################################
sub dataSave {
  my $mode = shift;
  my $dir  = shift;
  my $file = shift;
  my $protect = shift;
  my $userDir = shift;

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
    my $image = readSheetFileBinary($dir, $file, "image.$ext");
    $archive{"image.$ext"} = $image if defined $image;
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
  my $newline  = shift;

  overwriteFile($set::listfile, sub {
    my ($READ, $WRITE) = @_;

    print $WRITE "$newline\n";
    
    foreach (<$READ>){
      if(index($_, "$pc{id}<") == 0){ next; }
      else { print $WRITE $_; }
    }
  });
}

1;