use strict;
use warnings;
no warnings qw(once uninitialized);
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../_core/module";
use Cwd qw(abs_path);
use CGI qw(url);
use URI::Escape qw(uri_escape_utf8);
use POSIX qw(ceil);
use Encode qw(decode);
use JSON::PP;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use HTML::Template;

# 一覧本体・共通処理・テンプレートを、認証と登録データだけ置き換えて実行する。
my $case = decode_json($ARGV[0]);
my %listTypes = (ar2e => 'guild', dx3 => 'unit', gc => 'country', ms => 'clan');
my %typeIds = (ar2e => 'g', dx3 => 'u', gc => 'c', ms => 'c');
my $game = $case->{game};
die 'Unsupported game' unless exists $listTypes{$game};
die 'Unsupported enemy list' if $case->{enemy} && $game ne 'dx3';
my $kind = $case->{enemy} ? 'enemy' : $case->{character} ? 'chara' : $listTypes{$game};
my $typeId = $case->{enemy} ? 'e' : $case->{character} ? '' : $typeIds{$game};
our $core_dir = abs_path("$FindBin::Bin/../../_core");
our (%in, $ver);
$ver = 'test';
require "$core_dir/lib/$game/config-default.pl";
require "$core_dir/lib/subroutine.pl";
{
  no warnings 'redefine';
  *check = sub { $case->{guest} ? '' : 'tester' };
}

my $scratch = tempdir(CLEANUP => 1);
make_path("$scratch/skin-add");
open(my $message, '>:encoding(UTF-8)', "$scratch/skin-add/index-message.html") or die $!;
print $message 'TEST_INDEX_MESSAGE';
close $message;
chdir $scratch or die $!;
$ENV{SCRIPT_NAME} = "/$game/index.cgi";
$ENV{SERVER_NAME} = 'localhost';
$ENV{SERVER_PORT} = '80';
$ENV{REQUEST_METHOD} = 'GET';
delete $ENV{HTML_TEMPLATE_ROOT};

my @records = (
  ['A1', 'pc',     'Alice', 0, ' demo ', 1],
  ['A2', 'pc',     'Alice', 0, '',       0],
  ['B1', 'npc',    'Bob',   0, ' demo ', 1],
  ['B2', 'npc',    'Bob',   0, '',       0],
  ['L1', 'legacy', 'Carol', 0, '',       1],
  ['E1', '',       'Eve',   0, '',       0],
  ['H1', 'pc',     'Hide',  1, ' demo ', 1],
  ['H2', 'npc',    'Hide',  1, '',       0],
);
@records = () if $case->{empty};
open(my $list, '>:encoding(UTF-8)', "$scratch/list.cgi") or die $!;
open(my $pass, '>:encoding(UTF-8)', "$scratch/pass.cgi") or die $!;
my $i = 0;
for my $record (@records) {
  my ($id, $group, $player, $hide, $tags, $image) = @$record;
  $group = $group eq 'npc' ? 'beta' : 'alpha' if $case->{customRows};
  $group = $case->{storedGroups}{$id} if exists $case->{storedGroups} && exists $case->{storedGroups}{$id};
  my @fields = ($id, '', '', 1_700_000_000 + $i, "Name-$id", $player, $group);
  ++$i;
  if ($kind eq 'unit') {
    push @fields, $tags, $hide, $i % 2 ? 'unit' : 'company', 'Leader';
  }
  else {
    push @fields, $image, $tags, $hide;
    if ($kind eq 'enemy') {
      my @syndromes = ('Angel//', 'Angel/Balor/', 'Angel/Balor/Chimera');
      push @fields, $i % 2 ? 'Mエネミー(T)' : 'エネミー',
        $i % 2 ? 'Stage A' : 'Stage B', $syndromes[($i-1) % 3],
        100 + $i, $i, 10, 80;
    }
    elsif ($game eq 'ar2e') { push @fields, '', 'Master', $i; }
    elsif ($game eq 'gc') { push @fields, 'Lord', $i, 'Counts', 'Peerage', ''; }
    else { push @fields, '', $i, 'Base', 'Belong', 'Rule', 'Leader', '', '', '', ''; }
  }
  print $list join('<>', @fields), "<>\n";
  print $pass "$id<>[tester]<>unused<>\n" if $id eq 'A1' || $id eq 'B1' || $id eq 'H1';
}
close $list;
close $pass;
$set::listfile = "$scratch/list.cgi";
$set::passfile = "$scratch/pass.cgi";
$set::skin_tmpl = "$core_dir/skin/$game/index.html";
$set::pagemax = $case->{pagemax} // 0;
$set::list_maxline = $case->{listMaxline} // 0;
$set::simplelist = $case->{simplelist} // 0;
$set::simpleindex = $case->{simpleindex} // 0;
$set::playerlist = $case->{playerlist} // 1;
$set::masterid = $case->{admin} ? 'tester' : '';
$set::group_default = $case->{defaultGroup} if exists $case->{defaultGroup};
@set::groups = @{$case->{baseGroupSettings}} if exists $case->{baseGroupSettings};
if (exists $case->{groupSettings}) {
  no strict 'refs';
  @{"set::groups_$listTypes{$game}"} = @{$case->{groupSettings}};
}
%in = (type => $typeId, %{$case->{query} || {}});

my $template;
my $originalNew = HTML::Template->can('new');
{
  no warnings 'redefine';
  *HTML::Template::new = sub { $template = $originalNew->(@_); return $template; };
}
my $html;
{
  open(my $capture, '>:encoding(UTF-8)', \$html) or die $!;
  local *STDOUT = $capture;
  require "$core_dir/lib/$game/list-$kind.pl";
}
$html = decode('UTF-8', $html);
my @groups = map { +{
  id => $_->{ID}, name => $_->{NAME}, text => $_->{TEXT}, count => $_->{NUM}, players => $_->{'NUM-PL'},
  rows => [map { $_->{ID} } @{$_->{Lines}}],
  rowGroups => [map { $_->{GROUP} } @{$_->{Lines}}],
  pager => $_->{PAGER}, more => $_->{MORE},
} } @{$template->param('Lists') || []};
my ($optionsHtml) = $html =~ /(<select name="group">.*?<\/select>)/s;
my ($indexHtml) = $html =~ /(<ul class="grouplist">.*?<\/ul>)/s;
my %result = (
  group => $in{group}, groups => \@groups,
  options => $template->param('Groups'), optionsHtml => $optionsHtml,
  indexGroups => $template->param('IndexGroups'), indexHtml => $indexHtml,
  canonicalURL => $template->param('canonicalURL'),
  searchSummary => $template->param('searchSummary'),
  indexMessage => index($html, 'TEST_INDEX_MESSAGE') >= 0 ? 1 : 0,
);
for my $key (qw(modeIndex modeMylist simpleList simpleIndex)) {
  $result{$key} = $template->param($key) ? 1 : 0;
}
if ($case->{enemy}) {
  $result{enemyLines} = [map { @{$_->{Lines}} } @{$template->param('Lists') || []}];
  $result{enemyHtml} = $html;
}
binmode STDOUT, ':raw';
print JSON::PP->new->utf8->canonical->encode(\%result), "\n";
