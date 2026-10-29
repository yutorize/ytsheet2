use strict;
use warnings;
use utf8;
use FindBin;
use JSON::PP;
use Test::More;

my $builder = Test::More->builder;
binmode($_, ':encoding(UTF-8)') for ($builder->output, $builder->failure_output, $builder->todo_output);

sub renderList {
  my ($game, %args) = @_;
  open(my $child, '-|', $^X, "$FindBin::Bin/lib/render-list.pl", encode_json({game => $game, %args})) or die $!;
  my $output = do { local $/; <$child> };
  close $child or die "List rendering failed: $?";
  return decode_json($output);
}
sub rows {
  return [map { @{$_->{rows}} } @{$_[0]{groups}}];
}

for my $game (qw(ar2e dx3 gc ms)) {
  subtest "$game: 設定なし・空の設定" => sub {
    my $top = renderList($game, pagemax => 2, listMaxline => 3, simplelist => 1);
    is($top->{group}, 'all', '集約先はすべて');
    is($top->{modeIndex}, 1, '初期表示はトップページ');
    is($top->{simpleList}, 1, '簡易一覧を維持');
    is($top->{indexMessage}, 1, 'トップ用メッセージを維持');
    is($top->{searchSummary}, undef, '初期表示を検索結果にしない');
    unlike($top->{canonicalURL}, qr/group=/, '暗黙のグループをcanonical URLに加えない');
    is_deeply(rows($top), [qw(A1 A2 B1)], 'トップの表示上限を適用し、pagemaxでは切り出さない');
    is($top->{groups}[0]{count}, 6, '表示上限を超えた分も集計');
    is($top->{groups}[0]{name}, 'すべて', '見出しはすべて');
    is($top->{groups}[0]{more}, 1, 'MOREリンクを残す');
    is($top->{groups}[0]{pager}, '', 'トップにページャーを出さない');
    is_deeply($top->{options}, [], '共通のPC・NPCを引き継がない');
    unlike($top->{optionsHtml}, qr/value="(?:pc|npc)"/, '検索フォームに無効な選択肢を出さない');

    my $empty = renderList($game, groupSettings => [], pagemax => 2, listMaxline => 3, simplelist => 1);
    is_deeply($empty, $top, '未定義と空配列で同じ動作');
    my $simple = renderList($game, simpleindex => 1);
    is($simple->{simpleIndex}, 1, '簡易トップを維持');
    is_deeply(rows($simple), [], '簡易トップでは一覧データを出さない');
    like($simple->{indexHtml}, qr/group=all/, '簡易トップからすべてに進める');
    unlike($simple->{indexHtml}, qr/group=(?:pc|npc)/, '簡易トップにも無効なリンクを出さない');
    my $fromSimple = renderList($game, simpleindex => 1, query => {group => 'all'});
    is_deeply(rows($fromSimple), [qw(A1 A2 B1 B2 L1 E1)], '簡易トップのリンク先では一覧を表示');

    my $all = renderList($game, query => {group => 'all'});
    is_deeply(rows($all), [qw(A1 A2 B1 B2 L1 E1)], '未分類・旧グループもすべてに集約');
    is($all->{modeIndex}, 0, '明示指定は検索ページ');
    is_deeply($all->{groups}[0]{rowGroups}, [('all') x 6], '各行もすべてに統一');
    for my $group ('pc', 'npc', 'missing') {
      is_deeply(renderList($game, query => {group => $group}), $all, "$group の指定もすべてとして扱う");
    }
    my $blank = renderList($game, query => {group => '  '}, pagemax => 2, listMaxline => 3, simplelist => 1);
    is_deeply($blank, $top, '空白の指定は初期表示として扱う');

    for my $page (1 .. 3) {
      my $result = renderList($game, pagemax => 2, listMaxline => 1, query => {group => 'all', page => $page});
      my @expected = ([qw(A1 A2)], [qw(B1 B2)], [qw(L1 E1)]);
      is_deeply(rows($result), $expected[$page-1], "検索ページ$page の切り出し");
      is($result->{groups}[0]{count}, 6, '全ページで総件数を維持');
      is_deeply($result->{groups}[0]{players}, {Alice => 2, Bob => 2, Carol => 1, Eve => 1}, 'PLの集計を維持');
      like($result->{groups}[0]{pager}, qr/group=all/, 'ページャーもすべてを維持');
    }
    my $search = renderList($game, pagemax => 2, listMaxline => 1, query => {name => 'Name-B'});
    is_deeply(rows($search), [qw(B1 B2)], 'グループ未指定の検索もトップ上限で欠落しない');
    is($search->{modeIndex}, 0, '名前の指定は検索ページ');
    is_deeply(rows(renderList($game, query => {player => 'Alice'})), [qw(A1 A2)], 'PL名検索');
    is_deeply(rows(renderList($game, query => {tag => 'demo'})), [qw(A1 B1 H1)], 'タグ検索時の非表示データの扱いを維持');
    is_deeply(rows(renderList($game, pagemax => 2, query => {mode => 'mylist', page => 2})), ['H1'], 'マイリストをページ分割できる');
    is_deeply(rows(renderList($game, query => {sort => 'date'})), [qw(E1 L1 B2 B1 A2 A1)], '更新日時のソートを維持');
    is_deeply(rows(renderList($game, empty => 1, pagemax => 2)), [], '登録なしでも正常に表示');
    is(scalar @{rows(renderList($game, admin => 1))}, 8, '管理者には非表示データも表示');
    is(scalar @{rows(renderList($game, guest => 1))}, 6, 'ゲストには非表示データを表示しない');
    if ($game eq 'dx3') {
      is_deeply(rows(renderList($game, query => {subtype => 'company'})), [qw(A2 B2 E1)], 'ユニットの種別検索');
    }
    else {
      is_deeply(rows(renderList($game, query => {image => 1})), [qw(A1 B1 L1)], '画像条件を維持');
    }
  };

  subtest "$game: 専用設定あり" => sub {
    my @settings = ([alpha => '01', '専用A', '説明A'], [beta => '02', '専用B', '説明B']);
    my %args = (groupSettings => \@settings, customRows => 1);
    my $top = renderList($game, %args);
    is($top->{modeIndex}, 1, '専用設定ありでもトップ表示');
    is_deeply([map { $_->{ID} } @{$top->{options}}], [qw(alpha beta)], '専用の選択肢');
    is_deeply([map { $_->{name} } @{$top->{groups}}], ['専用A', '専用B'], '専用の見出し');
    my $result = renderList($game, %args, pagemax => 2, query => {group => 'alpha', page => 2});
    is($result->{group}, 'alpha', '指定グループを上書きしない');
    is_deeply(rows($result), [qw(L1 E1)], '専用グループを絞り込んでページ分割');
    is($result->{groups}[0]{count}, 4, '専用グループの総件数');
    is($result->{groups}[0]{name}, '専用A', '検索結果にも専用の見出し');
    like($result->{groups}[0]{pager}, qr/group=alpha/, '専用グループをページャーで維持');
    my $simple = renderList($game, %args, simpleindex => 1);
    like($simple->{indexHtml}, qr/group=alpha/, '簡易トップに専用グループへのリンク');

    my %legacyArgs = (%args, storedGroups => {L1 => 'retired', E1 => ''});
    my $legacyTop = renderList($game, %legacyArgs);
    is_deeply([map { $_->{id} } @{$legacyTop->{groups}}], [qw(alpha beta)], '既定IDが専用設定にない場合も空見出しを作らない');
    is_deeply($legacyTop->{groups}[0]{rows}, [qw(A1 A2 L1 E1)], '未分類・廃止済みIDを専用設定の先頭に補正');
    is($legacyTop->{groups}[0]{name}, '専用A', '補正先の見出しを表示');
    my $legacySearch = renderList($game, %legacyArgs, pagemax => 2, query => {group => 'alpha', page => 2});
    is_deeply(rows($legacySearch), [qw(L1 E1)], '補正した行を検索結果のページ分割でも取得できる');
    is($legacySearch->{groups}[0]{count}, 4, '補正後の総件数と検索件数を揃える');
    is_deeply($legacySearch->{groups}[0]{rowGroups}, [qw(alpha alpha)], '検索後の各行も同じIDに補正');
    my $defaultSearch = renderList($game, %legacyArgs, defaultGroup => 'beta', query => {group => 'beta'});
    is_deeply(rows($defaultSearch), [qw(B1 B2 L1 E1)], '設定内にある既定IDは先頭より優先する');
    is($defaultSearch->{groups}[0]{name}, '専用B', '有効な既定IDの見出しを保持');
    my $invalidSearch = renderList($game, %legacyArgs, query => {group => 'retired'});
    is_deeply(rows($invalidSearch), [], '削除済みの検索IDを表示グループとして復活させない');

    my $allDescription = renderList($game,
      groupSettings => [['all', '77', '全体', '保持すべき説明']],
      query => {group => 'all'},
    );
    is($allDescription->{groups}[0]{text}, '保持すべき説明', '設定済みのすべての説明文を保持');
  };

  subtest "$game: PL集計とソートの併用" => sub {
    my @sorts = ('date', 'pl');
    push @sorts, $game eq 'gc' ? 'level' : 'lv' if $game ne 'dx3';
    my $expectedPlayers = {Alice => 2, Bob => 2, Carol => 1, Eve => 1};
    for my $sort (@sorts) {
      for my $explicitGroup (0, 1) {
        my %query = (name => 'Name-', sort => $sort);
        $query{group} = 'all' if $explicitGroup;
        my $result = renderList($game, pagemax => 2, query => \%query);
        my $expectedRows = $sort eq 'pl' ? [qw(A1 A2)] : [qw(E1 L1)];
        is_deeply(rows($result), $expectedRows, "$sort 順の検索結果を正しく切り出す（明示指定=$explicitGroup）");
        is_deeply($result->{groups}[0]{players}, $expectedPlayers, "$sort 順でもPL名で全件を集計する（明示指定=$explicitGroup）");
      }
    }
    my $secondPage = renderList($game, pagemax => 2, query => {name => 'Name-', sort => 'date', page => 2});
    is_deeply(rows($secondPage), [qw(B2 B1)], '日時順の2ページ目も正しく切り出す');
    is_deeply($secondPage->{groups}[0]{players}, $expectedPlayers, '2ページ目でも全件のPL集計を保持');
    my $normalized = renderList($game, pagemax => 2, customRows => 1,
      groupSettings => [['alpha', '01', '専用A', ''], ['beta', '02', '専用B', '']],
      storedGroups => {L1 => 'retired', E1 => ''}, query => {group => 'alpha', sort => 'date'},
    );
    is_deeply(rows($normalized), [qw(E1 L1)], '補正したグループでも日時順の一覧を保持');
    is_deeply($normalized->{groups}[0]{players}, {Alice => 2, Carol => 1, Eve => 1}, 'グループ補正・ソート後もPL名で全件を集計');
    my $disabled = renderList($game, playerlist => 0, pagemax => 2, query => {name => 'Name-', sort => 'date'});
    is_deeply(rows($disabled), [qw(E1 L1)], 'PL集計が無効でも検索・ソートを保持');
    is_deeply($disabled->{groups}[0]{players}, {}, '無効時はPL集計を実行しない');
  };
}

