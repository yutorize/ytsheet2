use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use Fcntl qw(:flock);
require "$FindBin::Bin/../_core/lib/sw2/making-log.pl";

sub fixture {
  my ($count, %options) = @_;
  my $dir = tempdir(CLEANUP => 1);
  my $log = YtSheet::MakingLog->new(file => "$dir/makelist.cgi", keep => 5, unit => 5, %options);
  my @lines = map { row($_) } reverse 1 .. $count;
  $log->_write_file($log->{file}, \@lines);
  return $log;
}
sub row {
  my ($num, %options) = @_;
  return join('<>', $num, 1800000000, $options{id} // 'user-'.($num % 3),
    $options{name} // '作成者', $options{comment} // '#共通 ＃日本語 #a.b',
    $options{race} // '人間', '7,7,7,6,6,6,6,6,6,/', '')."<>\n";
}
sub numbers { return [map { YtSheet::MakingLog::_number($_) } @{$_[0]{lines}}]; }
sub post_args {
  return (id => 'new-user', name => '新規作成者', race => '人間', comment => '#新規',
    stt => '7,7,7,6,6,6,6,6,6,/', now => 1800000010, @_);
}

subtest 'default size rotates without changing old rows or numbers' => sub {
  my $log = fixture(1999, keep => 1000, unit => 1000);
  is($log->post(post_args()), 2000, 'number continues');
  is(scalar @{$log->_read_current}, 1000, 'current size');
  is(scalar @{$log->_archives}, 1, 'one archive');
  is_deeply(numbers($log->search(items => 3000)), [reverse 1 .. 2000], 'all numbers');
  is($log->search(num => 1)->{lines}[0], row(1), 'oldest row unchanged');
  is($log->search(num => 1999)->{lines}[0], row(1999), 'recent row unchanged');
};
subtest 'pagination crosses files and uses lookahead' => sub {
  my $log = fixture(25);
  is($log->archive, 20, 'initial migration');
  is_deeply(numbers($log->search()), [reverse 16 .. 25], 'first page');
  ok($log->search()->{has_next}, 'has next');
  is_deeply(numbers($log->search(page => 1)), [reverse 6 .. 15], 'second page');
  is_deeply(numbers($log->search(page => 2)), [reverse 1 .. 5], 'final partial page');
  ok(!$log->search(page => 2)->{has_next}, 'no next');
  is_deeply(numbers($log->search(page => 3)), [], 'out of range');
  is($log->archive, 0, 'migration is idempotent');
  my $exact = fixture(20); $exact->archive;
  ok(!$exact->search(page => 1)->{has_next}, 'exact final ten');
};
subtest 'filters and number lookup include all archives' => sub {
  my $log = fixture(30); $log->archive;
  my $expected = [28,25,22,19,16,13,10,7,4,1];
  is_deeply(numbers($log->search(id => 'user-1', tag => '日本語')), $expected, 'ID and fullwidth tag');
  is_deeply(numbers($log->search(id => 'user-1', tag => 'a.b')), $expected, 'literal tag');
  is_deeply(numbers($log->search(tag => 'aXb')), [], 'not regex');
  is_deeply(numbers($log->search(tag => '共')), [], 'whole tag');
  is_deeply(numbers($log->search(num => 2, page => 500)), [2], 'number ignores page');
  is_deeply(numbers($log->search(num => 2, id => 'user-1')), [], 'number keeps filter');
  is_deeply(numbers($log->search(num => 999)), [], 'absent number');
  my $oldest = $log->_archives->[-1]{file};
  unlink $oldest or die $!; symlink "$oldest.missing", $oldest or die $!;
  is_deeply(numbers($log->search(num => 12)), [12], 'skip unrelated archive');
  is_deeply(numbers($log->search()), [reverse 21 .. 30], 'stop at eleventh match');
};
subtest 'disabled rotation and legacy maximum' => sub {
  my $zero = fixture(2, keep => '000', unit => '000'); is($zero->archive, 0, 'zero strings');
  my $log = fixture(20, keep => 0, unit => 0);
  is($log->archive, 0, 'disabled'); is($log->post(post_args()), 21, 'posting works');
  is(scalar @{$log->_read_current}, 21, 'all retained');
  my $limited = fixture(20, max => 3);
  is($limited->post(post_args()), 21, 'limited numbering');
  is_deeply(numbers($limited->search()), [21,20,19], 'legacy deletion');
  is(scalar @{$limited->_archives}, 0, 'no archives');
  my $one = fixture(1, max => 1); $one->post(post_args());
  is_deeply(numbers($one->search()), [2], 'limit one');
};
subtest 'interval includes recently archived rows' => sub {
  my $log = fixture(4, keep => 2, unit => 2);
  $log->_write_file($log->{file}, [row(4), row(3), row(2, id => 'target'), row(1)]);
  $log->archive;
  my $ok = eval { $log->post(post_args(id => 'target', name => '作成者', interval => 60)); 1 };
  ok(!$ok, 'rejected'); like($@, qr/^429:/, 'rate-limit error');
  is_deeply(numbers($log->search()), [4,3,2,1], 'no mutation');
  is($log->post(post_args(id => 'target', name => '作成者', interval => 60, now => 1800000061)), 5, 'expired interval');
};
subtest 'interrupted rotation is searchable and retryable' => sub {
  my $log = fixture(8, keep => 2, unit => 2);
  my $write = \&YtSheet::MakingLog::_write_file;
  {
    no warnings 'redefine';
    local *YtSheet::MakingLog::_write_file = sub {
      die "simulated current failure\n" if $_[1] eq $_[0]{file}; return $write->(@_);
    };
    ok(!eval { $log->post(post_args()); 1 }, 'failure after archives');
  }
  is(scalar @{$log->_read_current}, 8, 'source retained');
  is(scalar @{$log->_archives}, 3, 'archives saved');
  is_deeply(numbers($log->search(items => 50)), [reverse 1 .. 8], 'deduplicated');
  is($log->post(post_args()), 9, 'retry number');
  is(scalar @{$log->_archives}, 3, 'reuse archives');
  is_deeply(numbers($log->search(items => 50)), [reverse 1 .. 9], 'complete history');
};
subtest 'archive failures and conflicts preserve the current file' => sub {
  my $log = fixture(8, keep => 2, unit => 2); my $before = $log->_read_current;
  {
    no warnings 'redefine';
    local *YtSheet::MakingLog::_write_file = sub { die "archive failure\n" };
    ok(!eval { $log->archive; 1 }, 'save failure');
  }
  is_deeply($log->_read_current, $before, 'source retained');
  $log->_write_file("$log->{archive_dir}/makelist-0000000001-0000000002.cgi", [row(2, comment => '#different'), row(1)]);
  ok(!eval { $log->archive; 1 }, 'conflicting content'); like($@, qr/^500:/, 'server error');
  is_deeply($log->_read_current, $before, 'conflict keeps source');
};
subtest 'changed chunk size cannot overlap interrupted archives' => sub {
  my $log = fixture(8, keep => 2, unit => 2); mkdir $log->{archive_dir} or die $!;
  $log->_write_file("$log->{archive_dir}/makelist-0000000001-0000000002.cgi", [row(2), row(1)]);
  $log->{unit} = 3; ok(!eval { $log->archive; 1 }, 'reject overlap');
  is(scalar @{$log->_archives}, 1, 'no overlapping file');
  is_deeply(numbers($log->search(items => 50)), [reverse 1 .. 8], 'history searchable');
  $log->{unit} = 2; is($log->archive, 6, 'resume with original unit');
};
subtest 'failed replacement cleans up temporary files' => sub {
  my $log = fixture(2); my $blocked = "$log->{file}.directory"; mkdir $blocked or die $!;
  ok(!eval { $log->_write_file($blocked, [row(1)]); 1 }, 'rename failure');
  like($@, qr/^500:/, 'error reported');
  is_deeply(numbers($log->search()), [2,1], 'source unchanged');
  opendir my $dir, File::Basename::dirname($log->{file}) or die $!;
  my @temps = grep { /^tmp_making_/ } readdir $dir; closedir $dir;
  is_deeply(\@temps, [], 'temporary cleaned up');
};
subtest 'temporary creation failure is sanitized and preserves source' => sub {
  plan skip_all => 'requires unprivileged POSIX user' if $> == 0 || $^O eq 'MSWin32';
  my $log = fixture(2, keep => 0, unit => 0); my $before = $log->_read_current;
  $log->_with_lock(LOCK_EX, sub { 1 });
  my $dir = File::Basename::dirname($log->{file}); my $mode = (stat($dir))[2] & 0777;
  chmod(0555, $dir) or die $!;
  my $ok = eval { $log->post(post_args()); 1 }; my $error = $@;
  chmod($mode, $dir) or die $!;
  ok(!$ok, 'creation fails'); like($error, qr/^500:/, 'status prefix');
  unlike($error, qr/\Q$dir\E/, 'no internal path');
  is_deeply($log->_read_current, $before, 'original intact');
  is($log->post(post_args()), 3, 'retry same number');
};
subtest 'snapshot survives concurrent rotation' => sub {
  my $log = fixture(9); my $snapshot = $log->_snapshot; $log->post(post_args());
  my @before; $log->_visit($snapshot, undef, sub { push @before, $_[0]; 1 });
  is_deeply(numbers({lines => \@before}), [reverse 1 .. 9], 'old snapshot');
  is_deeply(numbers($log->search()), [reverse 1 .. 10], 'new snapshot');
};
subtest 'invalid source and missing current file cannot lose data' => sub {
  my $log = fixture(8, keep => 2, unit => 2);
  my @rows = (row(8), row(6), row(7), map { row($_) } reverse 1 .. 5);
  $log->_write_file($log->{file}, \@rows);
  ok(!eval { $log->archive; 1 }, 'unsorted rejected'); is_deeply($log->_read_current, \@rows, 'source intact');
  my $archived = fixture(10); $archived->archive; unlink $archived->{file} or die $!;
  ok(!eval { $archived->post(post_args()); 1 }, 'no restart over existing archives');
};
subtest 'concurrent writers serialize numbering' => sub {
  my $log = fixture(8, keep => 2, unit => 2); my @children;
  foreach (1 .. 6) {
    my $pid = fork(); die 'fork failed' unless defined $pid;
    if (!$pid) { my $ok = eval { $log->post(post_args()); 1 }; require POSIX; POSIX::_exit($ok ? 0 : 1); }
    push @children, $pid;
  }
  foreach my $pid (@children) { waitpid($pid, 0); is($?, 0, 'writer succeeded'); }
  is_deeply(numbers($log->search(items => 50)), [reverse 1 .. 14], 'all unique');
};
subtest 'migration CLI creates no new post' => sub {
  my $log = fixture(12);
  open my $pipe, '-|', $^X, "$FindBin::Bin/../tools/archive-making.pl", $log->{file}, 2, 2 or die $!;
  my $output = do { local $/; <$pipe> }; close $pipe;
  is($?, 0, 'CLI succeeds'); like($output, qr/10 /, 'moved count');
  is_deeply(numbers($log->search(items => 50)), [reverse 1 .. 12], 'all retained');
  is(scalar @{$log->_read_current}, 2, 'current size');
};
done_testing;
