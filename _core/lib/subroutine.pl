use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl qw(:DEFAULT :flock);
use File::Copy qw/move/;
use File::Basename qw/dirname/;
use Encode qw/encode decode/;
use IO::Compress::Zip;
use IO::Uncompress::Unzip;

### サブルーチン #####################################################################################
our %statusCode = (
  400 => '400 Bad Request',
  401 => '401 Unauthorized',
  404 => '404 Not Found',
  403 => '403 Forbidden',
  409 => '409 Conflict',
  410 => '410 Gone',
  429 => '429 Too Many Requests',
  500 => '500 Internal Server Error',
  502 => '502 Bad Gateway',
  503 => '503 Service Unavailable',
);
### 案内画面 --------------------------------------------------
sub info {
  our $header = shift;
  our $message = shift;
  require $set::lib_info;
  exit;
}

### JSON --------------------------------------------------
sub infoJson {
  our $type = shift;
  our $message = shift;
  $message =~ s/"/\\\"/g;
  my $code;
  $message =~ s/^([0-9]{3}):/$code = $1; ''/e;
  if($code){
    if($statusCode{$code}){ print "Status: $statusCode{$code}\n"; }
    else { print "Status: $code\n"; }
  }
  print "Content-type: text/javascript; charset=utf-8\n\n";
  print '{"result":"'.$type.'","message":"'.$message.'"}';
  exit;
}

### JSファイル --------------------------------------------------
sub printJS {
  my $mode = shift;
  print "Content-type: text/javascript; charset=utf-8\n";
  print "Cache-Control: public, max-age=604800\n";
  print "\n";
  print "// ytsheet JS output mode:$mode \n\n";
  if($mode eq 'consts' && $set::lib_js_consts){
    require $set::lib_js_consts;
  }
  exit;
}

### エラー画面 --------------------------------------------------
sub error {
  our $message = shift;
  if($::in{mode} =~ /^(?:json|make|save)$/){
    infoJson('error',$message =~ s/<br>/ /gr);
  }
  else {
    info('エラー',$message);
  }
}

### ファイル名取得／パスorアカウント必要時 --------------------------------------------------
sub authSheet {
  open (my $FH, '<', $set::passfile) or die;
  while (my $line = <$FH>) {
    if(index($line, "$_[0]<") == 0){ #まずID照会
      close($FH);
      my ($id, $pass, $file, $type) = (split /<>/, $line)[0..3];
      if ( (!$pass) # パス不要
        || (&verifyCrypt($_[1], $pass)) # パス一致
        || ($pass eq "[$_[2]]") # 編集権アカウント一致
        || ($set::masterkey && $_[1] eq $set::masterkey) # 管理者パス一致
        || ($set::masterid && $_[2] eq $set::masterid) # 管理者アカウント一致
      ) {
        my $user;
        if($pass =~ /^\[(.+?)\]$/){ $user =$1; }
        return ($file, $type, $user);
      }
      return 0; #ID一致かつパス不一致
    }
  }
  close($FH);
  return 0;
}
### ファイル名取得／パスorアカウント不要時 --------------------------------------------------
sub findSheet {
  open (my $FH, '<', $set::passfile) or die;
  while (my $line  = <$FH>) {
    if(index($line, "$_[0]<") == 0){
      close($FH);
      my ($id, $pass, $file, $type) = (split /<>/, $line)[0..3];
      my $user;
      if($pass =~ /^\[(.+?)\]$/){ $file = '_'.$1.'/'.$file; $user = $1; }
      else { $file = 'anonymous/'.$file; }
      return ($file, $type, $user);
    }
  }
  close($FH);
  return 0;
}
### ファイルロック／更新 --------------------------------------------------
sub withLock {
  my ($filePath, $code) = @_;

  sysopen my $LOCK, "$filePath.lock", O_RDWR | O_CREAT
    or error "500:ロックファイルのオープンに失敗しました。";
  flock($LOCK, LOCK_EX)
    or error "500:ファイルのロックに失敗しました。";

  $code->();
  
  close($LOCK);
}
sub overwriteFile {
  my ($filePath, $code) = @_;
  withLock($filePath, sub {
    # 一時ファイル作成
    my $tmpfile;
    my $WRITE;
    while (1) {
      $tmpfile = dirname($filePath)."/tmp_$::in{mode}$::in{type}_".randomId(16);
      last if sysopen $WRITE, $tmpfile, O_WRONLY | O_EXCL | O_CREAT;
    }
    # ファイル読込
    sysopen my $READ, $filePath, O_RDONLY | O_CREAT
      or error "500:ファイルのオープンに失敗しました。//subroutine".__LINE__;
    # 処理
    my $returnValue;
    $returnValue = $code->($READ, $WRITE); # 戻り値はエラーメッセージ
    close($READ);
    close($WRITE);
    if($returnValue =~ /^[0-9]{3}:/){ unlink $tmpfile; error($returnValue); }
    # 保存（一時ファイルから上書き差替）
    rename $tmpfile, $filePath;
  });
}
sub appendFile {
  my ($filePath, $code) = @_;
  withLock($filePath, sub {
    # ファイルオープン
    sysopen my $WRITE, $filePath, O_WRONLY | O_APPEND | O_CREAT
      or error "500:ファイルのオープンに失敗しました。//subroutine".__LINE__;
    # 処理
    $code->($WRITE);
    close($WRITE);
  });
}
### typeによって各ファイル・ディレクトリを変更 --------------------------------------------------
sub changeFileByType {
  my $type = shift;
  if($type && exists $set::lib_type{$type}){
    return if exists $set::lib_type{chara};
    $set::lib_type{chara}{listFile} = $set::listfile;
    $set::lib_type{chara}{dataDir}  = $set::char_dir;
    $set::lib_type{chara}{edit}     = $set::lib_edit_char;
    $set::lib_type{chara}{calc}     = $set::lib_calc_char;
    $set::lib_type{chara}{view}     = $set::lib_view_char;
    $set::lib_type{chara}{list}     = $set::lib_list_char;
    $set::lib_type{chara}{skin}     = $set::skin_sheet;

    $set::listfile      = $set::lib_type{$type}{listFile};
    $set::char_dir      = $set::lib_type{$type}{dataDir};
    $set::lib_edit_char = $set::lib_type{$type}{edit};
    $set::lib_calc_char = $set::lib_type{$type}{calc};
    $set::lib_view_char = $set::lib_type{$type}{view};
    $set::lib_list_char = $set::lib_type{$type}{list};
    $set::skin_sheet    = $set::lib_type{$type}{skin};
  }
}

