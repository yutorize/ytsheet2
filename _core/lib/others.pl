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
  my $name = pcEscape( decode('utf8',$::in{'log-name'}) );

  ## パスワードチェック
  (undef, undef, my $file, my $type, my $user) = getfile($id,$pass,$LOGIN_ID);
  if(!$file){ error('パスワードが間違っているか、編集権限がありません。'); }
  changeFileByType($type);

  ## ディレクトリ
  my $fileDir = $set::char_dir .($user ? "_${user}/${file}" : $file);

  ## 読込
  sysopen (my $FH, "${fileDir}/log-list.cgi", O_RDWR) or error('ログ一覧が開けません。'.$fileDir);
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


1;