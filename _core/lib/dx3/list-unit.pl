################## ユニット一覧 ##################
use strict;
use utf8;
use open ":utf8";
use HTML::Template;
require $set::lib_list;

### クエリ ###########################################################################################
my @queryKeys = qw/mode tag group name player subtype leader/;
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  player  => 5,
  group   => 6,
  tags    => 7,
  hide    => 8,
  subtype => 9,
  leader  => 10,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type => 'u',
  typeName => 'ユニットシート'
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
@lines = filterTag(@lines) if $::in{tag};
foreach my $key (qw/name player member leader/){
  @lines = filterContainsRegex(lines => \@lines, key => $key, flags => 'i') if $::in{$key};
}
### ソート --------------------------------------------------
if($::in{sort}){
  my $sort = $::in{sort};
  if($sort eq 'name'){
    my @keys = map { sortKeyName($_) } @lines;
    @lines = @lines[sort { $keys[$a] cmp $keys[$b] } 0 .. $#keys];
  }
  elsif($sort eq 'pl'){
    my @keys = map { capField($_, 'player') } @lines;
    @lines = @lines[sort { $keys[$a] cmp $keys[$b] } 0 .. $#keys];
  }
  elsif($sort eq 'date'){
    my @keys = map { capField($_, 'date') } @lines;
    @lines = @lines[sort { $keys[$b] <=> $keys[$a] } 0 .. $#keys];
  }
}
### リストを回す --------------------------------------------------
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines => \@lines,
  selectedGroup => $::in{group},
  hasTagQuery => $::in{tag},
  countExtraOf => $set::playerlist ? sub { capField($_[0], 'player') } : undef,
);
my %groupedLists;
foreach (@$pageLines){
  my %pc = %{ splitField($_) };
  $pc{group} = $set::group_default if !$pc{group} || !$groups{$pc{group}};
  $pc{group} = 'all' if $::in{group} eq 'all';
  next if $shouldSkip->(group => $pc{group}, extra => $pc{player});
  push @{$groupedLists{$pc{group}}}, {
    ID     => $pc{id},
    NAME   => renderCharacterName($pc{name}),
    PLAYER => $pc{player},
    GROUP  => $pc{group},
    MEMBER => $pc{member},
    LEADER => $pc{leader},
    TAGS   => renderTagLinks($pc{tags}),
    DATE   => renderUpdateTime($pc{date}),
    HIDE   => $pc{hide},
  };
}
### テンプレートへ入力 ###############################################################################
$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => [ sort { $groups{$a}{sort} <=> $groups{$b}{sort} } keys %groupedLists ],
  groupedLists => \%groupedLists,
  count => $count,
  makePager => sub {
    my (%args) = @_;
    return makePager(
      count => $args{count}, page => $page,
      enabled => ($args{id} || $::in{mode} eq 'mylist'),
      queryBase => "type=u&group=$::in{group}$qLinks",
    );
  },
  makeGroup => \&makeCharacterGroup,
) ]);

## 検索サマリー --------------------------------------------------
setSearchSummary(
  [ $::in{leader}, 'リーダー「%s」' ],
);
### 出力 #############################################################################################
printFinalizedList();

1;