### シートアーカイブ --------------------------------------------------
sub sheetZipPath {
  my ($dir, $file) = @_;
  return "${dir}${file}.zip";
}
sub sheetLegacyDirPath {
  my ($dir, $file) = @_;
  return "${dir}${file}";
}
sub sheetFilePath {
  my ($dir, $file, $name) = @_;
  return "${dir}${file}/${name}";
}
sub sheetFileExists {
  my ($dir, $file, $name) = @_;
  my $zipPath = sheetZipPath($dir, $file);
  return 1 if zipMemberExists($zipPath, $name);
  return -f sheetFilePath($dir, $file, $name);
}
sub zipMemberExists {
  my ($zipPath, $member) = @_;
  return 0 if !-f $zipPath;

  my $ZIP = IO::Uncompress::Unzip->new($zipPath)
    or error "500:ZIPファイルのオープンに失敗しました。$IO::Uncompress::Unzip::UnzipError";
  while (1) {
    my $header = $ZIP->getHeaderInfo();
    if($header && $header->{Name} eq $member){
      close($ZIP);
      return 1;
    }
    last unless $ZIP->nextStream();
  }
  close($ZIP);
  return 0;
}
sub isSheetBinaryEntry {
  my $name = shift;
  return $name =~ /^image\.(?:png|jpe?g|gif|webp)$/i ? 1 : 0;
}
sub readZipMember {
  my ($zipPath, $member, $binary) = @_;
  return undef if !-f $zipPath;
  $binary = isSheetBinaryEntry($member) if !defined $binary;

  my $ZIP = IO::Uncompress::Unzip->new($zipPath)
    or error "500:ZIPファイルのオープンに失敗しました。$IO::Uncompress::Unzip::UnzipError";
  while (1) {
    my $header = $ZIP->getHeaderInfo();
    if($header && $header->{Name} eq $member){
      my $content = '';
      my $buffer;
      while (($ZIP->read($buffer)) > 0) { $content .= $buffer; }
      close($ZIP);
      return $binary ? $content : decode('UTF-8', $content);
    }
    last unless $ZIP->nextStream();
  }
  close($ZIP);
  return undef;
}
sub readSheetFile {
  my ($dir, $file, $name) = @_;
  my $zipPath = sheetZipPath($dir, $file);
  my $content = readZipMember($zipPath, $name, 0);
  return $content if defined $content;

  my $path = sheetFilePath($dir, $file, $name);
  return undef if !-f $path;
  open(my $IN, '<', $path) or error "500:データファイルが開けませんでした。";
  my $data = do { local $/; <$IN> };
  close($IN);
  return $data;
}
sub readSheetFileBinary {
  my ($dir, $file, $name) = @_;
  my $zipPath = sheetZipPath($dir, $file);
  my $content = readZipMember($zipPath, $name, 1);
  return $content if defined $content;

  my $path = sheetFilePath($dir, $file, $name);
  return undef if !-f $path;
  open(my $IN, '<', $path) or error "500:データファイルが開けませんでした。";
  binmode $IN;
  my $data = do { local $/; <$IN> };
  close($IN);
  return $data;
}
sub readSheetFileLines {
  my ($dir, $file, $name) = @_;
  my $content = readSheetFile($dir, $file, $name);
  return wantarray ? () : undef if !defined $content;
  return split(/(?<=\n)/, $content);
}
sub readSheetRecordLines {
  my ($dir, $file, $datatype, $log) = @_;
  my @source = readSheetFileLines($dir, $file, "${datatype}.cgi");
  if(!@source){
    checkDeletedSheet();
    error('404:シートが見つかりませんでした。');
  }
  elsif($datatype ne 'logs'){
    return @source;
  }

  my @lines;
  my $hit = 0;
  foreach (@source){
    if (index($_, "=") == 0){
      if (index($_, "=${log}=") == 0){ $hit = 1; next; }
      if ($hit){ last; }
    }
    if (!$hit) { next; }
    push(@lines, $_);
  }
  if(!$hit){ error("404:過去ログ（${log}）が見つかりません。"); }
  return @lines;
}
sub checkDeletedSheet {
  if(open (my $LIST, '<', $set::data_dir.'/deleted.cgi')){
    while(my $line = <$LIST>){
      if(index($line, "$::in{id}<") == 0){ error('410:削除されたシートです。'); }
    }
    close($LIST);
  }
  if(defined &viewNotFound) { viewNotFound(); }
}
sub sheetFileMTime {
  my ($dir, $file, $name) = @_;
  my $path = sheetFilePath($dir, $file, $name);
  return (stat($path))[9] if -f $path;
  my $zipPath = sheetZipPath($dir, $file);
  return (stat($zipPath))[9] if -f $zipPath;
  return undef;
}
sub sheetZipTmpDir {
  my $tmpDir = "${set::data_dir}/.tmp";
  if(!-d $tmpDir){
    mkdir $tmpDir or -d $tmpDir
      or error "500:ZIP一時ディレクトリの作成に失敗しました。$!";
  }
  return $tmpDir;
}
sub createSheetZipTmpFile {
  my $tmpDir = sheetZipTmpDir();
  my $tmpfile;
  my $lastError;
  foreach (1 .. 100) {
    $tmpfile = "$tmpDir/tmp_zip_$::in{mode}$::in{type}_".randomId(16);
    if(sysopen(my $TMP, $tmpfile, O_WRONLY | O_EXCL | O_CREAT)){
      close($TMP);
      return $tmpfile;
    }
    $lastError = "$!";
  }
  error "500:ZIP一時ファイルの作成に失敗しました。$lastError";
}
sub writeSheetZip {
  my ($zipPath, $entries) = @_;
  my $tmpfile;
  my @names = sort keys %{$entries};
  if(!@names){
    unlink $zipPath;
    return;
  }

  my $zipError;
  my $ok = eval {
    $tmpfile = createSheetZipTmpFile();
    my $first = shift @names;

    my $ZIP = IO::Compress::Zip->new(
      $tmpfile,
      Name   => $first,
      Method => IO::Compress::Zip::ZIP_CM_STORE(),
    ) or do { $zipError = "500:ZIPファイルの作成に失敗しました。$IO::Compress::Zip::ZipError"; die; };
    print $ZIP isSheetBinaryEntry($first) ? $entries->{$first} : encode('UTF-8', $entries->{$first});
    foreach my $name (@names){
      $ZIP->newStream(
        Name   => $name,
        Method => IO::Compress::Zip::ZIP_CM_STORE(),
      ) or do { $zipError = "500:ZIPエントリの作成に失敗しました。$IO::Compress::Zip::ZipError"; die; };
      print $ZIP isSheetBinaryEntry($name) ? $entries->{$name} : encode('UTF-8', $entries->{$name});
    }
    close($ZIP) or do { $zipError = "500:ZIPファイルの保存に失敗しました。$IO::Compress::Zip::ZipError"; die; };
    rename $tmpfile, $zipPath or do { $zipError = "500:ZIPファイルの差し替えに失敗しました。"; die; };
    1;
  };
  if(!$ok){
    my $message = $zipError || $@ || '500:ZIPファイルの保存に失敗しました。';
    unlink $tmpfile if $tmpfile && -f $tmpfile;
    error $message;
  }
}

