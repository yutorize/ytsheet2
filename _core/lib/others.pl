################## その他の処理 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

my $mode = $::in{'mode'};

### バックアップ命名 #################################################################################
if($mode eq 'bu-naming'){
  my $type = $::in{'type'};
  my $id   = $::in{'id'};
  my $date = $::in{'date'};
  my $name = decode('utf8',$::in{'backp-name'});
  my $pass = $::in{'pass'};

  ## パスワードチェック
  (undef, undef, my $file, undef, my $user) = getfile($id,$pass,$LOGIN_ID);
  if(!$file){ error('パスワードが間違っているか、編集権限がありません。'); }

  ## 保存
  my $data_dir = ($type eq 'm') ? $set::mons_dir : ($type eq 'i') ? $set::item_dir : $set::char_dir;
  $file = $user ? '_'.$user.'/'.$file : $file;

  sysopen (my $FH, "${data_dir}${file}/buname.cgi", O_RDWR | O_CREAT, 0666);
  flock($FH, 2);
  my @list = sort { (split(/<>/,$b))[0] cmp (split(/<>/,$a))[0] } <$FH>;
  seek($FH, 0, 0);
  print $FH "$date<>$name\n";
  foreach (@list){
    chomp $_;
    my( $_date, undef ) = split /<>/;
    if ($date ne $_date){
      print $FH $_,"\n";
    }
  }
  truncate($FH, tell($FH));
  close($FH);

  ## キャラシートへ移動／編集画面に戻る
  print "Location: ./?id=${id}&backup=${date}\n\n";
}


1;