use strict;
use warnings;
use utf8;
use FindBin;
use JSON::PP;
use Test::More;

my $builder = Test::More->builder;
binmode($_, ':encoding(UTF-8)') for ($builder->output, $builder->failure_output, $builder->todo_output);

sub renderEnemy {
  my (%args) = @_;
  open(my $child, '-|', $^X, "$FindBin::Bin/lib/render-list.pl", encode_json({game => 'dx3', enemy => 1, %args})) or die $!;
  my $output = do { local $/; <$child> };
  close $child or die "Enemy list rendering failed: $?";
  return decode_json($output);
}
sub rows {
  return [map { @{$_->{rows}} } @{$_[0]{groups}}];
}

subtest 'トップ表示と共通グループ処理' => sub {
  my $top = renderEnemy(pagemax => 2, listMaxline => 3, simplelist => 1);
  is($top->{group}, 'all', '実効グループはall');
  is($top->{modeIndex}, 1, '初期表示はトップページ');
  is($top->{indexMessage}, 1, 'トップ用メッセージを表示');
  is($top->{simpleList}, 1, '簡易一覧設定を維持');
  is($top->{searchSummary}, undef, '初期表示を検索結果にしない');
  unlike($top->{canonicalURL}, qr/group=/, '暗黙のグループをcanonical URLに加えない');
  is_deeply(rows($top), [qw(A1 A2 B1)], 'トップの表示上限を適用');
  is($top->{groups}[0]{id}, 'all', '内部IDを共通のallに統一');
  is($top->{groups}[0]{name}, 'すべて', '表示名はすべて');
  is($top->{groups}[0]{count}, 6, '表示上限を超える分も集計');
  is($top->{groups}[0]{more}, 1, 'MOREリンクを残す');
  is($top->{groups}[0]{pager}, '', 'トップではページャーを表示しない');
  my ($moreHref) = $top->{enemyHtml} =~ /<p class="more"><a href="([^"]+)"/;
  is($moreHref, './?type=e&group=all', 'MOREリンクはallの検索ページへ進む');
  is_deeply($top->{options}, [], 'キャラクターのPC・NPCを引き継がない');

  my $all = renderEnemy(query => {group => 'all'});
  is_deeply(rows($all), [qw(A1 A2 B1 B2 L1 E1)], '旧グループ・未分類をまとめる');
  is_deeply($all->{groups}[0]{rowGroups}, [('all') x 6], '各行のIDもallに統一');
  for my $group ('pc', 'npc', 'missing') {
    is_deeply(renderEnemy(query => {group => $group}), $all, "$group の指定はすべてとして扱う");
  }
  is($all->{enemyLines}[0]{AUTHOR}, 'Alice', 'データ製作者を維持');
  is($all->{enemyLines}[0]{TYPE}, 'Mエネミー（T）', 'エネミー種別の整形を維持');
  is($all->{enemyLines}[0]{SYNDROME}, '<span>Angel</span>', 'シンドロームの整形を維持');
};

subtest '簡易トップの入口とリンク先' => sub {
  my $simple = renderEnemy(simpleindex => 1);
  is($simple->{simpleIndex}, 1, '簡易トップ設定を強制解除しない');
  is_deeply(rows($simple), [], '簡易トップでは一覧を読み出さない');
  like($simple->{indexHtml}, qr/type=e&group=all/, 'すべてへの入口を表示');
  like($simple->{indexHtml}, qr/すべて/, '入口の表示名を表示');
  like($simple->{enemyHtml}, qr/<input type="hidden" name="group" value="all">/, '検索フォームも明示的にallを指定する');
  my $result = renderEnemy(simpleindex => 1, pagemax => 2, query => {group => 'all'});
  is($result->{modeIndex}, 0, 'リンク先は検索ページ');
  is_deeply(rows($result), [qw(A1 A2)], 'リンク先では通常の一覧を表示');
  like($result->{enemyHtml}, qr/type=e&group=all&sort=date/, 'ソートしても検索ページを維持できる');
};