sub readSheetZipEntries {
  my $zipPath = shift;
  my %entries;
  return %entries if !-f $zipPath;

  my $ZIP = IO::Uncompress::Unzip->new($zipPath)
    or error "500:ZIPファイルのオープンに失敗しました。$IO::Uncompress::Unzip::UnzipError";
  while (1) {
    my $header = $ZIP->getHeaderInfo();
    if($header){
      my $content = '';
      my $buffer;
      while (($ZIP->read($buffer)) > 0) { $content .= $buffer; }
      $entries{$header->{Name}} = isSheetBinaryEntry($header->{Name}) ? $content : decode('UTF-8', $content);
    }
    last unless $ZIP->nextStream();
  }
  close($ZIP);
  return %entries;
}
sub cleanupSheetLegacyDir {
  my ($dir, $file, $entries) = @_;
  my $legacyDir = sheetLegacyDirPath($dir, $file);
  return if !-d $legacyDir;

  foreach my $name (keys %{$entries}){
    next if $name =~ m|/|;
    my $path = sheetFilePath($dir, $file, $name);
    unlink $path if -f $path;
  }
  rmdir $legacyDir;
}
sub updateSheetArchive {
  my ($dir, $file, $code) = @_;
  my $zipPath = sheetZipPath($dir, $file);
  my %current = readSheetZipEntries($zipPath);
  my $changed = $code->(\%current);
  if($changed){
    writeSheetZip($zipPath, \%current);
    cleanupSheetLegacyDir($dir, $file, \%current);
  }
  return $changed;
}
sub saveSheetArchive {
  my ($dir, $file, $entries) = @_;
  $entries ||= {};
  updateSheetArchive($dir, $file, sub {
    my $current = shift;
    foreach my $name (keys %{$entries}){ $current->{$name} = $entries->{$name}; }
    return 1;
  });
}
sub updateSheetFile {
  my ($dir, $file, $name, $content) = @_;
  my $zipPath = sheetZipPath($dir, $file);
  if(-f $zipPath){
    saveSheetArchive($dir, $file, { $name => $content });
  }
  else {
    sysopen(my $OUT, sheetFilePath($dir, $file, $name), O_WRONLY | O_TRUNC | O_CREAT)
      or error "500:データファイルが開けませんでした。";
    flock($OUT, 2);
    binmode $OUT if isSheetBinaryEntry($name);
    print $OUT $content;
    close($OUT);
  }
}
sub deleteSheetFile {
  my ($dir, $file, $name) = @_;
  my $zipPath = sheetZipPath($dir, $file);
  my $legacyDeleted = unlink sheetFilePath($dir, $file, $name);
  if(-f $zipPath){
    my $zipDeleted = updateSheetArchive($dir, $file, sub {
      my $current = shift;
      return 0 if !exists $current->{$name};
      delete $current->{$name};
      return 1;
    });
    return $zipDeleted || $legacyDeleted;
  }
  return $legacyDeleted;
}

### プレイヤー名取得 --------------------------------------------------
sub getPlayerName {
  my $in_id = shift;
  open (my $FH, '<', $set::userfile);
  while (my $line = <$FH>) {
    if(index($line, "$in_id<") == 0){
      my ($id, $name, $mail) = (split /<>/, $line)[0,2,3];
      close($FH);
      return ($name,$mail);
    }
  }
  close($FH);
  return '';
}

### 編集保護設定取得 --------------------------------------------------
sub getProtectType {
  my $file = shift;
  my $protect   = '';
  my $forbidden = '';
  my $hide = '';
  my @lines;
  if($file =~ m|^(.*/)([^/]+)/data\.cgi$|){
    my ($dir, $sheet) = ($1, $2);
    @lines = readSheetFileLines($dir, $sheet, 'data.cgi');
  }
  if(!@lines){
    open (my $IN, '<', $file) or error('404:データがありません。');
    @lines = <$IN>;
    close($IN);
  }
  foreach my $line (@lines){
    if   ($line =~ /^protect<>(.*)\n/)  { $protect = $1; }
    elsif($line =~ /^forbidden<>(.*)\n/){ $forbidden = $1; }
    elsif($line =~ /^hide<>(.*)\n/){ $hide = $1; }
    
    if($protect && $forbidden && $hide){ last; }
  }
  return ($protect, $forbidden, $hide);
}

### 暗号化 --------------------------------------------------
my $USE_ARGON2 = eval {
  require Crypt::Argon2;
  Crypt::Argon2->import(qw/argon2id_pass argon2id_verify/);
  1;
} ? 1 : 0;

sub encrypt {
  my $plain = shift;
  return '' if !defined $plain || $plain eq '';

  my $s = createSalt(16);
  if($USE_ARGON2){
    my $time_cost = 3;
    my $memory_cost = 65536; # 64 MiB
    my $parallelism = 1;
    my $tag_length = 32;
    return argon2id_pass($plain, $s, $time_cost, $memory_cost, $parallelism, $tag_length);
  }

  return crypt($plain,index(crypt('a','$1$a$'),'$1$a$') == 0 ? '$1$'.$s.'$' : $s);
}

sub verifyCrypt {
  my($plain,$crypt) = @_;
  return 0 if !defined $plain || !defined $crypt || $plain eq '' || $crypt eq '';

  if($USE_ARGON2 && $crypt =~ /^\$argon2id\$/){
    return argon2id_verify($crypt, $plain) ? 1 : 0;
  }
  return crypt($plain,$crypt) eq $crypt;
}
sub createSalt {
  my ($length) = @_;

  if(open(my $RND, '<:raw', '/dev/urandom')){
    my $salt = '';
    if(read($RND, $salt, $length) == $length){
      close($RND);
      return $salt;
    }
    close($RND);
  }

  my @salts = ('0'..'9','A'..'Z','a'..'z','.','/');
  my $salt = '';
  1 while (length($salt .= $salts[rand(@salts)]) < $length);
  return $salt;
}

### ログイン --------------------------------------------------
sub logIn {
  if($set::oauth_service){ error("$set::oauth_serviceでのログインのみ有効です。"); }
  my $key = getKey($_[0],$_[1]);
  if($key){
    my $flag = 0;
    sysopen (my $FH, $set::login_users, O_RDWR | O_CREAT);
      flock($FH, 2);
      my @list = <$FH>;
      seek($FH, 0, 0);
      foreach (@list){
        my @line = (split/<>/, $_);
        if (time - $line[2] < 60*60*24*365){
          print $FH $_;
        }
      }
      print $FH "$_[0]<>$key<>".time."<>\n";
      truncate($FH, tell($FH));
    close ($FH);
    print &setCookie($set::cookie,$_[0],$key,'+365d');
  }
  else { error('ログインできませんでした。'); }
  
  if($set::url_home){ print "Location: $set::url_home\n\n"; }
  else { print "Location: ./\n\n"; }
}

### キー取得 --------------------------------------------------
sub getKey {
  my $in_id  = $_[0];
  my $in_pass= $_[1];
  open (my $FH, '<', $set::userfile);
  while (my $line = <$FH>) {
    my ($id, $pass) = (split /<>/, $line)[0,1];
    if ($in_id eq $id && (&verifyCrypt($in_pass, $pass))) {
      close($FH);
      my $s;
      my @salt = ('0'..'9','A'..'Z','a'..'z','.','/');
      1 while (length($s .= $salt[rand(@salt)] ) < 12);
      if($USE_ARGON2 && $pass !~ /^\$argon2id\$/){ updatePasswordHash($in_id,$in_pass); }
      return $s;
    }
  }
  close($FH);
  return 0;
}
sub updatePasswordHash {
  my ($id, $pass) = @_;
  overwriteFile($set::userfile, sub {
    my ($READ, $WRITE) = @_;
    foreach (<$READ>){
      if(index($_, "$id<") == 0){
        my @data = split(/<>/, $_, -1);
        @data[1] = encrypt($pass);
        print $WRITE join('<>', @data);
      }
      else{
        print $WRITE $_;
      }
    }
  });
}

