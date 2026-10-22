################## 管理者用ID重複・不整合チェック ##################
# index.cgiから呼び出す処理。認証・検査・一覧修正・画面HTMLをこのファイルにまとめる。
use 5.032;
use strict;
use utf8;
use Cwd qw(abs_path);
use Encode qw(decode encode FB_CROAK);
use Digest::SHA qw(hmac_sha256_hex);
use Errno qw(ENOENT EEXIST);
use Fcntl qw(:DEFAULT :flock);
use File::Spec;
use File::Basename qw(dirname basename);
use File::Temp qw(tempfile);
use Time::Local qw(timelocal);
use HTML::Template;

my $admin_id_check_windows_api;
my $admin_id_check_windows_case_api;

if (($::in{mode} // '') eq 'admin-id-check') {
  my $LOGIN_ID = check();
  my $is_master = $set::masterid && $LOGIN_ID && $LOGIN_ID eq $set::masterid;
  my $is_post = request_method() eq 'POST';
  # 不正なUTF-8は置換せずに拒否し、設定済みのパスワードとの誤一致を防ぐ。
  my $pass = $is_post ? eval { decode('UTF-8', $::in{pass} // '', FB_CROAK) } : '';
  my $authorized = $is_master || ($is_post && defined($pass) && $set::masterkey && $pass eq $set::masterkey);
  my $status;
  my $message = '';
  if (!$set::masterid && !$set::masterkey) {
    $status = '403 Forbidden';
    $message = 'config.cgiで管理ユーザーID（masterid）または管理パスワード（masterkey）を設定してください。';
  } elsif (!$authorized && $is_post) {
    $status = '403 Forbidden';
    $message = '管理パスワードが一致しないか、管理者としてログインしていません。';
  }

  my $html = <<'ADMIN_ID_CHECK_HTML';
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>ID重複・不整合チェック - <TMPL_VAR title ESCAPE=HTML></title>
  <style>
    :root { color-scheme: light dark; font-family: sans-serif; line-height: 1.6; }
    body { max-width: 1100px; margin: auto; padding: 1.5rem; }
    h1 { font-size: 1.6rem; } h2 { font-size: 1.2rem; }
    section { margin: 1.5rem 0; padding: 1rem; border: 1px solid #888; border-radius: .5rem; }
    .warning { border-left: 4px solid #d87b18; padding: .6rem 1rem; }
    .scroll { overflow-x: auto; }
    table { border-collapse: collapse; width: 100%; margin: .5rem 0; }
    th, td { border: 1px solid #888; padding: .5rem; text-align: left; vertical-align: top; }
    code { overflow-wrap: anywhere; } input, button { font: inherit; padding: .4rem; }
    label { display: block; margin-bottom: .5rem; }
  </style>
</head>
<body>
  <nav aria-label="ナビゲーション"><a href="./">シート一覧へ戻る</a></nav>
  <h1>キャラクターシートのID重複・不整合チェック</h1>
  <p><TMPL_VAR title ESCAPE=HTML> / 管理者用</p>
  <TMPL_IF message><p class="warning" role="alert"><TMPL_VAR message ESCAPE=HTML></p></TMPL_IF>
  <TMPL_UNLESS authorized>
    <section>
      <h2>管理者認証</h2>
      <TMPL_IF hasMasterId><p>設定済みの管理ユーザーで<a href="./?mode=login">ログイン</a>してから、このページを開いてください。</p></TMPL_IF>
      <TMPL_IF hasMasterKey>
        <form method="post" action="./?mode=admin-id-check">
          <input type="hidden" name="mode" value="admin-id-check">
          <label for="admin-pass">管理パスワード</label>
          <input id="admin-pass" name="pass" type="password" required autocomplete="current-password">
          <button type="submit">重複をチェック</button>
        </form>
      </TMPL_IF>
    </section>
  <TMPL_ELSE>
    <p>認証台帳内、または全種別の一覧内で同じIDが2行以上ある場合に検出します。認証台帳と一覧に1行ずつ載る通常の登録は重複に数えません。</p>
    <p>認証台帳と一覧の片側にしかないIDも、不整合エラーとして表示します。</p>
    <p>この画面を開く操作やチェックでは、一覧の修正は行いません。保存先は各種別のデータディレクトリからの相対名です（ZIP形式は末尾に <code>.zip</code>）。</p>
    <TMPL_IF repairReport>
      <section>
        <h2>不整合の解消結果</h2>
        <p>一覧への追加：<TMPL_VAR added> 行／一覧からの削除：<TMPL_VAR removed> 行</p>
        <TMPL_IF skipped><ul><TMPL_LOOP skipped><li>ID: <code><TMPL_VAR id ESCAPE=HTML></code>：<TMPL_VAR reason ESCAPE=HTML></li></TMPL_LOOP></ul></TMPL_IF>
        <TMPL_IF backups><p>修正前の一覧のバックアップ：</p><ul><TMPL_LOOP backups><li><code><TMPL_VAR path ESCAPE=HTML></code></li></TMPL_LOOP></ul></TMPL_IF>
        <TMPL_IF recovery>
          <h3>復旧が必要な一覧</h3>
          <ul><TMPL_LOOP recovery><li><code><TMPL_VAR path ESCAPE=HTML></code>：<TMPL_VAR message ESCAPE=HTML></li></TMPL_LOOP></ul>
        </TMPL_IF>
      </section>
    </TMPL_IF>
    <TMPL_IF complete>
      <p>検査完了：重複ID <strong><TMPL_VAR duplicateCount></strong> 件、不整合ID <strong><TMPL_VAR inconsistencyCount></strong> 件</p>
      <TMPL_UNLESS findings><p>重複・台帳間の不整合は見つかりませんでした。</p></TMPL_UNLESS>
    <TMPL_ELSE>
      <p class="warning" role="alert">検査未完了：読み込めた範囲で重複ID <strong><TMPL_VAR duplicateCount></strong> 件、不整合ID <strong><TMPL_VAR inconsistencyCount></strong> 件。下記の問題を確認してください。</p>
      <TMPL_IF inconsistencyCount><p class="warning" role="alert">不整合IDは暫定結果です。未読込の箇所に記録が存在する可能性があるため、読込の問題を解消して再検査してください。</p></TMPL_IF>
    </TMPL_IF>
    <TMPL_IF canRepair>
      <section>
        <h2>一覧の不整合を解消する</h2>
        <p>一覧のみに存在するIDの行を削除し、認証台帳のみに存在するIDは保存済みシートから一覧に追加します。認証台帳とシート本体は変更しません。</p>
        <p>保存済みシートが読めない場合や認証台帳でIDが重複している場合、そのIDの追加は見送り、理由を表示します。修正する一覧はバックアップを作成します。</p>
        <form method="post" action="./?mode=admin-id-check">
          <input type="hidden" name="mode" value="admin-id-check">
          <input type="hidden" name="action" value="repair">
          <input type="hidden" name="repair_token" value="<TMPL_VAR repairToken ESCAPE=HTML>">
          <TMPL_IF needRepairPassword><label>管理パスワード（実行時に再入力） <input name="pass" type="password" required autocomplete="current-password"></label></TMPL_IF>
          <label><input name="confirm_repair" type="checkbox" value="1" required> 上記の一覧への追加・一覧からの削除を実行する</label>
          <button type="submit">不整合を解消する</button>
        </form>
      </section>
    </TMPL_IF>
    <TMPL_LOOP findings>
      <section>
        <h2>ID: <code><TMPL_VAR id ESCAPE=HTML></code></h2>
        <TMPL_IF list_missing><p class="warning" role="alert">不整合エラー：認証台帳にのみ存在します。一覧に対応するIDがありません。</p></TMPL_IF>
        <TMPL_IF pass_missing><p class="warning" role="alert">不整合エラー：一覧にのみ存在します。認証台帳に対応するIDがありません。</p></TMPL_IF>
        <TMPL_IF pass_duplicate><p>認証台帳で重複（<TMPL_VAR pass_count> 行）</p></TMPL_IF>
        <TMPL_IF list_duplicate><p>一覧で重複（<TMPL_VAR list_count> 行）</p></TMPL_IF>
        <p>認証台帳 <TMPL_VAR pass_count> 行／一覧 <TMPL_VAR list_count> 行</p>
        <div class="scroll">
          <table>
            <thead><tr><th scope="col">台帳ファイル</th><th scope="col">行番号</th><th scope="col">種別</th><th scope="col">名前</th><th scope="col">保存先</th></tr></thead>
            <tbody><TMPL_LOOP records><tr>
              <td><code><TMPL_VAR path ESCAPE=HTML></code></td><td><TMPL_VAR line></td>
              <td><TMPL_VAR type ESCAPE=HTML></td><td><TMPL_VAR name ESCAPE=HTML></td><td><code><TMPL_VAR storage ESCAPE=HTML></code></td>
            </tr></TMPL_LOOP></tbody>
          </table>
        </div>
      </section>
    </TMPL_LOOP>
    <TMPL_IF issues>
      <section>
        <h2>検査中に見つかった問題</h2>
        <ul><TMPL_LOOP issues><li><code><TMPL_VAR path ESCAPE=HTML></code><TMPL_IF line>（<TMPL_VAR line> 行目）</TMPL_IF>：<TMPL_VAR message ESCAPE=HTML></li></TMPL_LOOP></ul>
      </section>
    </TMPL_IF>
    <section>
      <h2>検査対象</h2>
      <div class="scroll"><table>
        <thead><tr><th scope="col">ファイル</th><th scope="col">検査した行数</th><th scope="col">状態</th></tr></thead>
        <tbody><TMPL_LOOP files><tr><td><code><TMPL_VAR path ESCAPE=HTML></code></td><td><TMPL_VAR count></td><td><TMPL_VAR state ESCAPE=HTML></td></tr></TMPL_LOOP></tbody>
      </table></div>
    </section>
    <p><a href="./?mode=admin-id-check">もう一度チェックする</a>（パスワード認証の場合は再入力が必要です）</p>
  </TMPL_UNLESS>
</body>
</html>
ADMIN_ID_CHECK_HTML
  my $PAGE = HTML::Template->new( scalarref => \$html, case_sensitive => 1 );
  $PAGE->param(
    title => $set::title, authorized => $authorized ? 1 : 0,
    hasMasterKey => $set::masterkey ? 1 : 0, hasMasterId => $set::masterid ? 1 : 0,
    message => $message,
  );

  if ($authorized) {
    my @sources = (
      { path => $set::passfile, kind => 'pass' },
      { path => $set::listfile, kind => 'list', type => '' },
    );
    foreach my $type (sort keys %set::lib_type) {
      next if !$set::lib_type{$type}{listFile};
      push @sources, { path => $set::lib_type{$type}{listFile}, kind => 'list', type => $type, optional => 1 };
    }
    my $result = adminIdCheckScan(\@sources);
    # 認証済みセッション、または管理パスワードに結び付けた確認用署名。
    # GETや通常の検査POSTには書込処理を呼ばない。
    my (undef, $session_key) = $is_master ? getCookie() : ();
    my $secret = $is_master ? $session_key : $set::masterkey;
    my $binding = $is_master ? "session:$LOGIN_ID" : 'password';
    if ($is_post && ($::in{action} // '') eq 'repair') {
      my $snapshot = adminIdCheckVerifyToken($::in{repair_token} // '', $secret, $binding);
      if (!$snapshot) {
        $status = '403 Forbidden';
        $message = '実行確認が無効または期限切れです。再検査してから実行してください。';
      } elsif (($::in{confirm_repair} // '') ne '1') {
        $status = '400 Bad Request';
        $message = '一覧への追加・削除の確認欄にチェックしてください。';
      } else {
        my $repair = adminIdCheckRepair(\@sources, $snapshot);
        $status = $repair->{status};
        $message = $repair->{message};
        $PAGE->param(repairReport => 1, added => $repair->{added}, removed => $repair->{removed},
          skipped => $repair->{skipped}, backups => $repair->{backups}, recovery => $repair->{recovery});
        $result = adminIdCheckScan(\@sources);
      }
    }
    $PAGE->param(message => $message);
    $PAGE->param(
      findings => $result->{findings}, files => $result->{files}, issues => $result->{issues},
      complete => $result->{complete}, duplicateCount => scalar @{ $result->{duplicates} },
      inconsistencyCount => scalar @{ $result->{inconsistencies} },
      canRepair => $result->{repairable} && @{ $result->{inconsistencies} } ? 1 : 0,
      needRepairPassword => $is_master ? 0 : 1,
      repairToken => adminIdCheckToken(time, $result->{snapshot}, $secret, $binding),
    );
  }

  print "Status: $status\n" if $status;
  print "Cache-Control: no-store\n";
  print "Referrer-Policy: no-referrer\n";
  print "X-Content-Type-Options: nosniff\n";
  print "Content-Type: text/html; charset=utf-8\n\n";
  print outputTemplate($PAGE);
}

# Perl 5.32のWindows版ではstatのdevice/inodeが0になるため、同一ファイル判定に使わない。
# 台帳の照合・ロックの重複除外・取得順序は、すべてこの識別値を共通で使う。
sub adminIdCheckFileIdentity {
  my ($handle, $stat) = @_;
  return adminIdCheckWindowsFileIdentity($handle) if $^O eq 'MSWin32';
  die "ファイルの識別情報を取得できません。検査・修正を中止します。\n"
    unless @$stat && defined($stat->[0]) && defined($stat->[1]) && $stat->[1] != 0;
  return "unix:$stat->[0]:$stat->[1]";
}

sub adminIdCheckWindowsFileIdentity {
  my ($handle) = @_;
  my $api = adminIdCheckWindowsAPI();
  my $native = Win32API::File::FdGetOsFHandle(fileno($handle));
  return adminIdCheckWindowsNativeIdentity($native, $api);
}

sub adminIdCheckWindowsAPI {
  eval {
    require Win32::API;
    Win32::API->VERSION(0.84);
    require Win32API::File;
    1;
  } or die "Windowsのファイル識別に必要なWin32::API（0.84以上）またはWin32API::Fileを読み込めません。使用中のPerlに対応するモジュールを導入してください。\n";
  # NはWin32::API::Moreのポインタ幅の整数型。32/64ビットのHANDLEを切り詰めない。
  $admin_id_check_windows_api ||= Win32::API::More->new(
    'kernel32', 'GetFileInformationByHandle', 'NP', 'I'
  );
  die "Windowsのファイル識別APIを初期化できません。検査・修正を中止します。\n"
    unless $admin_id_check_windows_api;
  return $admin_id_check_windows_api;
}

sub adminIdCheckWindowsNativeIdentity {
  my ($native, $api) = @_;
  # BY_HANDLE_FILE_INFORMATIONは13個のDWORD（52バイト）。ゼロ終端文字列ではない。
  my $buffer = "\0" x 52;
  die "Windowsのファイル識別情報を取得できません。検査・修正を中止します。\n"
    unless defined($native) && $api->Call($native, $buffer) && length($buffer) == 52;
  my @info = unpack('V13', $buffer);
  die "WindowsのファイルIDが取得できません。検査・修正を中止します。\n"
    unless $info[11] || $info[12];
  # ボリューム番号とファイルIDの上位・下位を別々に保持し、32ビットPerlでも精度を失わない。
  my $identity = join(':', 'win32', @info[7, 11, 12]);
  return wantarray ? ($identity, $info[0]) : $identity;
}

sub adminIdCheckWindowsDirectoryInfo {
  my ($path) = @_;
  my $api = adminIdCheckWindowsAPI();
  # FILE_READ_ATTRIBUTES / 全共有 / OPEN_EXISTING / FILE_FLAG_BACKUP_SEMANTICS。
  # 最後のフラグでディレクトリを開く。ジャンクション等の参照先の実体を識別する。
  my $native = Win32API::File::CreateFile($path, 0x80, 7, [], 3, 0x02000000, 0);
  my $open_error = 0 + $^E;
  unless ($native) {
    # 未使用の追加種別では親ディレクトリごと未作成でも正常。作成はしない。
    return { missing => 1 } if $open_error == 2 || $open_error == 3;
    die "Windowsの台帳ディレクトリを開けません。パスと権限を確認してください。\n";
  }
  my $info;
  my $ok = eval {
    my ($identity, $attributes) = adminIdCheckWindowsNativeIdentity($native, $api);
    die "Windowsの台帳保存先をディレクトリとして確認できません。\n" unless $attributes & 0x10;
    my $case_sensitive = 0;
    $admin_id_check_windows_case_api ||= Win32::API::More->new(
      'kernel32', 'GetFileInformationByHandleEx', 'NIPI', 'I'
    );
    if ($admin_id_check_windows_case_api) {
      my $buffer = "\0" x 4; # FILE_CASE_SENSITIVE_INFOのULONG Flags
      my $got = $admin_id_check_windows_case_api->Call($native, 23, $buffer, 4); # FileCaseSensitiveInfo
      my $native_error = 0 + $^E;
      if ($got) {
        die "Windowsの大文字・小文字の区別設定を読み取れません。\n" unless length($buffer) == 4;
        $case_sensitive = unpack('V', $buffer) & 1;
      } else {
        # 古いWindows等で設定自体が未対応なら、標準の大文字・小文字を区別しない動作。
        die "Windowsの大文字・小文字の区別設定を確認できません。\n"
          unless $native_error == 1 || $native_error == 50 || $native_error == 87;
      }
    }
    $info = { identity => $identity, case_sensitive => $case_sensitive };
    1;
  };
  my $reason = $@;
  my $closed = Win32API::File::CloseHandle($native);
  die $reason unless $ok;
  die "Windowsの台帳ディレクトリを正常に閉じられません。\n" unless $closed;
  return $info;
}

# 未作成のファイルも、親ディレクトリの実体と名前からロックとの衝突を判定する。
sub adminIdCheckLockPathKey {
  my ($path, $directories) = @_;
  return abs_path($path) || File::Spec->rel2abs($path) unless $^O eq 'MSWin32';
  my $absolute = File::Spec->rel2abs($path);
  my $parent = dirname($absolute);
  my $info = $directories->{$parent} ||= adminIdCheckWindowsDirectoryInfo($parent);
  # 親自体がない場所にsysopenがファイルを作ることはできない。通常の欠落として検査する。
  return 'winmissing:' . $absolute if $info->{missing};
  my $name = basename($absolute);
  # 通常のWin32パスは末尾の空白・ピリオドを無視する。拡張パスではそのまま扱う。
  $name =~ s/[ .]+\z// unless $absolute =~ m{\A(?:\\\\\?\\|//\?/)};
  $name = lc($name) unless $info->{case_sensitive};
  return join(':', 'winpath', $info->{identity}, $name);
}

# 未作成の一覧も含め、ロックの保存先にしてはいけない台帳のパス・実体を集める。
sub adminIdCheckLockTargets {
  my ($sources) = @_;
  my $protected = { paths => {}, physical => {}, issues => [], directories => {} };
  foreach my $source (@$sources) {
    my $path = $source->{path};
    my $key = eval { adminIdCheckLockPathKey($path, $protected->{directories}) };
    if (defined($key)) { $protected->{paths}{$key} = 1; }
    else { push @{$protected->{issues}}, { path => $path, line => '', message => $@ || '台帳の保存先を識別できません。' }; }
    # 開けない台帳・未作成の一覧はScanが報告する。FIFOなどはここでも開かない。
    next unless -f $path;
    open my $read, '<:raw', $path or next;
    my @stat = stat($read);
    if (@stat && -f $read) {
      my $physical = eval { adminIdCheckFileIdentity($read, \@stat) };
      if (defined($physical)) { $protected->{physical}{$physical} = 1; }
      else { push @{$protected->{issues}}, { path => $path, line => '', message => $@ || 'ファイルを識別できません。' }; }
    }
    close $read;
  }
  return $protected;
}

sub adminIdCheckOpenLock {
  my ($path, $protected) = @_;
  die "台帳のファイル識別に失敗したため、ロックの取得を中止します。\n" if @{$protected->{issues}};
  my $lock_path = "$path.lock";
  my $key = adminIdCheckLockPathKey($lock_path, $protected->{directories});
  my $collision = "ロックファイルが検査対象の台帳を参照しています。設定したパスを確認してください。\n";
  # 作成前に確認し、未作成の台帳をロックファイルとして作ってしまうことを防ぐ。
  die $collision if $protected->{paths}{$key};
  die "通常のロックファイルではありません。設定したパスを確認してください。\n" if -e $lock_path && !-f $lock_path;
  my $lock;
  my $open_error = "ロックファイルを開けません。台帳の設定、リンクの参照先と権限を確認してください。\n";
  # O_CREATだけでは、既存のリンクをたどって台帳を作ってしまう。
  # まず作成せずに開き、欠落時だけO_EXCLで新しいロックを作成する。
  unless (sysopen($lock, $lock_path, O_RDWR)) {
    die $open_error unless $! == ENOENT;
    unless (sysopen($lock, $lock_path, O_RDWR | O_CREAT | O_EXCL)) {
      # 別リクエストが先に作った場合は既存ファイルを開き直す。リンク先は作成しない。
      die $open_error unless $! == EEXIST && sysopen($lock, $lock_path, O_RDWR);
    }
  }
  my @stat = stat($lock);
  die "通常のロックファイルとして確認できません。\n" unless @stat && -f $lock;
  my $physical = adminIdCheckFileIdentity($lock, \@stat);
  die $collision if $protected->{physical}{$physical};
  return ($lock, $physical);
}

# 認証台帳と一覧は別々に数える。同じIDが各台帳に1行ずつあるのは正常。
# 重複に加え、読み込めた台帳の片側にしかないIDも不整合として返す。
sub adminIdCheckScan {
  my ($sources, $options) = @_;
  $options ||= {};
  my (%records, %seen, %physical_paths, %registered_types, @files, @issues, @missing_lists);
  my ($complete, $repairable) = (1, 1);
  my %raw_files;
  my $protected = adminIdCheckLockTargets($sources);
  if (@{$protected->{issues}}) {
    push @issues, @{$protected->{issues}};
    $complete = $repairable = 0;
  }
  my $digest = Digest::SHA->new(256);
  foreach my $source (@$sources) {
    my $path = $source->{path};
    my $key = abs_path($path) || File::Spec->rel2abs($path);
    my $role = join(':', $source->{kind}, $source->{type} || 'chara');
    $digest->add(encode('UTF-8', join("\0", $key, $source->{kind}, $source->{type} // '') . "\0"));
    if (exists $seen{$key}) {
      if ($seen{$key} ne $role) {
        push @files, { path => $path, count => 0, state => '設定不整合' };
        push @issues, { path => $path, line => '', message => '認証台帳と一覧、または異なる種別の一覧が同じファイルを参照しています。用途・種別と設定したパスを確認してください。' };
        $complete = 0;
        $repairable = 0;
      }
      next;
    }
    $seen{$key} = $role;
    my $file = { path => $path, count => 0, state => '検査済み' };
    push @files, $file;

    # 名前付きパイプなどはopen自体が待ち続けるため、開く前にも種別を確認する。
    if (-e $path && !-f $path) {
      push @issues, { path => $path, line => '', message => '通常のファイルではありません。設定したパスを確認してください。' };
      $file->{state} = '読込不可';
      $complete = 0;
      $repairable = 0;
      next;
    }

    # 追加種別の欠落は、認証台帳に登録があるかを全ファイルの読込後に確認する。
    unless (open my $read, '<:raw', $path) {
      my $missing_list = $! == ENOENT && $source->{kind} eq 'list';
      my $optional_missing = $! == ENOENT && $source->{optional};
      $digest->add("missing\0");
      $raw_files{$path} = undef if $options->{capture};
      $repairable = 0 unless $missing_list;
      $file->{state} = $optional_missing ? '未作成（対象外）' : '読込不可';
      if ($optional_missing) {
        push @missing_lists, { file => $file, type => $source->{type} || 'chara' };
      } else {
        push @issues, { path => $path, line => '', message => 'ファイルを読み込めません。パスと読込権限を確認してください。' };
        $complete = 0;
      }
      next;
    } else {
      unless (-f $read) {
        push @issues, { path => $path, line => '', message => '通常のファイルではありません。設定したパスを確認してください。' };
        $file->{state} = '読込不可';
        $complete = 0;
        $repairable = 0;
        close $read;
        next;
      }
      close $read;
    }

    # 保存処理と同じロックファイルを利用する（台帳自体は読み取り専用）。
    my $lock;
    unless ($options->{locked} || eval {
      ($lock) = adminIdCheckOpenLock($path, $protected);
      flock($lock, LOCK_SH) or die "読込用ロックを取得できません。\n";
      1;
    }) {
      push @issues, { path => $path, line => '', message => $@ || '読込用ロックを取得できません。' };
      $file->{state} = 'ロック不可';
      $complete = 0;
      $repairable = 0;
      next;
    }
    unless (open my $read, '<:raw', $path) {
      push @issues, { path => $path, line => '', message => 'ロック後にファイルを読み込めません。' };
      $file->{state} = '読込不可';
      $complete = 0;
      $repairable = 0;
    } else {
      my @stat = stat($read);
      unless (@stat && -f $read) {
        push @issues, {path => $path, line => '', message => 'ロック後の台帳を通常のファイルとして確認できません。'};
        $file->{state} = '読込不可';
        $complete = $repairable = 0;
        close $read;
        close $lock if $lock;
        next;
      }
      # abs_pathではハードリンクを区別できないため、開いたファイルの識別値も照合する。
      my $physical = eval { adminIdCheckFileIdentity($read, \@stat) };
      unless (defined($physical)) {
        push @issues, {path => $path, line => '', message => $@ || '台帳のファイル識別に失敗しました。'};
        $file->{state} = '読込不可';
        $complete = $repairable = 0;
        close $read;
        close $lock if $lock;
        next;
      }
      if (exists($physical_paths{$physical}) && $physical_paths{$physical} ne $key) {
        push @issues, {path => $path, line => '', message => '異なる台帳パスが同じファイルのハードリンクを参照しています。台帳を独立したファイルにするか、設定したパスを確認してください。'};
        $file->{state} = '設定不整合';
        $complete = $repairable = 0;
        close $read;
        close $lock if $lock;
        next;
      }
      $physical_paths{$physical} = $key;
      $digest->add("present\0");
      $raw_files{$path} = '' if $options->{capture};
      my $line_no = 0;
      while (1) {
        # readlineは読込エラー時にも行の一部を返すため、文字列の有無より先にerrnoを確認する。
        local $! = 0;
        my $line = <$read>;
        if ($!) {
          push @issues, { path => $path, line => '', message => 'ファイルの読込中にエラーが発生しました。' };
          $file->{state} = '読込エラー';
          $complete = 0;
          $repairable = 0;
          last;
        }
        last if !defined $line;
        $digest->add(length($line) . ':' . $line);
        $raw_files{$path} .= $line if $options->{capture};
        $line_no++;
        my $decoded = eval { decode('UTF-8', $line, FB_CROAK) };
        if ($@) {
          push @issues, { path => $path, line => $line_no, message => 'UTF-8として読み込めない行です。' };
          $complete = 0;
          $repairable = 0;
          next;
        }
        $line = $decoded;
        $line =~ s/\r?\n\z//;
        next if $line =~ /^\s*$/;
        my @fields = split /<>/, $line, -1;
        my $minimum = $source->{kind} eq 'pass' ? 4 : 5;
        # 共通列も検証し、認証台帳の形式でコピーされたファイルを一覧として誤読しない。
        if (@fields < $minimum || $fields[0] eq '' || $fields[1 + ($source->{kind} eq 'pass' ? 1 : 0)] eq ''
          || ($source->{kind} eq 'list' && ($fields[2] !~ /\A[0-9]+\z/ || $fields[3] !~ /\A[0-9]+\z/))) {
          push @issues, { path => $path, line => $line_no, message => 'ID・ファイル名が空、または行の形式が不正です（一覧の作成・更新時刻は整数である必要があります）。' };
          $complete = 0;
          $repairable = 0;
          next;
        }
        my $record = { path => $path, line => $line_no };
        if ($source->{kind} eq 'pass') {
          # パスワードやハッシュを結果に含めない。
          $record->{type} = $fields[3] || 'chara';
          $registered_types{$record->{type}} = 1;
          my $owner_dir = $fields[1] =~ /^\[(.+)\]$/ ? "_$1/" : 'anonymous/';
          $record->{file} = $fields[2];
          $record->{storage} = $owner_dir . $fields[2];
          $record->{name} = '';
        } else {
          $record->{type} = $source->{type} || 'chara';
          # 一覧の2列目はファイル名、3列目は作成時刻。ユーザー名は含まれない。
          $record->{file} = $fields[1];
          $record->{storage} = $fields[1];
          $record->{name} = $fields[4];
        }
        push @{ $records{$fields[0]}{$source->{kind}} }, $record;
        $file->{count}++;
      }
      unless (close $read) {
        push @issues, {path => $path, line => '', message => '読込ファイルを正常に閉じられませんでした。'};
        $complete = $repairable = 0;
      }
    }
    close $lock if $lock;
  }

  foreach my $missing (@missing_lists) {
    next unless $registered_types{$missing->{type}};
    $missing->{file}{state} = '読込不可';
    push @issues, { path => $missing->{file}{path}, line => '', message => '認証台帳に登録のある種別の一覧が見つかりません。設定したパスを確認してください。' };
    $complete = 0;
  }

  my (@duplicates, @inconsistencies, @findings);
  foreach my $id (sort keys %records) {
    my $pass = $records{$id}{pass} || [];
    my $list = $records{$id}{list} || [];
    my $is_duplicate = @$pass > 1 || @$list > 1;
    my $is_inconsistent = !@$pass || !@$list;
    next unless $is_duplicate || $is_inconsistent;
    # 一覧のファイル名と種別を認証台帳に照合して保存先を特定する。
    my %locations;
    foreach my $record (@$pass) {
      $locations{$record->{type}}{$record->{file}}{$record->{storage}} = 1;
    }
    foreach my $record (@$list) {
      my @paths = sort keys %{ $locations{$record->{type}}{$record->{file}} || {} };
      $record->{storage} = @paths == 1 ? $paths[0]
        : @paths > 1 ? '候補: ' . join('、', @paths)
        : $record->{file} . '（認証台帳に対応する記録なし）';
    }
    # 照合用の内部項目を画面テンプレートには渡さない。
    delete $_->{file} foreach (@$pass, @$list);
    my $finding = {
      id => $id, pass_count => scalar @$pass, list_count => scalar @$list,
      pass_duplicate => @$pass > 1 ? 1 : 0, list_duplicate => @$list > 1 ? 1 : 0,
      pass_missing => @$pass == 0 ? 1 : 0, list_missing => @$list == 0 ? 1 : 0,
      records => [@$pass, @$list],
    };
    push @findings, $finding;
    push @duplicates, $finding if $is_duplicate;
    push @inconsistencies, $finding if $is_inconsistent;
  }
  return {
    duplicates => \@duplicates, inconsistencies => \@inconsistencies, findings => \@findings,
    files => \@files, issues => \@issues, complete => $complete,
    repairable => $repairable, snapshot => $digest->hexdigest, raw_files => \%raw_files,
    registered_types => \%registered_types,
  };
}

# 確認画面の台帳状態と認証方法に署名する。確認の有効期間は30分。
sub adminIdCheckToken {
  my ($stamp, $snapshot, $secret, $binding) = @_;
  my $payload = "$stamp:$snapshot";
  return $payload . ':' . hmac_sha256_hex(encode('UTF-8', "$binding:$payload"), encode('UTF-8', $secret // ''));
}
sub adminIdCheckVerifyToken {
  my ($token, $secret, $binding) = @_;
  return unless $secret && $token =~ /\A(\d{1,12}):([a-f0-9]{64}):[a-f0-9]{64}\z/;
  my ($stamp, $snapshot) = ($1, $2);
  return if $stamp > time || time - $stamp > 1800;
  return $token eq adminIdCheckToken($stamp, $snapshot, $secret, $binding) ? $snapshot : undef;
}

# Windows版Perl 5.32のabs_pathはlstatに対応せず、末尾のリンクを解決できない。
# リンク自体をrenameで置換しないよう、Windowsでは属性を確認して修正を止める。
sub adminIdCheckRepairPath {
  my ($path) = @_;
  if ($^O eq 'MSWin32') {
    eval { require Win32API::File; 1; }
      or die "一覧のファイル属性を確認するWin32API::Fileを読み込めません。修正を中止します。\n";
    my $attributes = Win32API::File::GetFileAttributes($path);
    my $native_error = 0 + $^E;
    if (!defined($attributes) || $attributes == 4294967295) { # INVALID_FILE_ATTRIBUTES
      # 欠落した一覧は復元できる。権限エラーなどを欠落として扱わない。
      die "Windowsの一覧ファイル属性を確認できません。修正を中止します。\n"
        unless defined($attributes) && ($native_error == 2 || $native_error == 3);
    } elsif ($attributes & 0x400) { # FILE_ATTRIBUTE_REPARSE_POINT
      die "Windows版Perl 5.32ではリンク等になっている一覧の安全な置換を保証できないため、修正を中止します。一覧の参照先ファイルを設定に直接指定してください。\n";
    }
  }
  return abs_path($path) || File::Spec->rel2abs($path);
}

# 全台帳を排他ロックし、確認画面から変化していないことを検証してから一覧だけを更新する。
sub adminIdCheckRepair {
  my ($sources, $snapshot) = @_;
  my $report = { added => 0, removed => 0, skipped => [], backups => [], recovery => [] };
  my (@locks, @staged, @committed);
  my $ok = eval {
    my (%paths, %locked_files);
    my @unlocked_optional;
    my $protected = adminIdCheckLockTargets($sources);
    die $protected->{issues}[0]{message} if @{$protected->{issues}};
    foreach my $source (@$sources) {
      my $key = abs_path($source->{path}) || File::Spec->rel2abs($source->{path});
      my $role = join(':', $source->{kind}, $source->{type} || 'chara');
      die "同じ台帳が異なる用途・種別に設定されています。設定を確認してください。\n"
        if $paths{$key} && $paths{$key}{role} ne $role;
      $paths{$key} ||= { source => $source, role => $role };
    }
    foreach my $key (sort keys %paths) {
      my $source = $paths{$key}{source};
      my $path = $source->{path};
      die "通常の台帳ファイルではないため、修正を中止しました。\n" if -e $path && !-f $path;
      # 未使用の追加種別では親ごと未作成でもよい。ここでは作成せず、ロック後の再検査で
      # 対象外であることを確認する。登録がある場合やファイルが現れた場合は更新前に止める。
      if ($source->{kind} eq 'list' && $source->{optional}
        && !-e $path && !-e dirname(File::Spec->rel2abs($path))) {
        push @unlocked_optional, $source;
        next;
      }
      my ($lock, $physical) = adminIdCheckOpenLock($path, $protected);
      # 同じロックを別ハンドルで再取得すると自分のロック待ちになるため、実体で重複を除く。
      if ($locked_files{$physical}) { close $lock; next; }
      $locked_files{$physical} = $lock;
      push @locks, $lock;
    }
    # 台帳パス順は設置先によって変わるため、共有ロックも実体の共通順序で取得する。
    foreach my $physical (sort keys %locked_files) {
      flock($locked_files{$physical}, LOCK_EX)
        or die "台帳の書込用ロックを取得できません。修正を中止しました。\n";
    }
    my $current = adminIdCheckScan($sources, { locked => 1, capture => 1 });
    die "台帳に読込・形式の問題があるため、修正を中止しました。\n" unless $current->{repairable};
    if ($current->{snapshot} ne $snapshot) {
      $report->{status} = '409 Conflict';
      die "表示後に台帳が変更されています。現在の結果を確認してから、再度実行してください。\n";
    }
    foreach my $source (@unlocked_optional) {
      my $type = $source->{type} || 'chara';
      die "追加種別の一覧のロックを取得できていないため、修正を中止しました。保存先ディレクトリと設定したパスを確認して再検査してください。\n"
        if $current->{registered_types}{$type} || defined($current->{raw_files}{$source->{path}});
    }
    my (%delete_ids, %new_lists, %calculators);
    foreach my $finding (@{ $current->{inconsistencies} }) {
      $delete_ids{$finding->{id}} = 1 if $finding->{pass_missing};
    }
    my ($added, $removed) = (0, 0);
    foreach my $entry (values %paths) {
      my $source = $entry->{source};
      next unless $source->{kind} eq 'list';
      my $path = $source->{path};
      my $raw = $current->{raw_files}{$path} // '';
      my $new = '';
      foreach my $line ($raw =~ /[^\n]*\n|[^\n]+\z/g) {
        my $decoded = decode('UTF-8', $line, FB_CROAK);
        my ($id) = split /<>/, $decoded, 2;
        if ($delete_ids{$id}) { $removed++; }
        else { $new .= encode('UTF-8', $decoded); }
      }
      $new_lists{$path} = $new;
    }
    # 種別ごとのdataCalcは同じ関数名なので、ロードした時点のコード参照を保持する。
    foreach my $finding (sort { $a->{records}[0]{type} cmp $b->{records}[0]{type} || $a->{id} cmp $b->{id} }
      grep { $_->{list_missing} } @{ $current->{inconsistencies} }) {
      my $line;
      my $restored = eval {
        die "認証台帳でIDが重複しているため、保存先を特定できません。\n" if $finding->{pass_count} != 1;
        my $record = $finding->{records}[0];
        my $type = $record->{type};
        my $config = $type eq 'chara'
          ? {listFile => $set::listfile, dataDir => $set::char_dir, calc => $set::lib_calc_char}
          : $set::lib_type{$type};
        die "種別に対応する一覧・保存先・生成処理が設定されていません。\n"
          unless $config && $config->{listFile} && $config->{dataDir} && $config->{calc} && exists $new_lists{$config->{listFile}};
        $line = adminIdCheckRestoreLine($finding->{id}, $record, $config, \%calculators);
        my $path = $config->{listFile};
        $new_lists{$path} .= "\n" if length($new_lists{$path}) && $new_lists{$path} !~ /\n\z/;
        $new_lists{$path} .= encode('UTF-8', $line . "\n");
        $added++;
        1;
      };
      push @{ $report->{skipped} }, {id => $finding->{id}, reason => $@ || '一覧を復元できませんでした。'} unless $restored;
    }
    # 全ファイルの新データとバックアップが準備できるまでは元の一覧に触れない。
    foreach my $path (sort keys %new_lists) {
      my $old = $current->{raw_files}{$path};
      my $new = $new_lists{$path};
      next if defined($old) ? $new eq $old : $new eq '';
      # リンクの場合も、実際の置換先と同じファイルシステム内で一時ファイルを作る。
      my $entry = {path => $path, destination => adminIdCheckRepairPath($path), existed => defined($old)};
      push @staged, $entry;
      if (defined $old) {
        my @stat = stat($entry->{destination});
        die "一覧ファイルの権限を確認できません。修正を中止しました。\n" unless @stat;
        $entry->{mode} = $stat[2] & 0777;
        $entry->{backup} = adminIdCheckTemp($entry->{destination}, $old, 'backup');
        push @{ $report->{backups} }, {path => $entry->{backup}};
      }
      $entry->{temp} = adminIdCheckTemp($entry->{destination}, $new, 'new');
      if (defined $old) {
        chmod($entry->{mode}, $entry->{temp}) or die "一覧ファイルの権限を設定できません。修正を中止しました。\n";
      }
    }
    foreach my $entry (@staged) {
      # 既存のシンボリックリンクの参照先を保ち、保存処理と同じロックを使う。
      rename($entry->{temp}, $entry->{destination}) or die "一覧の置き換えに失敗しました。\n";
      push @committed, $entry;
    }
    $report->{added} = $added;
    $report->{removed} = $removed;
    $report->{message} = @staged ? '一覧の不整合を解消しました。追加を見送ったIDがある場合は、下記の理由を確認してください。' : '一覧の変更はありません。追加を見送ったIDの理由を確認してください。';
    1;
  };
  unless ($ok) {
    my $reason = $@ || "修正処理に失敗しました。\n";
    my $rollback_ok = 1;
    foreach my $entry (reverse @committed) {
      my $rollback_temp;
      my $restored = eval {
        if ($entry->{existed}) {
          my $old = adminIdCheckReadRaw($entry->{backup});
          $rollback_temp = adminIdCheckTemp($entry->{destination}, $old, 'rollback');
          chmod($entry->{mode}, $rollback_temp) && rename($rollback_temp, $entry->{destination}) or die "rollback\n";
        } else { unlink($entry->{destination}) or die "rollback\n"; }
        1;
      };
      unlink $rollback_temp if $rollback_temp && -e $rollback_temp;
      unless ($restored) {
        $rollback_ok = 0;
        push @{ $report->{recovery} }, {
          path => $entry->{destination},
          message => $entry->{existed}
            ? 'バックアップ「' . $entry->{backup} . '」から、この一覧を復旧してください。'
            : 'この一覧は修正処理で新規作成しました。修正前の状態に戻すには、このファイルを削除してください。',
        };
      }
    }
    $report->{status} ||= '500 Internal Server Error';
    $report->{message} = $reason . ($rollback_ok ? '一覧への変更はありません。' : '一部の一覧を元に戻せませんでした。下記の「復旧が必要な一覧」で対象ファイルと復旧方法を確認してください。');
  }
  unlink $_->{temp} foreach grep { $_->{temp} && -e $_->{temp} } @staged;
  close $_ foreach @locks;
  return $report;
}

sub adminIdCheckReadRaw {
  my ($path) = @_;
  die "保存済みシートが見つからないか、通常のファイルではありません。\n" unless -f $path;
  open my $read, '<:raw', $path or die "保存済みデータを読み込めません。\n";
  my $raw = '';
  while (1) {
    my $chunk;
    my $count = read($read, $chunk, 65536);
    die "保存済みデータの読込中にエラーが発生しました。\n" unless defined $count;
    last unless $count;
    $raw .= $chunk;
  }
  close $read or die "保存済みデータの読込を正常に終了できません。\n";
  return $raw;
}

sub adminIdCheckTemp {
  my ($path, $raw, $purpose) = @_;
  my ($write, $temp) = tempfile(".admin-id-check-$purpose-XXXXXX", DIR => dirname($path), SUFFIX => '.cgi', UNLINK => 0);
  my $ok = eval {
    binmode $write, ':raw' or die;
    print {$write} $raw or die;
    close $write or die;
    1;
  };
  unless ($ok) {
    close $write;
    unlink $temp;
    die "一覧の一時ファイル・バックアップの書込に失敗しました。\n";
  }
  return $temp;
}

sub adminIdCheckRestoreLine {
  my ($id, $record, $config, $calculators) = @_;
  my $storage = $record->{storage};
  die "認証台帳の保存先が不正です。\n" unless $storage =~ m{\A(?:anonymous|_[A-Za-z0-9_.-]+)/([A-Za-z0-9_-]+)\z};
  my $file = $1;
  my $base = File::Spec->catfile($config->{dataDir}, $storage);
  my ($raw, $mtime);
  if (-e "$base.zip") {
    die "保存済みZIPが通常のファイルではありません。\n" unless -f "$base.zip";
    # 保存処理はZIPをrenameで置き換える。開いたハンドルから同じ版を読み切る。
    open my $archive, '<:raw', "$base.zip" or die "保存済みZIPを読み込めません。\n";
    die "保存済みZIPが通常のファイルではありません。\n" unless -f $archive;
    $mtime = (stat($archive))[9];
    my $zip = IO::Uncompress::Unzip->new($archive, Strict => 1, Transparent => 0)
      or die "保存済みZIPを読み込めません。\n";
    my $found;
    while (1) {
      my $header = $zip->getHeaderInfo;
      die "保存済みZIPが破損しています。\n" unless $header;
      if (($header->{Name} // '') eq 'data.cgi') {
        die "ZIP内のシートデータが重複しています。\n" if $found;
        $found = 1;
        $raw = '';
        while (1) {
          my $chunk;
          my $count = $zip->read($chunk, 65536);
          die "ZIP内のシートデータが破損しています。\n" if $count < 0;
          last unless $count;
          $raw .= $chunk;
        }
      }
      my $next = $zip->nextStream();
      die "保存済みZIPが破損しています。\n" if $next < 0;
      last unless $next;
    }
    $zip->close or die "保存済みZIPの読込を正常に終了できません。\n";
    close $archive or die "保存済みZIPの読込を正常に終了できません。\n";
    die "ZIPにシートデータがありません。\n" unless $found;
  } else {
    $raw = adminIdCheckReadRaw("$base/data.cgi");
    $mtime = (stat("$base/data.cgi"))[9];
  }
  my $text = eval { decode('UTF-8', $raw, FB_CROAK) };
  die "保存済みシートの文字コードが不正です。\n" if $@;
  my %pc;
  foreach my $line (split /\n/, $text) {
    $line =~ s/\r\z//;
    next if $line eq '';
    my ($key, $value) = split /<>/, $line, 2;
    die "保存済みシートの形式が不正です。\n" if !length($key) || !defined($value) || exists $pc{$key};
    $pc{$key} = CGI::unescapeHTML($value);
  }
  die "保存済みシートのIDが認証台帳と一致しません。\n" unless defined($pc{id}) && $pc{id} eq $id;
  # 通常の保存で必ず記録される作成時刻を確認し、途中で切れたデータを空行として復元しない。
  die "保存済みシートの作成時刻が欠落しているか不正です。\n"
    unless defined($pc{birthTime}) && $pc{birthTime} =~ /\A[0-9]+\z/;
  # グランクレストの計算処理は入力の合計に加算する。保存済みの計算結果を再入力しない。
  if (($set::game // '') eq 'gc' && $record->{type} eq 'chara') {
    delete @pc{qw(expTotal expUsed)};
  }
  my $now = $mtime;
  if (($pc{updateTime} // '') =~ /\A(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})(?::(\d{2}))?\z/) {
    my $epoch = eval { timelocal($6 // 0, $5, $4, $3, $2 - 1, $1) };
    $now = $epoch if defined($epoch) && !$@;
  }
  local $::mode_save = 1;
  local $::file = $file;
  local $::now = $now;
  local $::updatedLine;
  local $::in{type} = $record->{type} eq 'chara' ? '' : $record->{type};
  local *::error = sub { die "calc\n"; };
  local *::setUpdatatLineImage = sub {
    my ($pc) = @_;
    my @images;
    foreach my $n (1 .. $set::image_maxcount) {
      my $s = imageSuffix($n);
      push @images, $n . ($pc->{"imageSpoiler$s"} ? escapeThanSign('+' . $pc->{"imageSpoiler$s"}) : '')
        if $pc->{"image$s"} && !$pc->{"imageHide$s"};
    }
    return join(',', @images);
  };
  my $calculated = eval {
    unless ($calculators->{$config->{calc}}) {
      require $config->{calc};
      $calculators->{$config->{calc}} = \&::dataCalc;
    }
    $calculators->{$config->{calc}}->(\%pc);
    1;
  };
  die "保存済みシートから一覧データを生成できませんでした。\n" unless $calculated;
  my @fields = split /<>/, $::updatedLine // '', -1;
  die "生成された一覧データが不正です。\n"
    if @fields < 5 || $fields[0] ne $id || $fields[1] ne $file
      || $fields[2] !~ /\A[0-9]+\z/ || $fields[3] !~ /\A[0-9]+\z/ || $::updatedLine =~ /[\r\n]/;
  return $::updatedLine;
}

1;
