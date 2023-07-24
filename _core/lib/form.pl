################## フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $mode = $::in{mode};
my $LOGIN_ID = check;
if($LOGIN_ID && $mode =~ /register|login/){ print "Location: ./\n\n"; }

my $token = random_id(12);

my $mask = umask 0;
if($mode eq 'register'){
  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
  print $FH $token."<>".(time + 60*60*24)."<>\n";
  close($FH);
}
if($mode eq 'reset'){
  $token = $::in{code};
}

### テンプレート読み込み #############################################################################
my $INDEX = HTML::Template->new( filename => $set::skin_tmpl, utf8 => 1,
  path => ['./', $::core_dir],
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1);

$INDEX->param(modeRegister => 1) if $mode eq 'register';
$INDEX->param(modeLogin    => 1) if $mode eq 'login';
$INDEX->param(modeReminder => 1) if $mode eq 'reminder';
$INDEX->param(modeReset    => 1) if $mode eq 'reset';
$INDEX->param(modeOption   => 1) if $mode eq 'option';
$INDEX->param(modeOption   => 1) if $mode eq 'passchange';
$INDEX->param(modeConvert  => 1) if $mode eq 'convertform';

if($mode eq 'option' || $mode eq 'passchange'){
  $INDEX->param(setMessage => $main::set_message);
  $INDEX->param(userName => (getplayername($LOGIN_ID))[0]);
  $INDEX->param(userMail => (getplayername($LOGIN_ID))[1]);
}
if($mode eq 'convertform'){
  my @urls;
  foreach (keys %set::convert_url){
    push(@urls, { URL => $_ });
  }
  $INDEX->param(ConvertURLs => \@urls);
}

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(token => $token);
$INDEX->param(registerkey => 1) if $set::registerkey;

$INDEX->param(title => $set::title);
$INDEX->param(ver => $main::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;