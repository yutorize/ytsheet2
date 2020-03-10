################### リマインダ ###################
#use strict;
#use warnings;
use utf8;
use open ":utf8";

my $mask = umask 0;

if(param('id')){
  my $token = random_id(12);
  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
  print $FH param('id').'-'.$token."<>".(time + 60*60*1)."<>\n";
  close($FH);

  open (my $FH, '<', $set::userfile) or &error('一覧データのオープンに失敗しました。');
  my @list = <$FH>;
  close($FH);

  my $in_mail;
  foreach(@list){
    my($id, $pass, $name, $mail) = (split /<>/, $_)[0..3];
    if($id eq param('id')){
      $in_mail = $mail;
    }
  }

  if(!$in_mail){ error('存在しないIDです。'); }

  &sendmail($in_mail, $set::title." : PasswordReset", "パスワードを再設定します。\n下記のURLにアクセスしてください。\n\n".url()."?mode=reset&code=".param('id').'-'.$token."\n\nパスワードを再設定したくない場合、このメッセージは無視してください。");

  info('送信完了','登録されたメールアドレスにパスワードリセット用URLを送信しました。');
}
elsif(param('password')){
  if(!token_check(param('code'))){ error('URLの有効期限が過ぎています。'); }

  if(param('password') ne param('password_confirm')){ error('パスワードの確認入力が一致しません'); }
  if (param('password') eq ''){ error('パスワードが入力されていません'); }
  else {
    if (param('password') =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }
  
  my $id = (split(/-/, param('code')))[0];
  
  my $flag;
  sysopen (my $FH, $set::userfile, O_RDWR);
  my @list = <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
  foreach (@list){
    my @data= split /<>/;
    if ($data[0] eq $id){
      print $FH "$data[0]<>".e_crypt(param('password'))."<>$data[2]<>$data[3]<>\n";
      $flag = 1;
    }else{
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
  
  if(!$flag){ error('IDが存在しません。'); }
  
  info('再設定完了','パスワードの変更が完了しました。');
}
1;