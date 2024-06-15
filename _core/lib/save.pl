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
our $new_id;
(our $edit_ver = $::in{ver}) =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;

## パスワードチェック
if($::in{protect} eq 'password'){
  if ($pass eq ''){ infoJson('error','パスワードが入力されていません。'); }
  else {
    if ($pass =~ /[^0-9A-Za-z\.\-\/]/) { infoJson('error','パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです。'); }
  }
}
## 新規作成時処理
if ($mode eq 'make'){
  ##ログインチェック
  if($set::user_reqd && !$LOGIN_ID) {
    infoJson('error','ログインしていません。');
  }
  
  ## 登録キーチェック
  if(!$set::user_reqd && $set::registerkey && $set::registerkey ne $::in{registerkey}){
    infoJson('error','登録キーが一致しません。');
  }
  
  ## ID生成
  if($set::id_type && $LOGIN_ID){
    my $type = (exists $set::lib_type{$::in{type}}) ? $::in{type} : '';
    my $i = 1;
    $new_id = $LOGIN_ID.'-'.$type.sprintf("%03d",$i);
    # 重複チェック
    while (overlapCheck($new_id)) {
      $i++;
      $new_id = $LOGIN_ID.'-'.$type.sprintf("%03d",$i);
    }
  }
  else {
    $new_id = random_id(6);
    # 重複チェック
    while (overlapCheck($new_id)) {
      $new_id = random_id(6);
    }
  }
}

## 重複チェックサブルーチン
sub overlapCheck {
  my $id = shift;
  my $flag;
  open (my $FH, '<', $set::passfile);
  while (my $line = <$FH>){ 
    if(index($line, "$id<") == 0){ $flag = 1; }
  }
  close ($FH);
  return $flag;
}

### データ処理 #################################################################################
my %pc = %::in;
if($main::new_id){ $pc{id} = $main::new_id; }
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
  (undef, undef, $file, undef) = getfile($pc{id},$pc{pass},$LOGIN_ID);
  if(!$file){ infoJson('error','編集権限がありません。'); }
}

our $newline;
require $set::lib_calc_char;
my $data_dir = $set::char_dir;
my $listfile = $set::listfile;