### ログアウト --------------------------------------------------
sub logOut {
  my ($id, $key) = &getCookie;
  my $key  = $::in{key};
  open (my $FH, '+<', $set::login_users);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    my @line = (split/<>/, $_);
    if($id eq $line[0] && $key eq $line[1]){
    }
    else {
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
  print &setCookie($set::cookie,$id,$key,'Thu, 1-Jan-1970 00:00:00 GMT');
  
  if($set::url_home){ print "Location: $set::url_home\n\n"; }
  else { print "Location: ./\n\n"; }
}
### ログインチェック --------------------------------------------------
sub check {
  my ($in_id, $in_key) = &getCookie;
  return 0 if !$in_id || !$in_key;
  open (my $FH, $set::login_users) or 0;
  while (my $line = <$FH>){
    if(index($line, "$in_id<") == 0){
      my @data = (split/<>/, $line);
      if ($in_key eq $data[1] && time - $data[2] < 86400*365) {
        close($FH);
        return ($in_id);
      }
    }
  }
  close($FH);
  return 0;
}

### Cookieセット --------------------------------------------------
sub setCookie {
  my $value   = "$_[1]<>$_[2]";
  my $cookie = new CGI::Cookie(
    -name    => $_[0] ,
    -value   => $value ,
    -expires => $_[3] ,
  );
  return ("Set-Cookie: $cookie\n");
}

### Cookieゲット --------------------------------------------------
sub getCookie {
  my %cookies = fetch CGI::Cookie;
  my $value   = $cookies{$set::cookie}->value if(exists $cookies{$set::cookie});
  my @return = split(/<>/, $value);
  return @return;
}

### ランダムID生成 --------------------------------------------------
sub randomId {
  my @char = (0..9,'a'..'z','A'..'Z');
  my $s;
  1 while (length($s .= $char[rand(@char)]) < $_[0]);
  return $s;
}

### トークンチェック --------------------------------------------------
sub checkToken {
  my $in_token = shift;
  my $flag = 0;
  open (my $FH, '+<', $set::tokenfile);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    my ($token, $time) = (split/<>/, $_);
    if   ($token eq $in_token && $time >= time){ $flag = 1; }
    elsif($time < time) {  }
    else { print $FH $_; }
  }
  truncate($FH, tell($FH));
  close($FH);
  
  return $flag;
}
### メール送信 --------------------------------------------------
sub sendmail {
  my $from    = encode('MIME-Header', "ゆとシートⅡ")." <$set::admimail>";
  my $to      = shift;
  my $subject = encode('MIME-Header', shift);
  my $message = shift;

  $from    =~ s/\r|\n//g;
  $to      =~ s/\r|\n//g;
  $subject =~ s/\r|\n//g;

  open (my $MA, "|$set::sendmail -t") or &error("500:sendmailの起動に失敗しました。");
  print $MA "To: $to\n";
  print $MA "From: $from\n";
  print $MA "Subject: $subject\n";
  print $MA "Content-Transfer-Encoding: 8bit\n";
  print $MA "Content-Type: text/plain; charset=utf-8\n\n";
  print $MA $message;
  close($MA);
}

### URIエスケープ --------------------------------------------------
sub uri_escape_utf8 {
  my($tmp) = @_;
  $tmp = encode('utf8',$tmp);
  $tmp =~ s/([^\w])/'%'.unpack("H2", $1)/ego;
  $tmp =~ tr/ /+/;
  $tmp = decode('utf8',$tmp);
  return($tmp);
}

### 端数切り上げ --------------------------------------------------
sub ceil {
  my $num = shift;
  my $val = 0;
 
  $val = 1 if($num > 0 and $num != int($num));
  return int($num + $val);
}

### 正の数に+追加/0なら空 --------------------------------------------------
sub addNum {
  my $num = shift;
  return ($num > 0) ? "+$num" : ($num == 0) ? '' : $num;
}

### 算術演算子の連続を最適化 --------------------------------------------------
sub optimizeOperator {
  my $text = shift;
  $text =~ s/\+\++/\+/g;
  $text =~ s/\+-/-/g;
  $text =~ s/-\+/-/g;
  return $text;
}
sub optimizeOperatorFirst {
  my $text = shift;
  $text =~ s/^\+\++/\+/;
  $text =~ s/^\+-/-/;
  $text =~ s/^-\+/-/;
  return $text;
}
### 数値3桁区切り --------------------------------------------------
sub commify {
  my $num = shift;
  $num=~s/([0-9]{1,3})(?=(?:[0-9]{3})+(?![0-9]))/$1,/g;
  return $num;
}

### 整数判定 --------------------------------------------------
sub isInteger {
  $_[0] =~ /^[+-]?[0-9]+$/;
}
sub hasInteger {
  foreach(@_) {
    return 1 if isInteger($_);
  }
  return 0;
}

### エポック秒 => 年-月-日 時:分 --------------------------------------------------
sub epocToDate {
  my ($min, $hour, $day, $mon, $year) = (localtime(shift))[1..5];
  return sprintf("%04d-%02d-%02d %02d:%02d",$year+1900,$mon+1,$day,$hour,$min);
}
sub epocToDateQuery {
  my ($sec, $min, $hour, $day, $mon, $year) = (localtime(shift))[0..5];
  return sprintf("%04d-%02d-%02d-%02d-%02d-%02d",$year+1900,$mon+1,$day,$hour,$min, $sec);
}

### 数式を安全にevalする --------------------------------------------------
sub s_eval {
  my $i = shift;
  $i =~ y/ 　\t//d;
  if($i =~ /[^0-9,\+\-\*\/\%\(\) ]/){ $i = 0; }
  $i =~ s/,([0-9]{3}(?![0-9]))/$1/g;
  return eval($i);
}

### 前後の空白削除 --------------------------------------------------
sub trim {
  return shift =~ s/^\s+|\s+$//gr;
}

### 改行変換 --------------------------------------------------
sub convertEscapedBrToNewlines {
  my $pc = shift;
  for my $key (@_) {
    next unless defined $pc->{$key};
    $pc->{$key} =~ s/&lt;br&gt;/\n/g;
  }
}

### エスケープ --------------------------------------------------
sub escapePcData {
  my $text = shift;
  $text =~ s/&/&amp;/g;
  $text =~ s/"/&quot;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  $text =~ tr/\r\n//d;
  return $text;
}
sub normalizeHashtags {
  my $text = shift;
  $text =~ s/\s/ /g; #空白統一
  $text =~ tr/ / /s; #空白詰める
  $text =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  $text =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
  return $text;
}
sub escapeThanSign {
  my $text = shift;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  return $text;
}

