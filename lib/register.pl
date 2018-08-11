################## PLデータ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use Encode;

my $mask = umask 0;

my $mode = param('mode');
my $id = param('id');

if($mode eq 'register'){
  if(!token_check(param('_token'))){ error('セッションの有効期限が切れたか、二重投稿です'); }

  if(param('password') ne param('password_confirm')){ error('パスワードの確認入力が一致しません'); }
  if (param('password') eq ''){ error('パスワードが入力されていません'); }
  else {
    if (param('password') =~ /[^0-9A-Za-z\.\-\/]/) { error('パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです'); }
  }

  open (my $FH, '<', $set::userfile);
  while (<$FH>){ 
    if ($_ =~ /^$id<>/){ error('そのIDは使用されています'); }
  }
  close ($FH);

  sysopen (my $FH, $set::userfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
    print $FH param('id')."<>".&e_crypt(param('password'))."<>".Encode::decode('utf8', param('name'))."<>".param('mail')."<>\n";
  close ($FH);

  log_in(param('id'),param('password'));
}
if($mode eq 'option'){
  my $LOGIN_ID = check;
  
  sysopen (my $FH, $set::userfile, O_RDWR);
  my @list = <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
  foreach (@list){
    my @data= split /<>/;
    if ($data[0] eq $LOGIN_ID){
      print $FH "$data[0]<>$data[1]<>".Encode::decode('utf8', param('name'))."<>".param('mail')."<>\n";
    }else{
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
  
  our $set_message = '変更を保存しました。';
  require $set::lib_form;
}
1;