subtest '検索・ソート・ページ分割' => sub {
  for my $page (1 .. 3) {
    my $result = renderEnemy(pagemax => 2, query => {group => 'all', page => $page});
    my @expected = ([qw(A1 A2)], [qw(B1 B2)], [qw(L1 E1)]);
    is_deeply(rows($result), $expected[$page-1], "ページ$page の切り出し");
    is($result->{groups}[0]{count}, 6, '全ページで総件数を維持');
    like($result->{groups}[0]{pager}, qr/type=e&group=all/, 'ページャーでグループを維持');
  }
  my $sorted = renderEnemy(pagemax => 2, listMaxline => 1, query => {name => 'Name-', sort => 'date', page => 2});
  is_deeply(rows($sorted), [qw(B2 B1)], '日時順で検索・ページ分割');
  is($sorted->{groups}[0]{count}, 6, '検索ページはトップ件数上限に制限されない');
  like($sorted->{groups}[0]{pager}, qr/name=Name(?:-|%2d)/i, '検索条件をページャーに保持');
  like($sorted->{groups}[0]{pager}, qr/sort=date/, 'ソート条件をページャーに保持');
  for my $case (
    [{author => 'Bob'}, [qw(B1 B2)]],
    [{stage => 'Stage A'}, [qw(A1 B1 L1)]],
    [{etype => 'M'}, [qw(A1 B1 L1)]],
    [{syndrome => 'Balor'}, [qw(A2 B1 L1 E1)]],
    [{breed => 1}, [qw(A1 B2)]],
    [{breed => 2}, [qw(A2 L1)]],
    [{breed => 3}, [qw(B1 E1)]],
    [{image => 1}, [qw(A1 B1 L1)]],
    [{tag => 'demo'}, [qw(A1 B1 H1)]],
    [{mode => 'mylist'}, [qw(A1 B1 H1)]],
    [{group => 'all', sort => 'author'}, [qw(A1 A2 B1 B2 L1 E1)]],
  ) {
    is_deeply(rows(renderEnemy(query => $case->[0])), $case->[1], '既存の検索条件・ソートを維持: '.encode_json($case->[0]));
  }
  is_deeply(rows(renderEnemy(empty => 1, pagemax => 2)), [], '登録なしでも正常に表示');
  is(scalar @{rows(renderEnemy(admin => 1))}, 8, '管理者への非表示データ表示を維持');
  is(scalar @{rows(renderEnemy(guest => 1))}, 6, 'ゲストから非表示データを除外');
};

subtest 'グループを省略した旧形式URL' => sub {
  for my $simpleIndex (0, 1) {
    for my $case (
      [{page => 1}, [qw(A1 A2)]],
      [{page => 2}, [qw(B1 B2)]],
      [{sort => 'date'}, [qw(E1 L1)]],
      [{sort => 'date', page => 2}, [qw(B2 B1)]],
    ) {
      my $label = '簡易トップ='.$simpleIndex.' '.encode_json($case->[0]);
      my $result = renderEnemy(pagemax => 2, listMaxline => 1, simplelist => 1,
        simpleindex => $simpleIndex, query => $case->[0],
      );
      is($result->{modeIndex}, 0, "旧URLも検索ページとして扱う: $label");
      is($result->{simpleIndex}, 0, "旧URLでは簡易トップを表示しない: $label");
      is($result->{simpleList}, 0, "旧URLでは通常の検索一覧を表示する: $label");
      is_deeply(rows($result), $case->[1], "指定ページ・ソート順を保持する: $label");
      is($result->{groups}[0]{count}, 6, "総件数を保持する: $label");
      my @links = $result->{groups}[0]{pager} =~ /href="([^"]+)"/g;
      ok(@links > 0, "ページャーを表示する: $label");
      for my $link (@links) {
        like($link, qr/type=e&group=all/, '次のリンクでは明示的にallを保持');
        my $pageCount = () = $link =~ /[?&]page=/g;
        is($pageCount, 1, 'ページ番号を重複させない');
        if ($case->[0]{sort}) {
          my $sortCount = () = $link =~ /[?&]sort=/g;
          is($sortCount, 1, 'ソート指定を重複させない');
          like($link, qr/[?&]sort=date(?:&|$)/, 'ソート順を次のページでも保持');
        }
      }
    }
  }
};

done_testing();
