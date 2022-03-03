################### データ削除 ###################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = check;
my $mode = $::in{'mode'};
my $message;

my $data_dir; my $data_list;
   if($::in{'type'} eq 'm'){ $data_dir = $set::mons_dir; $data_list = $set::monslist; }
elsif($::in{'type'} eq 'i'){ $data_dir = $set::item_dir; $data_list = $set::itemlist; }
else                       { $data_dir = $set::char_dir; $data_list = $set::listfile; }

if(!$::in{'id'}){ error('IDがありません。'); }
if(!$::in{'check1'} || !$::in{'check2'} || !$::in{'check3'}){ error('確認のチェックが入っていません。'); }

my ($sheet_id, $sheet_user, $file, $user);
($sheet_id, undef, $file, undef, $user) = getfile($::in{'id'},$::in{'pass'},$LOGIN_ID);
if(!$file){ error('データが見つかりません。'); }
my $file_dir = $user ? '_'.$user.'/'.$file : $file;

## キャラシ削除
if($mode eq 'delete'){
  open (my $FH, "+<", $data_list) or error('一覧ファイルのオープンに失敗しました。');
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    if(index($_, "$::in{'id'}<") == 0){
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
    if(index($_, "$::in{'id'}<") == 0){
      $message .= 'IDを削除しました。<br>';
    } else {
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);

  if (unlink "${data_dir}${file_dir}/data.cgi")  { $message .= 'キャラクターデータを削除しました。<br>'; }
  if (unlink "${data_dir}${file_dir}/image.png") { $message .= 'キャラクター画像を削除しました。<br>'; }
  if (unlink "${data_dir}${file_dir}/image.jpg") { $message .= 'キャラクター画像を削除しました。<br>'; }
  if (unlink "${data_dir}${file_dir}/image.gif") { $message .= 'キャラクター画像を削除しました。<br>'; }
  if (unlink "${data_dir}${file_dir}/image.webp") { $message .= 'キャラクター画像を削除しました。<br>'; }

  if($set::del_back){
    my $dir = "${data_dir}${file_dir}/backup/";
    opendir (my $DIR, $dir);
    my @files = grep { !m/^(\.|\.\.)$/g } readdir $DIR;
    close ($DIR);
    my $flag = @files;
    if ($flag) {
      foreach (@files) {
        unlink "$dir$_";
      }
    }
    if(rmdir $dir){ print 'バックアップを削除しました。<br>'; }
    #else { print 'バックアップフォルダ'.$dir.'の削除に失敗しました。<br>'; }
  }
  
  if(rmdir "${data_dir}${file_dir}"){ $message .= 'ディレクトリを削除しました。<br>'; }
  else {
    if (!-d "${data_dir}deleted"){ mkdir "${data_dir}deleted" or error("削除データのバックアップディレクトリの作成に失敗しました。"); }
    rename("${data_dir}${file_dir}", "${data_dir}deleted/${user}_${file}");
  }
  
  info('キャラクターシートの削除',$message);
}
## 画像削除
elsif($mode eq 'img-delete'){
  # 画像差し替え
  if($set::beheaded){
    use File::Copy 'copy';
    if (unlink "${data_dir}${file_dir}/image.png") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.png", "${data_dir}${file_dir}/image.png"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
    if (unlink "${data_dir}${file_dir}/image.jpg") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.jpg", "${data_dir}${file_dir}/image.jpg"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
    if (unlink "${data_dir}${file_dir}/image.gif") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.gif", "${data_dir}${file_dir}/image.gif"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
    if (unlink "${data_dir}${file_dir}/image.webp") {
      $message .= 'キャラクター画像を削除しました。<br>';
      if(copy "${set::beheaded}.webp", "${data_dir}${file_dir}/image.webp"){
        $message .= '差し替え画像を設定しました。<br>';
      }
    }
  }
  # 消すだけ
  else {
    if (unlink "${data_dir}${file_dir}/image.png") { $message .= 'キャラクター画像を削除しました。<br>'; }
    if (unlink "${data_dir}${file_dir}/image.jpg") { $message .= 'キャラクター画像を削除しました。<br>'; }
    if (unlink "${data_dir}${file_dir}/image.gif") { $message .= 'キャラクター画像を削除しました。<br>'; }
    if (unlink "${data_dir}${file_dir}/image.webp") { $message .= 'キャラクター画像を削除しました。<br>'; }
  }
  $message .= '<a href="./?id='.$::in{'id'}.'">キャラクターシートを確認</a>';
  
  
  sysopen (my $FH, $::core_dir.'/data/delete.cgi', O_WRONLY | O_APPEND | O_CREAT, 0666) or $message .= 'デリートリストが開けませんでした。';
    if($user){ print $FH "$sheet_id<>$user<>$file<>image<>".time."<>\n"; }
    else { print $FH "$sheet_id<>-----<>$file<>image<>".time."<>\n"; }
  close ($FH);
  
  info('画像の削除',$message);
}
1;