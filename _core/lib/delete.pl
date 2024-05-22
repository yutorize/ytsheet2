################### データ削除 ###################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = check;
my $mode = $::in{mode};
my $message;


if(!$::in{id}){ error('IDがありません。'); }
if(!$::in{check1} || !$::in{check2} || !$::in{check3}){ error('確認のチェックが入っていません。'); }

my ($sheet_id, $sheet_user, $file, $type, $user);
($sheet_id, undef, $file, $type, $user) = getfile($::in{id},$::in{pass},$LOGIN_ID);
changeFileByType($type);
my $dataDir = $set::char_dir;
if(!$file){ error('データが見つかりません。'); }
my $fileDir = $user ? "_${user}/${file}" : "anonymous/${file}";

## キャラシ削除
if($mode eq 'delete'){
  open (my $FH, "+<", $set::listfile) or error('一覧ファイルのオープンに失敗しました。');
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    if(index($_, "$::in{id}<") == 0){
      $message .= 'リストから削除しました。<br>';
    }else{
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);

  open (my $FH, '+<', $set::passfile) or error('IDファイルのオープンに失敗しました。');
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    if(index($_, "$::in{id}<") == 0){
      $message .= 'IDを削除しました。<br>';
    } else {
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);

  if (unlink "${dataDir}${fileDir}/image.png") { $message .= '画像(png)を削除しました。<br>'; }
  if (unlink "${dataDir}${fileDir}/image.jpg") { $message .= '画像(jpg)を削除しました。<br>'; }
  if (unlink "${dataDir}${fileDir}/image.gif") { $message .= '画像(gif)を削除しました。<br>'; }
  if (unlink "${dataDir}${fileDir}/image.webp"){ $message .= '画像(webp)を削除しました。<br>'; }

  if($set::del_back){
    if (unlink "${dataDir}${fileDir}/data.cgi")  { $message .= '最新データを削除しました。<br>'; }
    if (unlink "${dataDir}${fileDir}/logs.cgi")  { $message .= '過去ログデータを削除しました。<br>'; }
    if (unlink "${dataDir}${fileDir}/log-list.cgi")  { $message .= '過去ログ一覧を削除しました。<br>'; }
  }
  
  if(rmdir "${dataDir}${fileDir}"){ $message .= 'ディレクトリを削除しました。<br>シートを完全に削除しました。<br>'; }
  else {
    if (!-d "${dataDir}deleted"){ mkdir "${dataDir}deleted" or error("削除データのバックアップディレクトリの作成に失敗しました。"); }
    if(rename("${dataDir}${fileDir}", "${dataDir}deleted/${user}_${file}")){
       $message .= 'シートを削除しました。<br>';
    }
  }
  
  info('キャラクターシートの削除',$message);
}
## 画像削除
elsif($mode eq 'img-delete'){
  # 画像差し替え
  if($set::beheaded){
    use File::Copy 'copy';
    if (unlink "${dataDir}${fileDir}/image.png") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.png", "${dataDir}${fileDir}/image.png"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
    if (unlink "${dataDir}${fileDir}/image.jpg") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.jpg", "${dataDir}${fileDir}/image.jpg"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
    if (unlink "${dataDir}${fileDir}/image.gif") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.gif", "${dataDir}${fileDir}/image.gif"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
    if (unlink "${dataDir}${fileDir}/image.webp") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.webp", "${dataDir}${fileDir}/image.webp"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
  }
  # 消すだけ
  else {
    if (unlink "${dataDir}${fileDir}/image.png") { $message .= 'キャラクター画像を削除しました。<br>'; }
    if (unlink "${dataDir}${fileDir}/image.jpg") { $message .= 'キャラクター画像を削除しました。<br>'; }
    if (unlink "${dataDir}${fileDir}/image.gif") { $message .= 'キャラクター画像を削除しました。<br>'; }
    if (unlink "${dataDir}${fileDir}/image.webp") { $message .= 'キャラクター画像を削除しました。<br>'; }
  }
  $message .= '<a href="./?id='.$::in{id}.'">キャラクターシートを確認</a>';
  
  
  sysopen (my $FH, $::core_dir.'/data/delete.cgi', O_WRONLY | O_APPEND | O_CREAT, 0666) or $message .= 'デリートリストが開けませんでした。';
    if($user){ print $FH "$sheet_id<>$user<>$file<>image<>".time."<>\n"; }
    else { print $FH "$sheet_id<>-----<>$file<>image<>".time."<>\n"; }
  close ($FH);
  
  info('画像の削除',$message);
}
1;