package YtSheet::MakingLog;
use strict;
use warnings;
use utf8;
use open ':utf8';
use Fcntl qw(:DEFAULT :flock);
use Errno qw(ENOENT);
use File::Basename qw(dirname);
use File::Temp qw(tempfile);

sub newMakingLog {
  my ($class, %args) = @_;
  foreach my $key (qw(keep unit max)) {
    $args{$key} = 0 unless defined $args{$key};
    ::error("500:能力値作成ログの設定が不正です。\n") unless $args{$key} =~ /^[0-9]+$/;
    $args{$key} = 0 + $args{$key};
  }
  ::error("500:過去ログの保存件数と分割単位は両方とも正数、または両方とも0にしてください。\n")
    if !!$args{keep} != !!$args{unit};
  $args{archive_dir} = $args{file}.'.archive';
  return bless \%args, $class;
}

# 既存のoverwriteFileと同じロックを使う。検索ではスナップショット取得中だけ共有ロックする。
# ロック中の例外は捕捉し、解放してから既存のerror()で表示する。
sub withMakingLogLock {
  my ($self, $mode, $code) = @_;
  sysopen my $lock, $self->{file}.'.lock', O_RDWR | O_CREAT
    or ::error("500:能力値作成ログのロックファイルを開けません。\n");
  flock($lock, $mode) or ::error("500:能力値作成ログをロックできません。\n");
  my $result = eval { $code->() };
  my $error = $@;
  close($lock) or $error ||= "500:能力値作成ログのロックを解放できません。\n";
  ::error($error) if $error;
  return $result;
}

sub readCurrentMakingLog {
  my ($self) = @_;
  my $fh;
  unless (open $fh, '<', $self->{file}) {
    return [] if $! == ENOENT;
    die "500:能力値作成ログを開けません。\n";
  }
  local $! = 0;
  my @lines = <$fh>;
  die "500:能力値作成ログを読み込めません。\n" if $!;
  close($fh) or die "500:能力値作成ログを読み込めません。\n";
  return \@lines;
}

sub getMakingPostNumber {
  my ($line) = @_;
  my ($num) = $line =~ /^([0-9]+)<>/;
  die "500:能力値作成ログの投稿番号が不正です。\n" unless defined($num) && $num > 0;
  return 0 + $num;
}

# 呼び出し元が排他ロックを保持する。差し替え前のファイルは失敗時も残す。
# eval内のdieで後片付けへ進み、withMakingLogLock()でロックを解放してからerror()を呼ぶ。
sub writeMakingLogFile {
  my ($self, $file, $lines) = @_;
  my ($fh, $tmp) = eval {
    tempfile('tmp_making_XXXXXXXX', DIR => dirname($file), UNLINK => 0);
  };
  die "500:能力値作成ログの一時ファイルを作成できません。\n" if $@;
  my $ok = eval {
    binmode($fh, ':utf8') or die "500:能力値作成ログの文字コードを設定できません。\n";
    my $mode = -e $file ? ((stat($file))[2] & 0777) : (0666 & ~umask);
    chmod($mode, $tmp) or die "500:能力値作成ログの属性を設定できません。\n";
    print {$fh} @$lines or die "500:能力値作成ログを書き込めません。\n";
    close($fh) or die "500:能力値作成ログの保存に失敗しました。\n";
    rename($tmp, $file) or die "500:能力値作成ログを置き換えられません。\n";
    1;
  };
  unless ($ok) {
    my $error = $@;
    close($fh) if defined fileno($fh);
    unlink $tmp;
    die $error;
  }
}

