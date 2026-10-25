################## キャラクターからエネミーへの移行 ##################
use strict;
use utf8;
use open ':utf8';
use CGI ();
use Cwd qw(abs_path);
use Encode qw(encode decode FB_CROAK LEAVE_SRC);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempfile tempdir);
use Fcntl qw(:DEFAULT :flock);

sub migrateEnemyRequest {
  error('405:POSTで実行してください。') unless CGI::request_method() eq 'POST';
  error('400:移行の確認欄にチェックしてください。') unless ($::in{confirm_migrate} // '') eq '1';
  my $login = check();
  error('401:ログインしていません。') if $set::user_reqd && !$login;
  my $pass = eval { decode('UTF-8', $::in{pass} // '', FB_CROAK | LEAVE_SRC) };
  error('400:パスワードの文字コードが不正です。') if $@;
  error('403:実行確認が無効または期限切れです。編集画面を開き直してください。')
    unless $::in{_token} && checkToken($::in{_token}, 'migrate-enemy:'.$::in{id}.':'.join(':', getCookie()));
  my $ok = eval { migrateEnemySheet($::in{id}, $pass, $login); 1; };
  error($@ || '500:移行に失敗しました。') unless $ok;
  print "Location: ./?id=" . uri_escape_utf8($::in{id}) . "\n\n";
}

my ($dx3CharaCalculator, $dx3EnemyCalculator);
sub dx3MigrationCalculators {
  return if $dx3EnemyCalculator;
  # 両ファイルとも同名のdataCalcを定義するため、各コード参照を保持する。
  require $set::lib_calc_char;
  $dx3CharaCalculator = \&::dataCalc;
  require $set::lib_type{e}{calc};
  $dx3EnemyCalculator = \&::dataCalc;
}

sub dx3MigrationParseRecord {
  my ($text, $id) = @_;
  my %pc;
  foreach my $line (split /\n/, $text) {
    $line =~ s/\r\z//;
    next if $line eq '';
    my ($key, $value) = split /<>/, $line, 2;
    error('400:保存済みデータの形式が不正です。') if !length($key) || !defined($value) || exists $pc{$key};
    $pc{$key} = CGI::unescapeHTML($value);
  }
  error('409:保存済みデータとIDが一致しません。') unless ($pc{id} // '') eq $id;
  error('400:作成日時が不正です。') unless ($pc{birthTime} // '') =~ /\A[0-9]+\z/;
  return \%pc;
}

sub dx3MigrationConvertRecord {
  my ($text, $id, $file, $now, $latest) = @_;
  my $pc = dx3MigrationParseRecord($text, $id);
  dx3MigrationCalculators();
  local $::mode_save = 0;
  # 旧形式のコンボ値はアップグレードの入力なので、変換後まで削除しない。
  delete $pc->{$_} foreach grep { /^skillTotal/ } keys %$pc;
  my %chara = $dx3CharaCalculator->($pc);
  my %enemy;
  foreach my $key (keys %chara) {
    if ($key =~ /\A(?:id|birthTime|updateTime|protect|forbidden|hide|stage|tags|mainImage|freeNote|nameFont|namePlate|nameColor|encroachEaOn|encroachOrOn)\z/
      || $key =~ /\A(?:effect|combo|weapon|armor|vehicle|item|skill|syndrome|sttSyn|image|words|color|palette|chatPalette|unitStatus)/) {
      $enemy{$key} = $chara{$key};
    }
  }
  # 名前のルビはルビ記法に変換する
  {
    my $name = $chara{characterName} // '';
    my $aka  = $chara{aka} // '';
    if($name && $chara{characterNameRuby}){ $name = "｜${name}《$chara{characterNameRuby}》" }
    if($aka  && $chara{akaRuby}          ){ $aka  = "｜${aka}《$chara{akaRuby}》" }
    $enemy{enemyName} = ($aka ? "“${aka}”" : '') . $name;
    $enemy{enemyName} ||= '無題';
  }
  # 専用欄のないプロフィールは定義リスト、ロイスは表組みで既存メモの後ろへ残す。
  my $definition = sub {
    my ($label, $value) = @_;
    # 値の改行は説明欄の継続行にする。行頭の文字が別の記法として解釈されるのも防ぐ。
    $value =~ s/<br>|\r\n?|\n/\n:|/gi;
    return ":$label|$value";
  };
  my $tableCell = sub {
    my $value = shift // '';
    $value =~ s/\|/&#124;/g;
    # セル内の改行には既存の行継続記法を使い、コメント記号が行頭に来るのも防ぐ。
    $value =~ s/<br>|\r\n?|\n/\\\\\n /gi;
    # 先頭の空白で見出し・セル結合・書式指定を避け、末尾の空セルも列として残す。
    return ' '.$value;
  };
  my @profile;
  foreach my $field (
    [age => '年齢'], [gender => '性別'], [sign => '星座'],
    [height => '身長'], [weight => '体重'], [blood => '血液型'],
    [works => 'ワークス'], [cover => 'カヴァー'],
  ) {
    my ($key, $label) = @$field;
    push @profile, $definition->($label, $chara{$key}) if defined($chara{$key}) && $chara{$key} =~ /\S/;
  }
  foreach my $field (
    [Origin => '出自'], [Experience => '経験'], [Encounter => '邂逅／欲望'],
    [Awaken => '覚醒'], [Impulse => '衝動'],
  ) {
    my ($key, $label) = @$field;
    my $value = $chara{'lifepath'.$key} // '';
    my $note = $chara{'lifepath'.$key.'Note'} // '';
    if ($value =~ /\S/) {
      push @profile, $definition->($label, $value . ($note =~ /\S/ ? " ／ 備考：$note" : ''));
    } elsif ($note =~ /\S/) { push @profile, $definition->("${label}の備考", $note); }
  }
  my @lois;
  foreach my $num (1..7) {
    my @values;
    foreach my $key (qw(Relation Name EmoPosi EmoNega Color Note)) {
      my $value = $chara{"lois${num}$key"} // '';
      $value = '○'.$value if $key =~ /\AEmo/ && $chara{"lois${num}${key}Check"};
      push @values, $value;
    }
    # Eロイスは名称と備考をエフェクト欄にも追加する。既存のエフェクトは維持する。
    if ($values[0] =~ /[EＥ]ロイス|\A\s*[EＥ]\s*\z/i && ($values[1] =~ /\S/ || $values[5] =~ /\S/)) {
      my $effect = ++$enemy{effectNum};
      $enemy{"effect${effect}Type"} = 'elois';
      $enemy{"effect${effect}Name"} = $values[1];
      $enemy{"effect${effect}Note"} = $values[5];
    }
    my $superior = $chara{"lois${num}S"} ? 'Sロイス' : '';
    my $state = $chara{"lois${num}State"} // '';
    # 空行にも保存される初期状態「ロイス」だけでは、メモに行を作らない。
    next unless (grep { /\S/ } @values) || $superior || ($state =~ /\S/ && $state ne 'ロイス');
    my @row = ( $num, @values[0..4], $state, join('／', grep { length($_) } $superior,$values[5]) );
    push @lois, '|' . join('|', map { $tableCell->($_) } @row) . '|';
  }
  my @notes;
  push @notes, "**プロフィール\n" . join("\n", @profile) if @profile;
  push @notes, "**ロイス\n|~ |~関係|~名前|~感情P|~感情N|~属性|~状態|~備考|h\n" . join("\n", @lois) if @lois;
  $enemy{freeNote} = join("\n\n", grep { defined($_) && $_ ne '' } ($enemy{freeNote}, @notes)) if @notes;
  $enemy{type} = 'e';
  $enemy{enemyType} = '一般';
  $enemy{author} = $chara{playerName};
  foreach my $name (qw(Body Sense Mind Social)) { $enemy{'stt'.$name} = $chara{'sttTotal'.$name} // 0; }
  $enemy{maxHp} = $chara{maxHpTotal};
  $enemy{initiative} = $chara{initiativeTotal};
  # エネミー側で直接編集できる侵蝕率欄に、固定値も含めて移す。
  $enemy{encroach} = $chara{encroachFixed} ? ($chara{encroachFixedValue} || 0) : $chara{baseEncroach};
  $enemy{armor} = $chara{armorTotal} // '';
  foreach my $key (grep { /^skillTotal/ } keys %chara) {
    (my $target = $key) =~ s/^skillTotal/skill/;
    $enemy{$target} = $chara{$key};
  }
  # 補正を含む合計を技能値として渡すので、補正欄を残すとコンボに二重加算される。
  delete $enemy{$_} foreach grep { /^skillAdd/ || /^combo[0-9]+(?:Dice|Fixed)[1-5]$/ } keys %enemy;
  $enemy{encroachOrOn} ||= scalar grep { ($chara{"lois${_}Name"} // '') =~ /起源種|オリジナルレネゲイド/ } 1..7;
  $enemy{updateTime} = epocToDate($now) if $latest;
  $enemy{ver} = $::ver;
  local $::mode_save = 1;
  local $::file = $file;
  local $::now = $now;
  local $::updatedLine;
  local *::setUpdatatLineImage = sub {
    my ($data) = @_;
    return join(',', map {
      my $s = imageSuffix($_);
      $data->{"image$s"} && !$data->{"imageHide$s"}
        ? ($_.($data->{"imageSpoiler$s"} ? escapeThanSign('+'.$data->{"imageSpoiler$s"}) : '')) : ()
    } 1..($set::image_maxcount || 1));
  };
  %enemy = $dx3EnemyCalculator->(\%enemy);
  my $result = join('', map { defined($enemy{$_}) && $enemy{$_} ne '' ? "$_<>$enemy{$_}\n" : '' } sort keys %enemy);
  return ($result, $::updatedLine);
}

sub dx3MigrationReadRaw {
  my $path = shift;
  open(my $in, '<:raw', $path) or error("500:ファイルを読み込めません。（$path）");
  my $text = do { local $/; <$in> };
  close($in) or error("500:ファイルを閉じられません。（$path）");
  return $text // '';
}

sub dx3MigrationTemp {
  my ($path, $raw) = @_;
  # 書込・復元のeval内から使うため、失敗はexitせず例外として呼出元へ返す。
  my ($out, $temp) = tempfile('tmp_migrate_XXXXXXXX', DIR => dirname($path), UNLINK => 0);
  binmode $out, ':raw';
  my $ok = print $out $raw;
  $ok = close($out) && $ok;
  if (!$ok) { unlink $temp; die "500:移行用の一時ファイルを保存できません。\n"; }
  if (-f $path) {
    chmod((stat($path))[2] & 0777, $temp) or do { unlink $temp; die "500:ファイルの権限を設定できません。\n"; };
  }
  return $temp;
}

sub dx3MigrationIndexLocks {
  my @paths = @_;
  my @locks;
  foreach my $path (sort @paths) {
    sysopen(my $lock, "$path.lock", O_RDWR | O_CREAT) or error('500:一覧をロックできません。');
    push @locks, $lock;
  }
  # 管理者の一覧修復も複数台帳をロックする。取得できなければ全て解放して再試行する。
  foreach (1..500) {
    my @held;
    foreach my $lock (@locks) {
      last unless flock($lock, LOCK_EX | LOCK_NB);
      push @held, $lock;
    }
    return \@locks if @held == @locks;
    flock($_, LOCK_UN) foreach @held;
    select undef, undef, undef, 0.02;
  }
  error('409:一覧を更新中です。しばらくしてから再度実行してください。');
}

sub migrateEnemySheet {
  my ($id, $pass, $login) = @_;
  error('400:DX3rdのキャラクターを指定してください。') unless $set::game eq 'dx3' && $set::lib_type{e};
  error('400:IDがありません。') unless defined($id) && length($id);
  error('401:ログインしていません。') if $set::user_reqd && !$login;
  my ($file, $type, $user, $sheetLock) = authSheetForUpdate($id, $pass, $login);
  error('403:シートが存在しないか、編集権限がありません。') unless $file;
  error('409:キャラクターシートだけを移行できます。') if $type;
  error('400:保存先の形式が不正です。') unless $file =~ /\A[0-9]+\z/ && (!defined($user) || $user =~ /\A[0-9A-Za-z_-]+\z/);
  my $relative = ($user ? "_${user}/" : 'anonymous/') . $file;
  my $source = $set::char_dir . $relative;
  my $destination = $set::lib_type{e}{dataDir} . $relative . '.zip';
  my @paths = ($set::passfile, $set::listfile, $set::lib_type{e}{listFile});
  make_path(dirname($destination), map { dirname($_) } @paths);
  my %distinct;
  foreach (@paths) {
    my $real = abs_path($_) || File::Spec->rel2abs($_);
    error('409:移行に使う台帳の保存先が重複しています。') if $distinct{$real}++;
  }
  my $indexLocks = dx3MigrationIndexLocks(@paths);
  error('409:移行先に同名のデータがあります。') if -e $destination || -l $destination || -e substr($destination, 0, -4) || -l substr($destination, 0, -4);
  error('400:移行元にリンクは指定できません。') if -l $source || -l "$source.zip";
  # 設定がシンボリックリンクの場合、リンクを置換せず参照先の台帳を更新する。
  my @indexes = map { +{ path => abs_path($_) || File::Spec->rel2abs($_), existed => -e $_, raw => -e $_ ? dx3MigrationReadRaw($_) : '' } } @paths;
  my @passRows = split /(?<=\n)/, decode('UTF-8', $indexes[0]{raw}, FB_CROAK | LEAVE_SRC);
  my $found = 0;
  foreach my $row (@passRows) {
    next unless index($row, "$id<") == 0;
    $found++;
    my @fields = split /<>/, $row, -1;
    error('409:認証台帳の内容が変更されています。') unless $fields[2] eq $file && !$fields[3];
    $fields[3] = 'e';
    $row = join('<>', @fields);
  }
  error('409:認証台帳のIDが重複しているか、見つかりません。') unless $found == 1;
  my @characterRows = split /(?<=\n)/, decode('UTF-8', $indexes[1]{raw}, FB_CROAK | LEAVE_SRC);
  my @enemyRows = split /(?<=\n)/, decode('UTF-8', $indexes[2]{raw}, FB_CROAK | LEAVE_SRC);
  error('409:エネミー一覧に同じIDがあります。') if grep { index($_, "$id<") == 0 } @enemyRows;
  error('409:キャラクター一覧にIDが見つかりません。') unless grep { index($_, "$id<") == 0 } @characterRows;

  my %entries = readSheetZipEntries("$source.zip");
  if (-d $source) {
    opendir(my $dir, $source) or error('500:移行元を開けません。');
    my @names = grep { $_ ne '.' && $_ ne '..' } readdir($dir);
    closedir($dir);
    foreach my $name (@names) {
      error('400:移行元に通常ファイル以外が含まれています。') unless -f "$source/$name" && !-l "$source/$name";
      next if exists $entries{$name};
      my $raw = dx3MigrationReadRaw("$source/$name");
      $entries{$name} = isSheetBinaryEntry($name) ? $raw : decode('UTF-8', $raw, FB_CROAK);
    }
  }
  error('404:移行元のデータがありません。') unless defined $entries{'data.cgi'};
  my $now = time;
  ($entries{'data.cgi'}, my $line) = dx3MigrationConvertRecord($entries{'data.cgi'}, $id, $file, $now, 1);
  if (length($entries{'logs.cgi'} // '')) {
    my @parts = split /(^=[^\r\n]+=\r?\n)/m, $entries{'logs.cgi'};
    error('400:過去ログの形式が不正です。') if shift(@parts) ne '' || @parts % 2;
    my $logs = '';
    while (@parts) {
      my $header = shift @parts;
      my ($record) = dx3MigrationConvertRecord(shift(@parts), $id, $file, $now, 0);
      $logs .= $header . $record;
    }
    $entries{'logs.cgi'} = $logs;
  }
  # 次の保存がバックアップの日時に使うlatestも、本体の更新日時と揃える。
  my $hasLatest = 0;
  my $logList = '';
  foreach my $row (split /(?<=\n)/, $entries{'log-list.cgi'} // '') {
    if (index($row, 'latest<>') == 0) {
      my (undef, undef, $name) = split /<>/, $row =~ s/\r?\n\z//r, 3;
      $row = "latest<>$now<>" . ($name // '') . "\n";
      $hasLatest = 1;
    }
    $logList .= $row;
  }
  unless ($hasLatest) {
    $logList .= "\n" if length($logList) && $logList !~ /\n\z/;
    $logList .= "latest<>$now<>\n";
  }
  $entries{'log-list.cgi'} = $logList;
  $indexes[0]{new} = join('', @passRows);
  $indexes[1]{new} = join('', grep { index($_, "$id<") != 0 } @characterRows);
  $indexes[2]{new} = "$line\n" . join('', @enemyRows);

  my (@committed, @moved, $stagedZip, $recovery);
  my $published = 0;
  my $ok = eval {
    # 共通ZIP処理のerrorも、この書込区間だけは例外化して復元処理へ進める。
    local *::error = sub { die $_[0]."\n"; };
    # 全てを準備してから公開する。失敗時の復旧用コピーは確定まで保持する。
    $recovery = tempdir('migrate_XXXXXXXX', DIR => sheetZipTmpDir(), CLEANUP => 0);
    foreach my $i (0..$#indexes) {
      my $entry = $indexes[$i];
      $entry->{backup} = dx3MigrationTemp("$recovery/index$i", $entry->{raw}) if $entry->{existed};
      $entry->{temp} = dx3MigrationTemp($entry->{path}, encode('UTF-8', $entry->{new}));
    }
    require JSON::PP;
    my $manifest = JSON::PP->new->utf8->canonical->encode({
      id => $id, source => $source, destination => $destination,
      indexes => [map { +{path => $_->{path}, backup => $_->{backup}, existed => $_->{existed} ? 1 : 0} } @indexes],
    });
    my $manifestTemp = dx3MigrationTemp("$recovery/manifest.json", $manifest);
    rename($manifestTemp, "$recovery/manifest.json") or die "500:復旧情報を保存できません。\n";
    $stagedZip = dx3MigrationTemp($destination, '');
    writeSheetZip($stagedZip, \%entries);
    rename($stagedZip, $destination) or die "500:移行先のデータを保存できません。\n";
    $published = 1;
    foreach my $entry (@indexes) {
      dx3MigrationCommitIndex($entry->{temp}, $entry->{path});
      push @committed, $entry;
    }
    foreach my $path ("$source.zip", $source) {
      next unless -e $path;
      my $backup = "$recovery/" . (@moved ? 'source-directory' : 'source');
      dx3MigrationMoveSource($path, $backup);
      push @moved, [$path, $backup];
    }
    1;
  };
  unless ($ok) {
    my $reason = $@ || "500:移行に失敗しました。\n";
    my $restored = 1;
    foreach my $entry (reverse @moved) { $restored = 0 unless rename($entry->[1], $entry->[0]); }
    foreach my $entry (reverse @committed) {
      if ($entry->{existed}) {
        # バックアップは残したまま、元ファイルと同じ場所の一時ファイルから復元する。
        my $rollback = eval { dx3MigrationTemp($entry->{path}, $entry->{raw}); };
        $restored = 0 unless $rollback && rename($rollback, $entry->{path});
      } else { $restored = 0 unless unlink $entry->{path}; }
    }
    $restored = 0 if $published && $restored && !unlink($destination);
    unlink $stagedZip if $stagedZip && -e $stagedZip;
    unlink $_->{temp} foreach grep { $_->{temp} && -e $_->{temp} } @indexes;
    if ($restored) { remove_tree($recovery) if $recovery; }
    else { $reason .= "復旧が必要です。バックアップ保存先: $recovery\n"; }
    error($reason);
  }
  remove_tree($recovery);
  return $id;
}

sub dx3MigrationCommitIndex {
  my ($temp, $path) = @_;
  rename($temp, $path) or die "500:移行の台帳を更新できません。（$path）\n";
}

sub dx3MigrationMoveSource {
  my ($source, $backup) = @_;
  rename($source, $backup) or die "500:移行元のデータを移動できません。\n";
}

1;
