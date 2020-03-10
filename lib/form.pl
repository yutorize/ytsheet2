################## フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;
if($LOGIN_ID && param('mode') =~ /register|login/){ print "Location: ./\n\n"; }

my $token = random_id(12);

my $mask = umask 0;
if(param('mode') eq 'register'){
  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
  print $FH $token."<>".(time + 60*60*24)."<>\n";
  close($FH);
}
if(param('mode') eq 'reset'){
  $token = param('code');
}

### テンプレート読み込み #############################################################################
my $INDEX = HTML::Template->new( filename => $set::skin_tmpl, utf8 => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1);

$INDEX->param(modeRegister => 1) if param('mode') eq 'register';
$INDEX->param(modeLogin => 1) if param('mode') eq 'login';
$INDEX->param(modeReminder => 1) if param('mode') eq 'reminder';
$INDEX->param(modeReset => 1) if param('mode') eq 'reset';
$INDEX->param(modeOption => 1) if param('mode') eq 'option';
$INDEX->param(modeOption => 1) if param('mode') eq 'passchange';

if(param('mode') eq 'option' || param('mode') eq 'passchange'){
  $INDEX->param(setMessage => $main::set_message);
  $INDEX->param(userName => (getplayername($LOGIN_ID))[0]);
  $INDEX->param(userMail => (getplayername($LOGIN_ID))[1]);
}

$INDEX->param(LOGIN_ID => $LOGIN_ID);

$INDEX->param(token => $token);
$INDEX->param(registerkey => 1) if $set::registerkey;

$INDEX->param(title => $set::title);
$INDEX->param(ver => $main::ver);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;