################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

require $set::lib_list;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group name player lv-min lv-max taxa home origin clan address image
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  player  => 5,
  group   => 6,
  image   => 7,
  tags    => 8,
  hide    => 9,
  session => 10,
  lv         => 11,
  endurance  => 12,
  taxa       => 13,
  home       => 14,
  origin     => 15,
  background => 16,
  clan       => 17,
  clanEmotion=> 18,
  address    => 19,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type     => '',
  typeName => '都民',
  pageTitle => '都民登録書',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
  excludeFromQLinks => { group => 1 },
);
my %groups = setupGroupList();

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
@lines = filterGroup(@lines) if $::in{group} && $::in{group} ne 'all';
@lines = filterTag(@lines)   if $::in{tag};
@lines = filterContainsRegex(lines => \@lines, key => 'name', flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'player', flags => 'i') if $::in{player};
@lines = filterFlagRegex(lines => \@lines, key => 'image') if $::in{image};
@lines = filterContainsRegex(lines => \@lines, key => 'taxa') if $::in{taxa};
@lines = filterContainsRegex(lines => \@lines, key => 'clan') if $::in{clan};

@lines = filterRange(
  lines => \@lines,
  key => 'lv',
  template => $INDEX,
) if hasInteger($::in{'lv-min'}, $::in{'lv-max'});

### ソート ###########################################################################################
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name'){ my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'pl')  { my @t = map { capField($_,'player') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date'){ my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'lv')  { my @t = map { capField($_,'lv')     } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
}

### ページ処理 #######################################################################################
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines => \@lines,
  selectedGroup => $::in{group},
  hasTagQuery   => $::in{tag},
  countExtraOf  => $set::playerlist ? sub {
    my $line = shift;
    return capField($line, 'player');
  } : undef,
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };
  
  #グループ
  $pc{group} = $set::group_default if (!$pc{group} || !$groups{$pc{group}});
  $pc{group} = 'all' if $::in{group} eq 'all';
  
  next if $shouldSkip->(
    group => $pc{group},
    extra => $pc{player},
  );
  
  ## シンプルリスト
  if($indexMode && $set::simplelist){
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID     => $pc{id},
      NAME   => renderCharacterName($pc{name}),
      PLAYER => $pc{player},
      GROUP  => $pc{group},
      LEVEL  => $pc{lv},
      HIDE   => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
  ## 通常リスト
  else {
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID     => $pc{id},
      NAME   => renderCharacterName($pc{name}),
      PLAYER => $pc{player},
      GROUP  => $pc{group},
      LEVEL  => $pc{lv},
      TAXA   => $pc{taxa},
      HOME   => $pc{home},
      ORIGIN => $pc{origin},
      CLAN   => $pc{clan},
      ADDRESS=> $pc{address},
      TAGS   => renderTagLinks($pc{tags}, $pc{session}),
      DATE   => renderUpdateTime($pc{date}),
      HIDE   => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
}

### テンプレートへ入力 ###############################################################################
$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => [ sort { $groups{$a}{sort} <=> $groups{$b}{sort} } keys %groupedLists ],
  groupedLists => \%groupedLists,
  count => $count,
  
  makePager => sub {
    my (%args) = @_;

    return makePager(
      count     => $args{count},
      page      => $page,
      enabled   => ($args{id} || $::in{mode} eq 'mylist'),
      queryBase => "group=$::in{group}$qLinks",
    );
  },

  makeGroup => \&makeCharacterGroup,
) ]);

## 検索サマリー --------------------------------------------------
setSearchSummary(
  { nameHeader => '東京名' },
  [ $::in{taxa}, '分類名に「%s」を含む' ],
  [ $::in{lv}, 'レベル「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
