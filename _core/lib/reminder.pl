################### リマインダ ###################
use strict;
#use warnings;
use utf8;
use open ":utf8";


if($::in{mail}){
  open (my $READ, '<', $set::userfile) or error('ユーザー一覧のオープンに失敗しました。//reminder'.__LINE__);
  my @list = <$READ>;
  close($READ);

  my @hit_id;
  foreach(@list){
    my($id, $pass, $name, $mail) = (split /<>/, $_)[0..3];
    if($mail eq $::in{mail}){
      push(@hit_id, $id);
    }
  }
  if(!@hit_id){ error('入力したメールアドレスは登録されていません。'); }

  &sendmail($::in{mail}, $set::title." : ID-Reminder", "このメールアドレスで登録されているIDは\n".join("\n",@hit_id)."\nです。");

  info('送信完了','入力されたメールアドレスにIDを送信しました。');
}
elsif($::in{id}){
  my $token = random_id(12);
  sysopen (my $WRITE, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT);
  print $WRITE $::in{id}.'-'.$token."<>".(time + 60*60*1)."<>\n";
  close($WRITE);

  open (my $READ, '<', $set::userfile) or error('ユーザー一覧のオープンに失敗しました。//reminder'.__LINE__);
  my @list = <$READ>;
  close($READ);

  my $in_mail;
  foreach(@list){
    my($id, $pass, $name, $mail) = (split /<>/, $_)[0..3];
    if($id eq $::in{id}){
      $in_mail = $mail;
    }
  }

  if(!$in_mail){ error('存在しないIDか、メールアドレスが設定されていないIDです。'); }

  &sendmail($in_mail, $set::title." : PasswordReset", "パスワードを再設定します。\n下記のURLにアクセスしてください。\n\n".url()."?mode=reset&code=".$::in{id}.'-'.$token."\n\nパスワードを再設定したくない場合、このメッセージは無視してください。");

  info('送信完了','登録されたメールアドレスにパスワードリセット用URLを送信しました。');
}
elsif($::in{password}){
  if(!token_check($::in{code})){ error('URLの有効期限が過ぎています。'); }

  if($::in{password} ne $::in{password_confirm}){ error('パスワードの確認入力が一致しません'); }
  if ($::in{password} eq ''){ error('パスワードが入力されていません'); }
  else {
    if ($::in{password} =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }
  
  my $id = (split(/-/, $::in{code}))[0];
  
  my $flag;
  overwriteFile($set::userfile, sub {
    my ($READ, $WRITE) = @_;
    foreach (<$READ>){
      if(index($_, "$id<") == 0){
        $flag = 1;
        my @data = split(/<>/, $_, -1);
        @data[1] = encrypt($::in{password});
        print $WRITE join('<>', @data);
      }
      else {
        print $WRITE $_;
      }
    }
  });
  
  if(!$flag){ error('IDが存在しません。'); }
  
  info('再設定完了','パスワードの変更が完了しました。');
}

1;