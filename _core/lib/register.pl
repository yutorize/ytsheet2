################## PLデータ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $mask = umask 0;

my $mode = $::in{'mode'};

if($mode eq 'register'){
  if(!token_check($::in{'_token'})){ error('セッションの有効期限が切れたか、二重投稿です'); }

  if($set::registerkey && $set::registerkey ne $::in{'registerkey'}){ error('登録キーが間違っています。'); }
  if($::in{'password'} ne $::in{'password_confirm'}){ error('パスワードの確認入力が一致しません'); }
  if ($::in{'password'} eq ''){ error('パスワードが入力されていません'); }
  else {
    if ($::in{'password'} =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }

  open (my $FH, '<', $set::userfile);
  while (my $line = <$FH>){
    if(index($line, "$::in{'id'}<") == 0){ error('そのIDは使用されています'); }
  }
  close ($FH);

  sysopen (my $FH, $set::userfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
    print $FH $::in{'id'}."<>".&e_crypt($::in{'password'})."<>".decode('utf8', $::in{'name'})."<>".$::in{'mail'}."<>".time."<>\n";
  close ($FH);
  
  if($set::player_dir){
    if (!-d $set::player_dir.$::in{'id'}){ mkdir $set::player_dir.$::in{'id'}; }
    sysopen (my $FH, $set::player_dir.$::in{'id'}.'/data.cgi', O_WRONLY | O_APPEND | O_CREAT, 0666);
      print $FH "id<>".$::in{'id'}."\n";
      print $FH "name<>".decode('utf8',$::in{'name'})."\n";
    close ($FH);
  }

  log_in($::in{'id'},$::in{'password'});
}
elsif($mode eq 'option'){
  my $LOGIN_ID = check;
  
  sysopen (my $FH, $set::userfile, O_RDWR);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach my $line (@list){
    if(index($line, "$LOGIN_ID<") == 0){
      my @data= split(/<>/, $line);
      print $FH "$data[0]<>$data[1]<>".decode('utf8', $::in{'name'})."<>".$::in{'mail'}."<>\n";
    }else{
      print $FH $line;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
  
  our $set_message = '変更を保存しました。';
  require $set::lib_form;
}
elsif($mode eq 'passchange'){
  my $LOGIN_ID = check;

  if($::in{'new_password'} ne $::in{'new_password_confirm'}){ error('パスワードの確認入力が一致しません'); }
  if ($::in{'password'} eq ''){ error('パスワードが入力されていません'); }
  if ($::in{'new_password'} eq ''){ error('新しいパスワードが入力されていません'); }
  else {
    if ($::in{'new_password'} =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }
  
  my $flag;
  sysopen (my $FH, $set::userfile, O_RDWR);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    my @data= split /<>/;
    if ($data[0] eq $LOGIN_ID && c_crypt($::in{'password'},$data[1])){
      print $FH "$data[0]<>".e_crypt($::in{'new_password'})."<>$data[2]<>$data[3]<>\n";
      $flag = 1;
    }else{
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
  
  if(!$flag){ error('パスワードが間違っています'); }
  
  our $set_message = '変更を保存しました。';
  require $set::lib_form;
}
1;