### タグ変換 --------------------------------------------------
sub unescapeTags {
  my $text = shift;
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  #$text =~ s/\{\{([0-9\+\-\*\/\%\(\) ]+?)\}\}/s_eval($1);/eg;
  
  $text =~ s#(―{2,})#<span class="d-dash">$1</span>#g;
  
  $text =~ s{©}{<i class="s-icon copyright">©</i>}gi;

  if($set::game eq 'sw2'){
    if($::in{mode} ne 'download'){
      $text =~ s/\[魔\]/<img alt="&#91;魔&#93;" class="i-icon" src="${set::icon_dir}item_magic.png">/gi;
      $text =~ s/\[刃\]/<img alt="&#91;刃&#93;" class="i-icon" src="${set::icon_dir}item_edge.png">/gi;
      $text =~ s/\[打\]/<img alt="&#91;打&#93;" class="i-icon" src="${set::icon_dir}item_blow.png">/gi;
      $text =~ s/\[流\]/<img alt="&#91;流&#93;" class="i-icon" src="${set::icon_dir}item_school.png">/gi;
      $text =~ s/\[ア\]/<img alt="&#91;ア&#93;" class="i-icon" src="${set::icon_dir}item_school_a.png">/gi;
      $text =~ s/\[テ\]/<img alt="&#91;テ&#93;" class="i-icon" src="${set::icon_dir}item_school_t.png">/gi;
      $text =~ s/\[特\]/<img alt="&#91;特&#93;" class="i-icon" src="${set::icon_dir}item_local.png">/gi;
    }
    else {
      $text =~ s|\[魔\]|<img alt="&#91;魔&#93;" class="i-icon" src="data:image/webp;base64,UklGRngAAABXRUJQVlA4TGwAAAAvDUADEJUwqm2rSmh72cEmtnAOl7eMwJ+7zogw28hpOPMa4UHcl0zaNkgVlL67ppBtBAjj/MUO5DeYtE2KbLc8HtGup3ve0ssIJGMUH2QWX6zWQv8NUmOoKtlKw84kPYHu3EhQYAK96yf1aB0=">|gi;
      $text =~ s|\[刃\]|<img alt="&#91;刃&#93;" class="i-icon" src="data:image/webp;base64,UklGRnQAAABXRUJQVlA4TGcAAAAvDUADEA5HbSMJEtB9L43lcuiOSHdjqKqoJMJsI6D9JjGQMz0yBW3bMPwB92+SggYEGKestBqxCXiAz6/MF3vqbz4X8f/vInwp2NqETVZh0yRFBVsZBdjKXDDNXIBmFkgb0ESL1FwBAA==">|gi;
      $text =~ s|\[打\]|<img alt="&#91;打&#93;" class="i-icon" src="data:image/webp;base64,UklGRngAAABXRUJQVlA4TGsAAAAvDUADEA4HbSNJEqj78BymA3eA+sFQUpdSitq2gfgj7PktgQGYyKRtSq8qmsmZJpC0Ya1We/3OmYAHpP2ufrcRz/n/f3cZPkXKpUt3aQQNKQ6UoxGwCfVICXGA2FaI7US2BfEsDi045A3yFgA=">|gi;
      $text =~ s|\[流\]|<img alt="&#91;流&#93;" class="i-icon" src="data:image/webp;base64,UklGRqAAAABXRUJQVlA4TJQAAAAvDUADENVACeBIkIQPnpc389pe3lvZVREN4UUahyRcQds2TNt9BMM0/nwmRW3bQD35kxyIvSqlbRswrPf2+aKpMGkDpjO3fL6w/d3nz52A88P3nRn4zf0F9ydcSaSQs+k/cGnb1vho0i1KONjStVsAomhS1wBp2nfJKk1r4NCeUHHO1GXdFvuKmqTq2T6AQM72Gx4E">|gi;
      $text =~ s|\[ア\]|<img alt="&#91;ア&#93;" class="i-icon" src="data:image/webp;base64,UklGRmgAAABXRUJQVlA4TFwAAAAvDUADEFUwattI0O8ILKkDeviOxOwuhrRR07YBm6r6TzCdAIJsG6n5k23/BKzhfa+rn3z70xNUAziDwgM/Rw2QxDpMIrRxR9vChSEerMmJNqfQcgElXhI8rsHrAg==">|gi;
      $text =~ s|\[テ\]|<img alt="&#91;テ&#93;" class="i-icon" src="data:image/webp;base64,UklGRmQAAABXRUJQVlA4TFcAAAAvDUADEFUwiCTJiZH/BwSiDG+YuGRhA5G2zfz7u5LSA7IBylRhpiBtA0ZU/RvbnYDHeHe1qc/+3zctkV7x1GTQoCsRzYFCBBgzD9ASADYAsTJp5tZjqE0A">|gi;
      $text =~ s|\[特\]|<img alt="&#91;特&#93;" class="i-icon" src="data:image/webp;base64,UklGRogAAABXRUJQVlA4THwAAAAvDUADECdAJm3jX1Rl1EjZOSFk2Uj+BKd0Dufw669k2Uj+Aud0CAfx+49k0jZ1Vf9/LY1F21WA/XcVGESyU+elUwEJgwA4ogAFbab+TX08RPR/AhbvzUOS0EZ5UjZMniVNAe6SijkiHJrCnJKbObTr6Bf0ccZH2c3vIik2">|gi;
    }
    if($::SW2_0){
      $text =~ s/(\[[常主補宣条選]\])+/&textToIcon($&);/egi;
      $text =~ s/「((?:[○◯〇＞▶〆☆≫»□☐☑🗨▽▼]|&gt;&gt;)+)/"「".&textToIcon($1);/egi;
    } else {
      $text =~ s/(\[[常準主補宣]\])+/&textToIcon($&);/egi;
      $text =~ s/「((?:[○◯〇△＞▶〆☆≫»□☐☑🗨]|&gt;&gt;)+)/"「".&textToIcon($1);/egi;
    }
    $text =~ s|\[[⤴↑]\]|<i class="s-icon uplift">⤴</i>|g;
    $text =~ s|\[[⤵↓]\]|<i class="s-icon calm">⤵</i>|g;
    $text =~ s|\[♡\]|<i class="s-icon heart">♡</i>|g;
  }
  
  
  our @linkPlaceholders;
  $text =~ s/((?:making|能力値作成(?:履歴)?)#([0-9]+(?:-[0-9]+)?))/ &generateLinkTag("?&mode=making&num=$2",$1) /egi if($set::game eq 'sw2'); # メイキングリンク
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/ &generateLinkTag($2,$1) /egi; # リンク
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/ &generateLinkTag("?id=$2",$1) /egi; # シート内リンク
  $text =~ s/(https?:\/\/[^\s\<]+)/ &generateLinkTag($1,$1) /egi; # 自動リンク
  
  $text =~ s/'''(.+?)'''/<span class="oblique">$1<\/span>/gi; # 斜体
  $text =~ s/''(.+?)''/<b>$1<\/b>/gi;  # 太字
  $text =~ s/%%(.+?)%%/<span class="strike">$1<\/span>/gi;  # 打ち消し線
  $text =~ s/__(.+?)__/<span class="underline">$1<\/span>/gi;  # 下線
  $text =~ s/\{\{(.+?)\}\}/<span style="color:transparent">$1<\/span>/gi;  # 透明
  $text =~ s/[|｜]([^|｜\n]+?)《(.+?)》/<ruby><rp>｜<\/rp>$1<rp>《<\/rp><rt>$2<\/rt><rp>》<\/rp><\/ruby>/gi; # なろう式ルビ
  $text =~ s/《《(.+?)》》/<span class="text-em">$1<\/span>/gi; # カクヨム式傍点

  $text =~ s/\x{FFFC}(\d+)\x{FFFC}/$linkPlaceholders[$1-1]/g; # リンク後処理
  
  $text =~ s/\n/<br>/gi;

  if($set::game eq 'sw2'){
  }
  
  return $text;
  
  sub generateLinkTag {
    my $url = shift;
    my $txt = shift;
    $txt =~ s{<a .+?>|</a>}{}g; # 内側のリンクは削除（二重リンク防止）
    push @linkPlaceholders, $url;
    my $number = "\x{FFFC}" . scalar(@linkPlaceholders) . "\x{FFFC}";
    if($txt =~ "^https?://"){ $txt = $number; } # $txtがURL形式なら$urlと同じに（二重リンクとURLの偽り防止）
    if($url =~ /^[#\.\/\?]/){ return '<a href="'.$number.'">'.$txt.'</a>'; }
    else { return '<a href="'.$number.'" target="_blank">'.$txt.'</a>'; }
  }
}
sub unescapeTagsLines {
  my $text = shift;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  $text =~ s|^//(.*?)\n?$||gm; # コメントアウト
  
  $text =~ s/\\\\\n/<br>/gi;
  
  $text =~ s/^LEFT:/<\/p><p class="left">/gim;
  $text =~ s/^CENTER:/<\/p><p class="center">/gim;
  $text =~ s/^RIGHT:/<\/p><p class="right">/gim;
  
  my $d_count = 0;
  $d_count += ($text =~ s/^\[(&gt;|[vＶｖ])\]\*\*\*\*(.*?)$/"<\/p><details @{[$1 eq '&gt;' ? '' : 'open']}><summary class=\"header4\">$2<\/summary><div class=\"detail-body\"><p>"/gime);
  $d_count += ($text =~ s/^\[(&gt;|[vＶｖ])\]\*\*\*(.*?)$/"<\/p><details @{[$1 eq '&gt;' ? '' : 'open']}><summary class=\"header3\">$2<\/summary><div class=\"detail-body\"><p>"/gime);
  $d_count += ($text =~ s/^\[(&gt;|[vＶｖ])\]\*\*(.*?)$/"<\/p><details @{[$1 eq '&gt;' ? '' : 'open']}><summary class=\"header2\">$2<\/summary><div class=\"detail-body\"><p>"/gime);
  $d_count += ($text =~ s/^\[(&gt;|[vＶｖ])\]\*(.*?)$/"<\/p><details @{[$1 eq '&gt;' ? '' : 'open']}><summary class=\"header1\">$2<\/summary><div class=\"detail-bod\"><p>"/gime);
  $d_count += ($text =~ s/^\[(&gt;|[vＶｖ])\](.+?)$/"<\/p><details @{[$1 eq '&gt;' ? '' : 'open']}><summary>$2<\/summary><div class=\"detail-body\"><p>"/gime);
  $d_count += ($text =~ s/^\[(&gt;|[vＶｖ])\]$/"<\/p><details @{[$1 eq '&gt;' ? '' : 'open']}><summary>詳細<\/summary><div class=\"detail-body\"><p>"/gime);
  while($text =~ s/^\[-{3,}\]\n?$/<\/p><\/div><\/details><p>/im) {
    $d_count--;
    last if $d_count <= 0;
  }

  $text =~ s/^-{4,}$/<\/p><hr><p>/gim;
  $text =~ s/^( \*){4,}$/<\/p><hr class="dotted"><p>/gim;
  $text =~ s/^( \-){4,}$/<\/p><hr class="dashed"><p>/gim;
  $text =~ s/^\*\*\*\*(.*?)$/<\/p><h5>$1<\/h5><p>/gim;
  $text =~ s/^\*\*\*(.*?)$/<\/p><h4>$1<\/h4><p>/gim;
  $text =~ s/^\*\*(.*?)$/<\/p><h3>$1<\/h3><p>/gim;
  $text =~ s/^\*(.*?)$/<\/p><h2>$1<\/h2><p>/gim;
  
  $text =~ s/(?:^(?:\|(?:.*?))+\|[hc]?(?:\n|$))+/'<\/p>'.&generateTable($&).'<p>'/egim;

  $text =~ s/^\:(.*?)\|(.*?)$/<dt>$1<\/dt><dd>$2<\/dd>/gim;
  $text =~ s/(<\/dd>)\n/$1/gi;
  $text =~ s/<\/dd><dt>\s*<\/dt><dd>/&lt;br&gt;/gi;
  $text =~ s/(?!<\/dd>)(<dt>.*?<\/dd>)(?!<dt>)/<\/p><dl class="note-description">$1<\/dl><p>/gi;
  $text =~ s/<dt> *?<\/dt>//gim;

  $text =~ s/\n<\/p>/<\/p>/gi;
  $text =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
  $text =~ s/<p><\/p>//gi;
  $text =~ s/\n/&lt;br&gt;/gi;
  
  while($d_count > 0) {
    $text .= "</div></details>";
    $d_count--;
  }
  
  return $text;
}

sub generateTable {
  my $text = shift;
  my $output = '<table class="note-table">';
  my @data;
  my @classes;
  foreach my $line (split("\n", $text)){
    $line =~ s/^\|//;
    if   (!@data && $line eq 'data-table|'){ $output = '<table class="data-table">'; next; }
    elsif(!@data && $line eq 'max-table|' ){ $output = '<table class="note-table width-max">'; next; }
    elsif($line =~ /c$/){ (my $row, @classes) = generateTableCol($line); $output .= $row; next; }
    elsif($line =~ /h$/){ $output .= generateTableHeader($line); next; }
    my @row = split('\|', $line);
    push(@data, [ @row ]);
  }
  my $row_num = 0;
  foreach my $row (@data){
    $output .= "<tr>";
    my $col_num = 0;
    my $colspan = 1;
    foreach my $col (@{$row}){
      my $rowspan = 1;
      my $td = 'td';
      while($data[$row_num+$rowspan][$col_num] eq '~'){ $rowspan++; }
      $col_num++;
      my @classesCell;
      if($classes[$col_num-1]){ push(@classesCell, @{$classes[$col_num-1]}); }
      if   ($col eq '&gt;'){ $colspan++; next; }
      elsif($col eq '~')   { next; }
      elsif($col =~ s/^~//){ $td = 'th' }
      else {
        while($col =~ s/^(LEFT|CENTER|RIGHT|NOWRAP|SMALL)://){
          push(@classesCell, lc($1));
        }
        foreach my $class (reverse @classesCell){
          if($class =~ /^(left|center|right)$/){
            @classesCell = grep { $_ eq $class || !/^(left|center|right)$/ } @classesCell;
            last;
          }
        }
      }
      $output .= "<$td";
      if($colspan > 1){ $output .= ' colspan="'.$colspan.'"'; $colspan = 1; }
      if($rowspan > 1){ $output .= ' rowspan="'.$rowspan.'"'; }
      if(@classesCell){ $output .= ' class="'.join(' ',@classesCell).'"' }
      $output .= ">$col</$td>";
    }
    $output .= "</tr>";
    $row_num++;
  }
  $output .= "</table>";

  return $output;

  sub generateTableCol {
    my @out;
    my @col = (split(/\|/, $_[0]));
    pop @col;
    my @classes;
    foreach(@col){
      if($_ eq '&gt;'){
        push @out, '>';
        push @classes, '>';
      }
      else {
        my ($style, @class) = &generateTableStyle($_);
        push @out, $style;
        push @classes, \@class;
      }
    }
    foreach (0 .. $#out){
      my $n = 1;
      while ($out[$_] eq '>'){
        $out[$_] = $out[$_+$n];
        $n++
      }
      my $n = 1;
      while ($classes[$_] eq '>'){
        $classes[$_] = $classes[$_+$n];
        $n++
      }
    }
    return '<colgroup>'.(join '', @out).'</colgroup>', @classes;
  }
  sub generateTableStyle {
    my $text = shift;
    my $style;
    my @class;
    while($text =~ s/^(LEFT|CENTER|RIGHT|NOWRAP|SMALL)://){
      push @class, lc($1);
    }
    if($text =~ /^([0-9]+)(px|em|\%)/){
      my $num = $1; my $type = $2;
      if   ($type eq 'px' && $num > 300){ $num = 300 }
      elsif($type eq 'em' && $num >  20){ $num =  20 }
      elsif($type eq  '%' && $num > 100){ $num = 100 }
      $style .= "width:calc(${num}${type} + 1em + 1px);";
    }
    return "<col style=\"$style\">", @class,
  }
  sub generateTableHeader {
    my $line = shift;
    my $output;
    $line =~ s/h$//;
    $output .= "<thead><tr>";
    my $colspan = 1;
    foreach my $col (split('\|', $line)){
      my $td = 'td';
      if   ($col eq '&gt;'){ $colspan++; next; }
      elsif($col =~ s/^~//){ $td = 'th' }
      $output .= "<$td";
      if($colspan > 1){ $output .= ' colspan="'.$colspan.'"'; }
      $output .= ">$col</$td>";
    }
    $output .= "</tr></thead>";
    return $output;
  }
}
### タグ削除 --------------------------------------------------
sub removeTags {
  my $text = $_[0];
  $text =~ s#<rp>[\|｜]</rp>##g;
  $text =~ s#<rp>[《]</rp>#(#g;
  $text =~ s#<rp>[》]</rp>#)#g;
  $text =~ s/<img alt="&#91;(.)&#93;"/[$1]<img /g;
  $text =~ s/<.+?>//g;
  $text =~ s/&#91;/[/g;
  $text =~ s/&#93;/]/g;
  return $text;
}
sub removeRuby {
  my $text = shift;
  $text =~ s#<rt>.*?</rt>|<rp>.*?</rp>##g;
  return $text;
}

### RGB>HSL --------------------------------------------------
sub rgbToHsl {
  my $re = shift || 0;
  my $gr = shift || 0;
  my $bl = shift || 0;
  my $RGB_MAX = 255;
  my $HUE_MAX = 360;
  my $SATURATION_MAX = 100;
  my $LIGHTNESS_MAX = 100;

  my $max = max($re,$gr,$bl);
  my $min = min($re,$gr,$bl);
  my ($hu, $sa, $li);

  # Hue
  my $hp = $HUE_MAX / 6;
  if   ($max == $min) { $hu = 0; }
  elsif ($re == $max) { $hu = $hp * (($gr - $bl) / ($max - $min)); }
  elsif ($gr == $max) { $hu = $hp * (($bl - $re) / ($max - $min)) + $HUE_MAX / 3; }
  else                { $hu = $hp * (($re - $gr) / ($max - $min)) + $HUE_MAX * 2 / 3; }
  if ($hu < 0) { $hu += $HUE_MAX; }

  # Saturation
  my $cnt = ($max + $min) / 2;
  if ($max == $min) { $sa = 0; }
  elsif ($cnt < $RGB_MAX / 2) {
    if ($max + $min <= 0) { $sa = 0; }
    else { $sa = ($max - $min) / ($max + $min) * $SATURATION_MAX; }
  }
  else {
    $sa = ($max - $min) / ($RGB_MAX * 2 - $max - $min) * $SATURATION_MAX;
  }

  # Lightness
  my $li = ($max + $min) / $RGB_MAX / 2 * $LIGHTNESS_MAX;

  return ($hu, $sa, $li);
};

### デフォルトカラー --------------------------------------------------
sub setDefaultColors {
  my ($pc,$type) = @_;
  $pc->{$type.'colorHeadBgH'} //= 225;
  $pc->{$type.'colorHeadBgS'} //=   9;
  $pc->{$type.'colorHeadBgL'} //=  65;
  $pc->{$type.'colorBaseBgH'} //= 235;
  $pc->{$type.'colorBaseBgS'} //=   0;
}

### 進数変換 --------------------------------------------------
sub convert10to36 {
  my $number = shift;
  if(!$number){ return 0;}
  my @work;
  while ($number > 0) {
    unshift @work, substr("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", $number % 36, 1);
    $number = int($number / 36);
  }
  return join('', @work);
}
### ケース変換 --------------------------------------------------
sub kebabToCamel {
  return $_[0] =~ s/-([a-z])/\u$1/gr;
}
sub snakeToCamel {
  return $_[0] =~ s/_([a-z])/\u$1/gr;
}

### 行の有無チェック --------------------------------------------------
## 数値の0も偽とする（NameとNoteは空のみ偽）
sub existsRow {
  my $prefix = shift;
  foreach(@_){
    if($_ eq 'Name' || $_ eq 'Note'){
      if($::pc{$prefix.$_} ne ''){ return 1; }
    }
    else {
      if($::pc{$prefix.$_}){ return 1; }
    }
  }
  return 0;
}
## 厳密に空/未定義のみ偽
sub existsRowStrict {
  my $prefix = shift;
  foreach(@_){
    if($::pc{$prefix.$_} ne ''){ return 1; }
  }
  return 0;
}
## 全てが真の場合のみ
sub existsRowFull {
  my $prefix = shift;
  foreach(@_){
    if(!$::pc{$prefix.$_}){ return 0; }
  }
  return 1;
}

### 配列の重複削除 --------------------------------------------------
sub deduplicate {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

### 外部データ取得 --------------------------------------------------
sub fetchText {
  require LWP::UserAgent;

  my $url = shift;
  my $ua  = LWP::UserAgent->new;
  my $res = $ua->get($url);
  if ($res->is_success) {
    return $res->decoded_content;
  }
  elsif($::in{url}) {
    error '400:入力されたURLへのアクセスに失敗しました。URLに誤りがあるか、URL先に問題が発生しています。(STATUS CODE:'.$res->code.')';
  }
}
sub fetchJson {
  my $text = fetchText($_[0]);

  $text = utf8::is_utf8($text) ? encode('utf8', (join '', $text)) : $text;

  my $data = eval { decode_json($text) };
  unless($data) {
    if($::in{url}){
      error '400:JSONデータが取得できませんでした。URLに誤りがあるか、URL先に問題が発生しています。';
    }
    else {
      $data = {  };
    }
  }

  return %{ $data };
}

### シートデータインポート --------------------------------------------------
sub importSheetData {
  my $setUrl = shift;
  my $file;
  
  ## キャラクター保管所
  if($setUrl =~ m"(^https?://charasheet\.vampire-blood\.net/m?[a-f0-9]+)"){
    if(defined &convertHokanjoToYtsheet){
      my %in = fetchJson($1.'.js');
      return convertHokanjoToYtsheet(\%in);
    }
    else {
      error "400:このゲームではキャラクター保管所からのコンバートに対応していません。";
    }
  }
  ## キャラクターシート倉庫
  if($setUrl =~ m"^https?://character-sheets\.appspot\.com/[^/]+/edit.html"){
    if(defined &convertSoukoToYtsheet){
      $setUrl =~ s/edit\.html\?/display\?ajax=1&/;
      my %in = fetchJson($setUrl);
      $in{'image_url'} = $setUrl =~ s/display\?ajax=1&/image?/r;
      return convertSoukoToYtsheet(\%in);
    }
    else {
      error "400:このゲームではキャラクターシート倉庫からのコンバートに対応していません。";
    }
  }
  ## 旧ゆとシート
  {
    foreach my $url (keys %set::convert_url){
      if($setUrl =~ s"^${url}data/(.*?).html"$1"){
        open my $IN, '<', "$set::convert_url{$url}data/${setUrl}.cgi" or error '500:旧ゆとシートのデータが開けませんでした。';
        my %pc;
        $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = $2;/egi while <$IN>;
        close($IN);
        
        return convert1to2(\%pc);
      }
    }
  }
  ## 同じゆとシートⅡ
  my $self = CGI->new()->url;
  if($setUrl =~ m"^$self\?id=(.+?)(?:$|&)"){
    my $id = $1;
    my ($file, $type, $author) = findSheet($id);
    unless($file){
      error '404:コンバート元のゆとシートⅡのデータが見つかりませんでした。URLに誤りがあるか、データが削除されている可能性があります。';
    }
    my %pc;
    my @lines = readSheetFileLines($set::char_dir, $file, 'data.cgi');
    unless(@lines){
      error '500:コンバート元のゆとシートⅡのデータが開けませんでした。';
    }
    foreach (@lines){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }

    my $LOGIN_ID = check;
    unless(
      (!$pc{forbidden}) ||
      ($pc{protect} eq 'none') || 
      ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
    ){
      error '403:閲覧・編集に制限がかかっており、コンバートできないデータです。';
    }
    $pc{imageURL} = $self."?id=$id&mode=image&cache=$pc{imageUpdate}";
    $pc{convertSource} = '同じゆとシートⅡ';
    return %pc;
  }
  ## 別のゆとシートⅡ
  {
    my %pc = fetchJson($setUrl.'&mode=json');
    $_ = escapeThanSign($_) foreach values %pc;
    if($pc{result} eq 'OK'){
      our $base_url = $setUrl;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{convertSource} = '別のゆとシートⅡ';
      return %pc;
    }
    elsif($pc{result}) {
      error "400:コンバート元のゆとシートⅡでエラーがありました。<br>> $pc{result}:$pc{message}";
    }
  }
  
  error '400:有効なデータが取得できませんでした。';
}

### .htaccess作成 --------------------------------------------------
sub ensureHtaccessDenied {
  my ($dir) = @_;

  my $path = "$dir/.htaccess";
  my $content = "Require all denied\n";

  if (-e $path) {
    open(my $FH, '<', $path) or error "500:Cannot read $path: $!";

    local $/;
    my $current = <$FH>;

    close($FH);

    return 1 if $current =~ /^\s*Require\s+all\s+denied\s*$/m;

    error "500:$path already exists, but does not contain 'Require all denied'";
  }

  sysopen(my $FH, $path, O_WRONLY | O_CREAT | O_EXCL, 0644) or error "500:Cannot create $path: $!";
  print $FH $content;
  close($FH);

  return 1;
}

### HTMLテンプレート出力 --------------------------------------------------
sub outputTemplate {
    my ($tmpl) = @_;
    my $out = $tmpl->output;
    if (
      eval { $tmpl->isa('HTML::Template::Pro') }
      && !Encode::is_utf8($out)
    ) {
      $out = Encode::decode('UTF-8', $out);
    }
    return $out;
}
### アップデート・コンバート --------------------------------------------------
## バックアップ形式変更
sub checkLogFile {
  my $dir = shift;
  my $mode = shift;
  if (-d "${dir}/backup") { logFileUpdate($dir,$mode); }
}
sub logFileUpdate {
  my $dir = shift;
  my $mode = shift;

  my $lately_term    = 60*60*24;
  my $interval_long  = 60 * ($set::log_interval_long  || 60);
  my $interval_short = 60 * ($set::log_interval_short || 15);
  
  require Time::Local;

  my %log_name;
  open (my $IN, "${dir}/buname.cgi");
  while (<$IN>){
    chomp;
    my ($date, $name) = split('<>', $_, 2);
    if($name){ $log_name{$date} = $name; }
  }
  close($IN);

  opendir(my $DIR,"${dir}/backup");
  my @log_list;
  while (my $date = readdir($DIR)){
    if ($date =~ s/.cgi$//){
      my ($year, $month, $day, $hour, $min) = split(/-/, $date);
      my $epoc = Time::Local::timelocal(0, $min, $hour, $day, $month-1, $year-1900);
      push(@log_list, { date => $date, epoc => $epoc });
    }
  }
  closedir($DIR);

  my @tmp = map { $_->{date} } @log_list;
  @log_list = @log_list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp];

  my $latest_epoc = (stat("${dir}/data.cgi"))[9];

  my $logs_content = '';
  my $log_list_content = '';
  my $before_saved = 0;
  foreach my $i (0 .. $#log_list){
    my $date = $log_list[$i]{date};
    my $epoc = $log_list[$i]{epoc};
    my $next = $log_list[$i+1]{epoc} || $latest_epoc;
    if (
      $latest_epoc - $epoc <= $lately_term ||
      $log_name{$date} ne '' ||
      $next - $epoc >= $interval_long ||
      ($next - $epoc >= $interval_short &&
       $epoc - $before_saved >= $interval_long)
    ){
      $before_saved = $epoc;
      $logs_content .= "=${date}=\n";
      $log_list_content .= "${date}<>$epoc<>$log_name{$date}\n";
      open(my $IN,"${dir}/backup/${date}.cgi") or die;
      while (my $line = <$IN>){ $logs_content .= $line; };
      close($IN);
    }
    unlink("${dir}/backup/${date}.cgi");
  }
  $log_list_content .= "latest<>$latest_epoc<>\n";
  if($dir =~ m|^(.*/)([^/]+)$|){
    my ($sheetDir, $sheetFile) = ($1, $2);
    my %archive = (
      'data.cgi'     => readSheetFile($sheetDir, $sheetFile, 'data.cgi') // '',
      'logs.cgi'     => $logs_content,
      'log-list.cgi' => $log_list_content,
    );
    foreach my $ext (qw(png jpg jpeg gif webp)){
      my $image = readSheetFileBinary($sheetDir, $sheetFile, "image.$ext");
      $archive{"image.$ext"} = $image if defined $image;
    }
    saveSheetArchive($sheetDir, $sheetFile, \%archive);
  }
  rmdir("${dir}/backup");
  unlink("${dir}/buname.cgi");
  if($mode eq 'view'){ print "Location:./?id=$::in{id}\n\n"; }
}


1;