subtest '通常のキャラクター一覧' => sub {
  my $result = renderList('ms', character => 1);
  is($result->{modeIndex}, 1, 'トップ表示を維持');
  is_deeply([map { $_->{ID} } @{$result->{options}}], [qw(pc npc)], '共通グループを維持');
  is_deeply([map { $_->{id} } @{$result->{groups}}], [qw(pc npc)], 'PC・NPC別の集約を維持');
  my $all = renderList('ms', character => 1,
    baseGroupSettings => [['pc', '01', 'ＰＣ', ''], ['all', '77', '全体', '共通設定の説明']],
    query => {group => 'all'},
  );
  is($all->{groups}[0]{text}, '共通設定の説明', '通常一覧でもすべての説明文を保持');
};

subtest '通常のキャラクター一覧: 旧グループIDの検索' => sub {
  for my $playerlist (0, 1) {
    for my $pagemax (0, 1) {
      my %args = (
        character => 1, playerlist => $playerlist, pagemax => $pagemax,
        storedGroups => {E1 => 'legacy'},
      );
      my $first = renderList('ms', %args, query => {group => 'legacy'});
      is_deeply(rows($first), $pagemax ? ['L1'] : [qw(L1 E1)], "旧IDの検索結果を表示（pagemax=$pagemax、PL集計=$playerlist）");
      is($first->{groups}[0]{id}, 'legacy', '集計と表示に同じ旧IDを使用');
      is($first->{groups}[0]{count}, 2, '旧IDの検索対象を全件集計');
      is_deeply($first->{groups}[0]{players}, ($playerlist || !$pagemax) ? {Carol => 1, Eve => 1} : {}, 'PL集計の従来動作を維持');
      if ($pagemax) {
        like($first->{groups}[0]{pager}, qr/group=legacy.*page=2/, 'ページャーで旧IDを維持');
        my $second = renderList('ms', %args, query => {group => 'legacy', page => 2});
        is_deeply(rows($second), ['E1'], '旧IDの2ページ目を表示');
        is($second->{groups}[0]{count}, 2, '2ページ目でも総件数を維持');
        is_deeply($second->{groups}[0]{rowGroups}, ['legacy'], '2ページ目も同じ旧IDに分類');
      }
    }
  }
};

done_testing();