# 過去ログは作成後に更新・削除しない。ファイル名の番号を数値で比較する。
sub listMakingLogArchives {
  my ($self) = @_;
  my $dir;
  unless (opendir $dir, $self->{archive_dir}) {
    return [] if $! == ENOENT;
    die "500:能力値作成の過去ログ一覧を開けません。\n";
  }
  my @files;
  while (my $name = readdir $dir) {
    next unless $name =~ /^makelist-([0-9]+)-([0-9]+)\.cgi$/;
    my ($low, $high) = (0 + $1, 0 + $2);
    die "500:能力値作成の過去ログ範囲が不正です。\n" unless $low > 0 && $low <= $high;
    push @files, { file => "$self->{archive_dir}/$name", low => $low, high => $high };
  }
  closedir($dir) or die "500:能力値作成の過去ログ一覧を読み込めません。\n";
  @files = sort { $b->{high} <=> $a->{high} } @files;
  foreach my $i (1 .. $#files) {
    die "500:能力値作成の過去ログ範囲が重複しています。\n"
      if $files[$i]{high} >= $files[$i-1]{low};
  }
  return \@files;
}

sub rotateMakingLogs {
  my ($self, $lines) = @_;
  return if $self->{max} || !$self->{keep} || @$lines < $self->{keep} + $self->{unit};
  my $previous;
  foreach my $line (@$lines) {
    my $num = getMakingPostNumber($line);
    die "500:能力値作成ログが投稿番号の降順になっていません。\n"
      if defined($previous) && $num >= $previous;
    $previous = $num;
  }
  mkdir($self->{archive_dir}) or die "500:能力値作成の過去ログ保存先を作れません。\n"
    unless -d $self->{archive_dir};
  my $archives = $self->listMakingLogArchives;
  while (@$lines >= $self->{keep} + $self->{unit}) {
    # 必ず最古のブロックから保存する。中断時も同じ範囲・同じ内容で再試行できる。
    my @chunk = splice(@$lines, -$self->{unit});
    my ($low, $high) = (getMakingPostNumber($chunk[-1]), getMakingPostNumber($chunk[0]));
    my $file = sprintf('%s/makelist-%010d-%010d.cgi', $self->{archive_dir}, $low, $high);
    foreach my $archive (@$archives) {
      next if $archive->{high} < $low || $archive->{low} > $high;
      die "500:退避途中の過去ログと範囲が重複します。分割単位を元に戻して再試行してください。\n"
        unless $archive->{file} eq $file;
    }
    if (-e $file) {
      open my $fh, '<', $file or die "500:退避済みの能力値作成ログを開けません。\n";
      local $! = 0;
      my @saved = <$fh>;
      die "500:退避済みの能力値作成ログを読み込めません。\n" if $!;
      close($fh) or die "500:退避済みの能力値作成ログを読み込めません。\n";
      die "500:退避済みの能力値作成ログと内容が一致しません。\n"
        unless join('', @saved) eq join('', @chunk);
    }
    else {
      $self->writeMakingLogFile($file, \@chunk);
    }
  }
}

# 初回移行用。新規投稿なしで、既存ログだけを分割する。
sub archiveMakingLogs {
  my ($self) = @_;
  return $self->withMakingLogLock(LOCK_EX, sub {
    my $lines = $self->readCurrentMakingLog;
    my $before = @$lines;
    $self->rotateMakingLogs($lines);
    $self->writeMakingLogFile($self->{file}, $lines) if @$lines != $before;
    return $before - @$lines;
  });
}

sub checkMakingPostInterval {
  my ($self, $lines, $post) = @_;
  return unless $post->{interval};
  my $check = sub {
    my ($line) = @_;
    my ($num, $date, $id, $name, $comment, $race) = split /<>/, $line;
    die "500:能力値作成ログの日付が不正です。\n" unless defined($date) && $date =~ /^[0-9]+$/;
    return 0 if $post->{now} - $date > $post->{interval};
    die "429:$post->{interval}秒以内の連続投稿は禁止されています。\n"
      if $post->{id} eq $id && $post->{name} eq $name && $post->{race} eq $race;
    return 1;
  };
  foreach my $line (@$lines) { return unless $check->($line); }
  # 現行の末尾も制限時間内なら、直前の過去ログにさかのぼる。
  foreach my $archive (@{$self->listMakingLogArchives}) {
    open my $fh, '<', $archive->{file} or die "500:能力値作成の過去ログを開けません。\n";
    my $stop = 0;
    while (1) {
      local $! = 0;
      my $line = <$fh>;
      die "500:能力値作成の過去ログを読み込めません。\n" if !defined($line) && $!;
      last unless defined $line;
      unless ($check->($line)) { $stop = 1; last; }
    }
    close($fh) or die "500:能力値作成の過去ログを読み込めません。\n";
    return if $stop;
  }
}

