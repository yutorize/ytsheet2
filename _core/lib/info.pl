################## インフォメーション ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

### テンプレート読み込み #############################################################################
my $INDEX = HTML::Template->new( filename => $set::skin_tmpl, utf8 => 1,
  path => ['./', $::core_dir],
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1);

$INDEX->param(modeInfo => 1);

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(header => $main::header);
$INDEX->param(message => $main::message);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $main::ver);
$INDEX->param(coreDir => $main::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;