################### データ削除 ###################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = check;

my $message;

my $data_dir; my $data_list;
   if(param('type') eq 'm'){ $data_dir = $set::mons_dir; $data_list = $set::monslist; }
elsif(param('type') eq 'i'){ $data_dir = $set::item_dir; $data_list = $set::itemlist; }
else                       { $data_dir = $set::char_dir; $data_list = $set::listfile; }

if(!param('id')){ error('IDがありません。'); }
if(!param('check1') || !param('check2') || !param('check3')){ error('確認のチェックが入っていません。'); }

my $file;
(undef, undef, $file, undef) = getfile(param('id'),param('pass'),$LOGIN_ID);
if(!$file){ error('データが見つかりません。'); }

open (my $FH, "+<", $data_list) or error('一覧ファイルのオープンに失敗しました。');
my @list = <$FH>;
flock($FH, 2);
seek($FH, 0, 0);
foreach (@list){
  my($id, undef) = split /<>/;
  if (param('id') eq $id){
    $message .= 'リストから削除しました。<br>';
  }else{
    print $FH $_;
  }
}
truncate($FH, tell($FH));
close($FH);

open (my $FH, '+<', $set::passfile) or error('IDファイルのオープンに失敗しました。');
my @list = <$FH>;
flock($FH, 2);
seek($FH, 0, 0);
foreach (@list){
  my($id, undef) = split /<>/;
  if (param('id') eq $id){
    $message .= 'IDを削除しました。<br>';
  } else {
    print $FH $_;
  }
}
truncate($FH, tell($FH));
close($FH);

if (unlink "${data_dir}${file}/data.cgi")  { $message .= 'キャラクターデータを削除しました。<br>'; }
if (unlink "${data_dir}${file}/image.png") { $message .= 'キャラクター画像を削除しました。<br>'; }
if (unlink "${data_dir}${file}/image.jpg") { $message .= 'キャラクター画像を削除しました。<br>'; }
if (unlink "${data_dir}${file}/image.gif") { $message .= 'キャラクター画像を削除しました。<br>'; }

if($set::del_back){
  my $dir = "${data_dir}${file}/backup/";
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

if(rmdir "${data_dir}${file}"){ $message .= 'ディレクトリを削除しました。<br>'; }
else { rename("${data_dir}${file}", "${data_dir}del-${file}") }

info('キャラクターシートの削除',$message);

1;