sub saveMakingPost {
  my ($self, %post) = @_;
  return $self->withMakingLogLock(LOCK_EX, sub {
    $post{now} = time unless defined $post{now};
    my $lines = $self->readCurrentMakingLog;
    die "500:過去ログがあるため、空の現行ログから採番できません。\n"
      if !@$lines && @{$self->listMakingLogArchives};
    $self->checkMakingPostInterval($lines, \%post);
    my $num = @$lines ? getMakingPostNumber($lines->[0]) + 1 : 1;
    # making_maxが正数の場合は従来の保存上限を優先し、自動退避しない。
    splice(@$lines, $self->{max} - 1) if $self->{max} && @$lines >= $self->{max};
    unshift @$lines, join('<>', $num, $post{now}, map { $post{$_} // '' }
      qw(id name comment race stt curse))."<>\n";
    $self->rotateMakingLogs($lines);
    $self->writeMakingLogFile($self->{file}, $lines);
    return $num;
  });
}

sub getMakingLogSnapshot {
  my ($self) = @_;
  return $self->withMakingLogLock(LOCK_SH, sub {
    return { lines => $self->readCurrentMakingLog, archives => $self->listMakingLogArchives };
  });
}

sub visitMakingLogLines {
  my ($self, $snapshot, $num, $code) = @_;
  my $archives = $snapshot->{archives};
  my $archived_max = @$archives ? $archives->[0]{high} : 0;
  foreach my $line (@{$snapshot->{lines}}) {
    my $current = getMakingPostNumber($line);
    # 退避成功後・現行更新前の中断では最古側が重複する。過去ログ側を正として一度だけ読む。
    next if $current <= $archived_max;
    next if $num && $current != $num;
    return unless $code->($line);
  }
  foreach my $archive (@$archives) {
    next if $num && ($num < $archive->{low} || $num > $archive->{high});
    open my $fh, '<', $archive->{file} or ::error("500:能力値作成の過去ログを開けません。\n");
    my $stop = 0;
    while (1) {
      local $! = 0;
      my $line = <$fh>;
      ::error("500:能力値作成の過去ログを読み込めません。\n") if !defined($line) && $!;
      last unless defined $line;
      next if $num && getMakingPostNumber($line) != $num;
      unless ($code->($line)) { $stop = 1; last; }
    }
    close($fh) or ::error("500:能力値作成の過去ログを読み込めません。\n");
    return if $stop;
  }
}

sub searchMakingPosts {
  my ($self, %query) = @_;
  my $items = $query{items} || 10;
  my $offset = ($query{page} || 0) * $items;
  my $tag = defined $query{tag} ? qr/^(?:[^<]*<>){4}[^<]*?[#＃]\Q$query{tag}\E(\s|[#＃]|<)/ : undef;
  my (@lines, $matched, $has_next);
  $matched = $has_next = 0;
  $self->visitMakingLogLines($self->getMakingLogSnapshot, $query{num}, sub {
    my ($line) = @_;
    return 1 if defined($query{id}) && $line !~ /^(?:[^<]*<>){2}\Q$query{id}\E</;
    return 1 if defined($tag) && $line !~ $tag;
    return 1 if !$query{num} && $matched++ < $offset;
    if (@lines == $items) { $has_next = 1; return 0; }
    push @lines, $line;
    return $query{num} ? 0 : 1;
  });
  return { lines => \@lines, has_next => $has_next };
}

1;
