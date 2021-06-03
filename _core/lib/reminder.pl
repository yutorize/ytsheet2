################### リマインダ ###################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $mask = umask 0;


if($::in{'mail'}){

  open (my $FH, '<', $set::userfile) or &error('一覧データのオープンに失敗しました。');
  my @list = <$FH>;
  close($FH);

  my @hit_id;
  foreach(@list){
    my($id, $pass, $name, $mail) = (split /<>/, $_)[0..3];
    if($mail eq $::in{'mail'}){
      push(@hit_id, $id);
    }
  }
  if(!@hit_id){ error('入力したメールアドレスは登録されていません。'); }

  &sendmail($::in{'mail'}, $set::title." : ID-Reminder", "このメールアドレスで登録されているIDは\n".join("\n",@hit_id)."\nです。");

  info('送信完了','入力されたメールアドレスにIDを送信しました。');
}
elsif($::in{'id'}){
  my $token = random_id(12);
  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
  print $FH $::in{'id'}.'-'.$token."<>".(time + 60*60*1)."<>\n";
  close($FH);

  open (my $FH, '<', $set::userfile) or &error('一覧データのオープンに失敗しました。');
  my @list = <$FH>;
  close($FH);

  my $in_mail;
  foreach(@list){
    my($id, $pass, $name, $mail) = (split /<>/, $_)[0..3];
    if($id eq $::in{'id'}){
      $in_mail = $mail;
    }
  }

  if(!$in_mail){ error('存在しないIDです。'); }

  &sendmail($in_mail, $set::title." : PasswordReset", "パスワードを再設定します。\n下記のURLにアクセスしてください。\n\n".url()."?mode=reset&code=".$::in{'id'}.'-'.$token."\n\nパスワードを再設定したくない場合、このメッセージは無視してください。");

  info('送信完了','登録されたメールアドレスにパスワードリセット用URLを送信しました。');
}
elsif($::in{'password'}){
  if(!token_check($::in{'code'})){ error('URLの有効期限が過ぎています。'); }

  if($::in{'password'} ne $::in{'password_confirm'}){ error('パスワードの確認入力が一致しません'); }
  if ($::in{'password'} eq ''){ error('パスワードが入力されていません'); }
  else {
    if ($::in{'password'} =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }
  
  my $id = (split(/-/, $::in{'code'}))[0];
  
  my $flag;
  sysopen (my $FH, $set::userfile, O_RDWR);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    my @data= split /<>/;
    if ($data[0] eq $id){
      print $FH "$data[0]<>".e_crypt($::in{'password'})."<>$data[2]<>$data[3]<>\n";
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