## 保存数チェック
my $max_files = 32000;
if($mode eq 'make' && $pc{protect} ne 'account'){
  opendir my $dh, "${data_dir}anonymous/";
  my $num_files = () = readdir($dh);
  if($num_files-2 >= $max_files){
    infoJson('error','現在、サーバーの許容量の都合により、ユーザーアカウントに紐づけされていないシートを新規作成できません。\nアカウント登録・ログインをし、編集保護設定で「アカウントに紐付ける」を選択して保存してください。\nすでにログイン中であっても、「アカウントに紐づける」設定での保存しかできません。');
    require $set::lib_edit; exit;
  }
}
if($mode eq 'save' && $pc{protect} ne 'account' && $pc{protectOld} eq 'account'){
  opendir my $dh, "${data_dir}anonymous/";
  my $num_files = () = readdir($dh);
  if($num_files-2 >= $max_files){
    infoJson('error','現在、サーバーの許容量の都合により、ユーザーアカウントに紐づけされていないシートを新規作成できません。\nアカウントに紐づけないデータをこれ以上増やせないため、紐づけ済みのシートの保護設定を変更できません。');
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
my $mask = umask 0;

## 二重投稿チェック
if ($mode eq 'make'){
  my $_token = $::in{_token};
  if(!token_check($_token)){
    infoJson('error','セッションの有効期限が切れたか、二重投稿です。一覧やマイリストを確認してください。');
  }
}
### 個別データ保存 --------------------------------------------------
delete $pc{ver};
delete $pc{pass};
delete $pc{_token};
delete $pc{registerkey};
$pc{IP} = $ENV{'REMOTE_ADDR'};
### passfile --------------------------------------------------
if (!-d $set::data_dir){ mkdir $set::data_dir or infoJson('error',"データディレクトリ($set::data_dir)の作成に失敗しました。"); }
if (!-d $data_dir){ mkdir $data_dir or infoJson('error',"データディレクトリ($data_dir)の作成に失敗しました。"); }
my $user_dir;
## 新規
if($mode eq 'make'){
  $user_dir = passfileWriteMake($pc{id},$pass,$LOGIN_ID,$pc{protect},$now,$data_dir);
}
## 更新
elsif($mode eq 'save'){
  if($pc{protect} ne $pc{protectOld}
    || ($set::masterid && $LOGIN_ID eq $set::masterid)
    || ($set::masterkey && $pass eq $set::masterkey)
  ){
    $user_dir = passfileWriteSave($pc{id},$pass,$LOGIN_ID,$pc{protect},$data_dir);
  }
  else {
    $user_dir = ($pc{protect} eq 'account' && $LOGIN_ID) ? "_${LOGIN_ID}/" : 'anonymous/';
  }
  dataSave('save', $data_dir, $file, $pc{protect}, $user_dir);
}
### 一覧データ更新 --------------------------------------------------
listSave($listfile, $newline);

### 画像アップ更新 --------------------------------------------------
if($pc{imageDelete}){
  unlink "${data_dir}${user_dir}${file}/image.$pc{image}"; # ファイルを削除
}
if($imageflag && $pc{image}){
  unlink "${data_dir}${user_dir}${file}/image.$oldext"; # 前のファイルを削除
  open(my $IMG, ">", "${data_dir}${user_dir}${file}/image.$pc{image}");
  binmode($IMG);
  print $IMG $imagedata;
  close($IMG);
}



### 保存後処理 ######################################################################################
### キャラシートへ移動／編集画面に戻る --------------------------------------------------
if($edit_ver < 1.18012){
  print "Location: ./?id=".(${new_id} || $pc{id})."\n\n";
  exit;
}
if($mode eq 'make'){
  infoJson('make',$new_id);
}
else {
  infoJson('ok','保存しました。')
}




### サブルーチン ###################################################################################
use File::Copy qw/move/;

sub dataSave {
  my $mode = shift;
  my $dir  = shift;
  my $file = shift;
  my $protect = shift;
  my $user_dir = shift;

  if (!-d "${dir}${user_dir}"){
    mkdir "${dir}${user_dir}" or infoJson('error',"データディレクトリの作成に失敗しました。");
  }
  if (!-d "${dir}${user_dir}${file}"){
    if($mode eq 'save' && -d "${dir}${file}"){ #v1.14/v1.20のコンバート処理
      move("${dir}${file}", "${dir}${user_dir}${file}") or infoJson('error',"データディレクトリの移動に失敗しました。");
    }
    else {
      mkdir "${dir}${user_dir}${file}" or infoJson('error',"データファイルの作成に失敗しました。");
    }
  }
  $dir .= $user_dir;

  ## バックアップ作成
  if($mode eq 'save'){
    my $lately_term    = 60*60*24;
    my $interval_long  = 60 * ($set::log_interval_long  || 60);
    my $interval_short = 60 * ($set::log_interval_short || 15);
    
    my $latest_epoc;
    my %log_name;
    my %log_save;
    my @log_list;
    my $delete_flag;
    if(!-f "${dir}${file}/log-list.cgi"){ logFileCheck("${dir}${file}") }
    open (my $FH, "${dir}${file}/log-list.cgi");
    flock($FH, 1);
    while (<$FH>){
      chomp;
      my ($date, $epoc, $name) = split('<>', $_, 3);
      if($name){ $log_name{$date} = $name; }
      if($date eq 'latest'){
        $latest_epoc = $epoc;
      }
      else {
        push(@log_list, { date => $date, epoc => $epoc, name => $name });
      }
    }
    close($FH);
    $latest_epoc ||= (stat("${dir}${file}/data.cgi"))[9];
    my $latest_date = epocToDateQuery($latest_epoc);
    
    if($now - $latest_epoc > 3){ #3秒未満の連続更新は処理を飛ばす
      my $before_saved = 0;
      foreach my $i (0 .. $#log_list){
        my $epoc = $log_list[$i]{epoc};
        my $next = $log_list[$i+1]{epoc} || $latest_epoc;
        if (
          $now - $epoc <= $lately_term ||
          $log_list[$i]{name} ne '' ||
          $next - $epoc >= $interval_long ||
          ($next - $epoc >= $interval_short &&
           $epoc - $before_saved >= $interval_long)
        ){
          $before_saved = $epoc;
          $log_save{ $log_list[$i]{date} } = $epoc;
        }
        else {
          $delete_flag = 1
        }
      }

      # set::log_max 以上を削除
      if($set::log_max && scalar(keys %log_save) >= $set::log_max){
        my $max_over = scalar(keys %log_save)+1 - $set::log_max;
        foreach (sort keys %log_save){
          if($max_over <= 0){ last; }
          if(!exists $log_name{$_}){ delete $log_save{$_}; $delete_flag = 1; $max_over--; }
        }
      }
    
      # data => logs (削除あり)
      if($delete_flag){
        sysopen(my $BU,"${dir}${file}/logs.cgi", O_RDWR | O_CREAT, 0666);
        flock($BU, 2);
        my @lines = <$BU>;
        seek($BU, 0, 0);

        my $cut = 0;
        foreach (@lines) {
          if (index($_, "=") == 0){
            $cut = 0;
            if($_ =~ /^=(.+?)=/){
              if(!$log_save{$1}){ $cut = 1; }
            }
          }
          print $BU $_ if !$cut;
        }

        print $BU "=${latest_date}=\n";
        open (my $IN, '<', "${dir}${file}/data.cgi");
        flock($IN, 2);
        print $BU $_ while (<$IN>);
        close($IN);

        truncate($BU, tell($BU));
        close($BU);
      }
      # data => logs (追記のみ)
      else {
        open (my $IN, '<', "${dir}${file}/data.cgi");
        sysopen (my $BU, "${dir}${file}/logs.cgi", O_WRONLY | O_APPEND | O_CREAT, 0666);
        flock($BU, 2);
        print $BU "=${latest_date}=\n";
        print $BU $_ while (<$IN>);
        close($BU);
        close($IN);
      }
      
      sysopen (my $BUL, "${dir}${file}/log-list.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
      flock($BUL, 2);
      print $BUL "$_<>$log_save{$_}<>$log_name{$_}\n" foreach (sort keys %log_save);
      print $BUL "${latest_date}<>${latest_epoc}<>$log_name{latest}\n";
      print $BUL "latest<>${now}<>\n";
      close($BUL);
    }
  }
  elsif($mode eq 'make'){
    sysopen (my $BUL, "${dir}${file}/log-list.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
    flock($BUL, 2);
    print $BUL "latest<>${now}<>\n";
    close($BUL);
  }

  ## data.cgi保存／更新
  sysopen (my $DD, "${dir}${file}/data.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
  flock($DD, 2);
  print $DD "ver<>",$main::ver,"\n";
  foreach (sort keys %pc){
    if($pc{$_} ne "") { print $DD "$_<>$pc{$_}\n"; }
  }
  close($DD);
}

sub passfileWriteMake {
  my ($id, $pass ,$LOGIN_ID, $protect, $now, $data_dir) = @_;
  sysopen (my $FH, $set::passfile, O_RDWR | O_APPEND | O_CREAT, 0666);
  flock($FH, 2);
  my @list = <$FH>;
  foreach (@list){
    if ($_ =~ /^(?:[^<]*?<>){2}$now</){
      close($FH);
      infoJson('error','新規作成が衝突しました。再度保存してください。');
    }
  }
  my $passwrite; my $user_dir;
  if   ($protect eq 'account'&& $LOGIN_ID) { $passwrite = '['.$LOGIN_ID.']'; $user_dir = '_'.$LOGIN_ID.'/'; }
  elsif($protect eq 'password')            { $passwrite = e_crypt($pass); }
  $user_dir ||= 'anonymous/';
  dataSave('make', $data_dir, $file, $protect, $user_dir);
  print $FH "$id<>$passwrite<>$now<>".$::in{type}."<>\n";
  close($FH);
  return $user_dir;
}

sub passfileWriteSave {
  my ($id, $pass ,$LOGIN_ID, $protect, $dir) = @_;
  my $move; my $old_dir; my $new_dir; my $file;
  sysopen (my $FH, $set::passfile, O_RDWR);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    if(index($_, "$id<") == 0){
      my @data = split /<>/;
      $file = $data[2];
      my $passwrite = $data[1];
      if($passwrite =~ /^\[(.+?)\]$/){ $old_dir = '_'.$1.'/'; }
      if   ($protect eq 'account')  {
        if($passwrite !~ /^\[.+?\]$/) {
          $passwrite = '['.$LOGIN_ID.']';
          $move = 1;
          $new_dir = '_'.$LOGIN_ID.'/';
        }
      }
      elsif($protect eq 'password') {
        if(!$passwrite || $passwrite =~ /^\[.+?\]$/) { $passwrite = e_crypt($pass); }
        if($old_dir) { $move = 1; }
      }
      elsif($protect eq 'none') {
        $passwrite = '';
        if($old_dir) { $move = 1; }
      }
      $_ = "$data[0]<>$passwrite<>$data[2]<>$data[3]<>\n";
    }
  }
  $old_dir ||= 'anonymous/';
  $new_dir ||= 'anonymous/';
  my $user_dir;
  if($move){
    if(!-d "${dir}${new_dir}"){ mkdir "${dir}${new_dir}" or infoJson('error',"データディレクトリの作成に失敗しました。"); }
    move("${data_dir}${old_dir}${file}", "${data_dir}${new_dir}${file}") or infoJson('error',"データディレクトリの移動に失敗しました。（${old_dir}⇒${new_dir}）");
    $user_dir = $new_dir;
  }
  else {
    $user_dir = $old_dir;
  }
  print $FH $_ foreach @list;
  truncate($FH, tell($FH));
  close($FH);

  return $user_dir;
}

sub listSave {
  my $listfile = shift;
  my $newline  = shift;
  sysopen (my $FH, $listfile, O_RDWR | O_CREAT, 0666);
  flock($FH, 2);
  my @list = <$FH>;
  my @tmp = map { (split /<>/)[3] } @list;
  @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp];
  seek($FH, 0, 0);
  print $FH "$newline\n";
  foreach (@list){
    if(index($_, "$pc{id}<") != 0){
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
}


1;