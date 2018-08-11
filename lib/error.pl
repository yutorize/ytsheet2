################## フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use HTML::Template;

my $LOGIN_ID = check;

### テンプレート読み込み ##################################################
#my $template = HTML::Template->new(filename => "template.html", utf8 => 1,);
my $INDEX;
open (my $FH, "<:utf8", $set::skin_tmpl ) or die "Couldn't open template file: $!\n";
$INDEX = HTML::Template->new( filehandle => *$FH , die_on_bad_params => 0, case_sensitive => 1);
close($FH);

$INDEX->param(modeError => 1);

$INDEX->param(LOGIN_ID => $LOGIN_ID);

$INDEX->param(errorMessage => $main::error_message);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $main::ver);

### 出力 ##################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;