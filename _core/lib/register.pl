################## PLデータ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $mode = $::in{mode};

if($mode eq 'register'){
  if(!token_check($::in{_token})){ error('セッションの有効期限が切れたか、二重投稿です'); }

  if($set::registerkey && $set::registerkey ne $::in{registerkey}){ error('登録キーが間違っています。'); }
  if($::in{password} ne $::in{password_confirm}){ error('パスワードの確認入力が一致しません'); }
  if ($::in{password} eq ''){ error('パスワードが入力されていません'); }
  else {
    if ($::in{password} =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }

  open (my $READ, '<', $set::userfile);
  while (my $line = <$READ>){
    if(index($line, "$::in{id}<") == 0){ error('そのIDは使用されています'); }
  }
  close ($READ);

  appendFile($set::userfile, sub {
    my ($WRITE) = @_;
    print $WRITE $::in{id}."<>".&encrypt($::in{password})."<>".decode('utf8', $::in{name})."<>".$::in{mail}."<>".time."<>\n";
  });
  
  if($set::player_dir){
    if (!-d $set::player_dir.$::in{id}){ mkdir $set::player_dir.$::in{id}; }
    sysopen (my $FH, $set::player_dir.$::in{id}.'/data.cgi', O_WRONLY | O_APPEND | O_CREAT);
      print $FH "id<>".$::in{id}."\n";
      print $FH "name<>".decode('utf8',$::in{name})."\n";
    close ($FH);
  }

  log_in($::in{id},$::in{password});
}
elsif($mode eq 'option'){
  my $LOGIN_ID = check;

  overwriteFile($set::userfile, sub {
    my ($READ, $WRITE) = @_;
    foreach (<$READ>){
      if(index($_, "$LOGIN_ID<") == 0){
        my @data = split(/<>/, $_, -1);
        @data[2] = decode('utf8', $::in{name});
        @data[3] = $::in{mail};
        print $WRITE join('<>', @data);
      }
      else {
        print $WRITE $_;
      }
    }
  });
  
  our $set_message = '変更を保存しました。';
  require $set::lib_form;
}
elsif($mode eq 'passchange'){
  my $LOGIN_ID = check;

  if($::in{new_password} ne $::in{new_password_confirm}){ error('パスワードの確認入力が一致しません'); }
  if ($::in{password} eq ''){ error('パスワードが入力されていません'); }
  if ($::in{new_password} eq ''){ error('新しいパスワードが入力されていません'); }
  else {
    if ($::in{new_password} =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }
  
  my $flag;
  overwriteFile($set::userfile, sub {
    my ($READ, $WRITE) = @_;
    foreach (<$READ>){
      if(index($_, "$LOGIN_ID<") == 0){
        my @data = split(/<>/, $_, -1);
        if (verifyCrypt($::in{password},$data[1])){
          @data[1] = encrypt($::in{new_password});
          print $WRITE join('<>', @data);
          $flag = 1;
          next;
        }
      }
      print $WRITE $_;
    }
  });
  
  if(!$flag){ error('パスワードが間違っています'); }
  
  our $set_message = '変更を保存しました。';
  require $set::lib_form;
}
1;