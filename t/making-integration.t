use strict;
use warnings;
no warnings 'once';
use utf8;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use Encode qw(encode decode);
use CGI ();
use lib "$FindBin::Bin/../_core/module";

# CGIの入力・認証・最終出力を代替し、実際の設定・データ・テンプレートを使う。
our $core_dir = abs_path("$FindBin::Bin/../_core");
our (%in, $LOGIN_ID, $SW2_0, $ver);
my %params;
sub check { return 'user-1'; }
sub param { return @_ ? $params{$_[0]} : keys %params; }
sub error { die $_[0]."\n"; }
sub isInteger { return defined($_[0]) && $_[0] =~ /^-?[0-9]+$/; }
sub getPlayerName { return '作成者'; }
sub url { return 'https://example.invalid/sw2.5/'; }
sub outputTemplate { return $_[0]->output; }
sub escapeThanSign { my $text = shift; $text =~ s/</&lt;/g; $text =~ s/>/&gt;/g; return $text; }
sub uri_escape_utf8 {
  my $text = encode('utf8', $_[0]);
  $text =~ s/([^A-Za-z0-9_.~-])/sprintf('%%%02X', ord($1))/eg;
  return $text;
}

require "$core_dir/lib/sw2/config-default.pl";
require "$core_dir/lib/sw2/making-log.pl";
my $dir = tempdir(CLEANUP => 1);
$set::makelist = "$dir/makelist.cgi";
$set::making_archive_keep = $set::making_archive_unit = 5;
$ver = 'test';
my $log = YtSheet::MakingLog->new(file => $set::makelist, keep => 5, unit => 5);
my @rows = map {
  join('<>', $_, 1800000000, 'user-'.($_ % 2), '過去の作成者', '#過去 ＃検索', '人間',
    '7,7,7,6,6,6,6,6,6,/7,7,7,8,8,8,8,8,8,/', '')."<>\n"
} reverse 1 .. 19;
$log->_write_file($set::makelist, \@rows);

sub run_controller {
  my ($file, %args) = @_;
  %params = map { $_ => encode('utf8', $args{$_}) } keys %args;
  %in = %params;
  my $output = '';
  open my $capture, '>', \$output or die $!;
  binmode $capture, ':utf8';
  local *STDOUT = $capture;
  my $result = do "$core_dir/lib/sw2/$file";
  die $@ if $@;
  die "controller failed: $!" unless defined $result;
  close($capture) or die $!;
  return decode('utf8', $output);
}

my $redirect = run_controller('making.pl', mode => 'making', make => 1,
  name => '<新規作成者>', race => '人間', tec => 7, phy => 7, spi => 7, repeat => 3,
  comment => '#新規 ＃検索');
like($redirect, qr/Location:\.\/\?mode=making&num=20\n\n/, 'redirect unchanged');
is(scalar @{$log->_read_current}, 5, 'controller rotates');
is(scalar @{$log->_archives}, 3, 'three blocks');
like($log->search(num => 20)->{lines}[0], qr/&lt;新規作成者&gt;/, 'escaping retained');

my $html = run_controller('list-making.pl', mode => 'making', page => 0);
my @numbers = $html =~ /\[#([0-9]+)\]/g;
is_deeply(\@numbers, [reverse 11 .. 20], 'first page');
like($html, qr/次の10件/, 'next link');
$html = run_controller('list-making.pl', mode => 'making', page => 1);
@numbers = $html =~ /\[#([0-9]+)\]/g;
is_deeply(\@numbers, [reverse 1 .. 10], 'final page');
unlike($html, qr/次の10件/, 'no next link');
$html = run_controller('list-making.pl', mode => 'making', num => '2-2');
@numbers = $html =~ /\[#([0-9]+)\]/g;
is_deeply(\@numbers, [2], 'archived num-trial');
like($html, qr/<table class="selected">/, 'selected trial');
like($html, qr/making_num=2-2/, 'new-sheet link');
$html = run_controller('list-making.pl', mode => 'making', tag => '＃過去');
@numbers = $html =~ /\[#([0-9]+)\]/g;
is_deeply(\@numbers, [reverse 10 .. 19], 'Japanese tag');
like($html, qr/能力値作成履歴/, 'making template');
$html = run_controller('list-making.pl', mode => 'making', mylist => 1, id => 'user-0', tag => '検索');
@numbers = $html =~ /\[#([0-9]+)\]/g;
is_deeply(\@numbers, [20,19,17,15,13,11,9,7,5,3], 'mylist priority and tag');
like($html, qr/次の10件/, 'filtered next');
$html = run_controller('list-making.pl', mode => 'making', mylist => 1, tag => '検索', page => 1);
@numbers = $html =~ /\[#([0-9]+)\]/g;
is_deeply(\@numbers, [1], 'oldest filtered result');
unlike($html, qr/次の10件/, 'filtered no next');

subtest 'temporary-file errors render HTTP 500 using real info.pl' => sub {
  my $failure;
  {
    no warnings 'redefine';
    local *YtSheet::MakingLog::tempfile = sub {
      die "Error in tempfile() using template $dir/tmp_making_PRIVATE: Permission denied\n";
    };
    eval {
      run_controller('making.pl', mode => 'making', make => 1,
        name => '作成者', race => '人間', tec => 7, phy => 7, spi => 7, repeat => 1);
    };
    $failure = $@;
  }
  ok($failure, 'failure reported');
  local $main::message = $failure;
  local $main::header = 'エラー';
  local $main::isError = 1;
  local %main::statusCode = (500 => '500 Internal Server Error');
  my $output = '';
  {
    open my $capture, '>:utf8', \$output or die $!;
    local *STDOUT = $capture;
    my $result = do "$core_dir/lib/info.pl";
    die $@ if $@;
    die "error template failed: $!" unless defined $result;
    close($capture) or die $!;
  }
  my $response = decode('utf8', $output);
  like($response, qr/^Status: 500 Internal Server Error\n/, 'HTTP 500');
  like($response, qr/一時ファイルを作成できません/, 'user message');
  unlike($response, qr/\Q$dir\E|Error in tempfile/, 'no internal details');
  is(scalar @{$log->search(items => 30)->{lines}}, 20, 'history unchanged');
};
done_testing;
