################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

require $set::lib_list;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group name player class style works image
);
setFields({
  id       => 0,
  date     => 3,
  name     => 4,
  player   => 5,
  group    => 6,
  image    => 7,
  tags     => 8,
  hide     => 9,
  class    => 10,
  style    => 11,
  substyle => 12,
  works    => 13,
  level    => 14,
  exp      => 15,
  country  => 16,
  gender   => 17,
  age      => 18,
  height   => 19,
  weight   => 20,
  session  => 21,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type     => '',
  typeName => 'キャラクター',
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
@lines = filterContainsRegex(lines => \@lines, key => 'class', query => $_) foreach split /\s/,$::in{class};
@lines = filterContainsRegex(lines => \@lines, key => 'style', query => $_) foreach split /\s/,$::in{style};
@lines = filterContainsRegex(lines => \@lines, key => 'works', query => $_) foreach split /\s/,$::in{works};

### ソート ###########################################################################################
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name'){ my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'pl')  { my @t = map { capField($_,'player') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date'){ my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'level'){ my @t = map { capField($_,'level') } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
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
      LV     => $pc{level},
      HIDE   => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
  ## 通常リスト
  else {
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID       => $pc{id},
      NAME     => renderCharacterName($pc{name}),
      PLAYER   => $pc{player},
      GROUP    => $pc{group},
      CLASS    => $pc{class},
      STYLE    => thinIfLong($pc{style}, 8),
      WORKS    => thinIfLong($pc{works}, 8),
      LV       => $pc{level},
      EXP      => $pc{exp},
      COUNTRY  => $pc{country},
      GENDER   => renderGender($pc{gender}),
      AGE      => renderAge($pc{age}),
      HEIGHT   => $pc{height},
      WEIGHT   => $pc{weight},
      TAGS     => renderTagLinks($pc{tags}, $pc{session}),
      DATE     => renderUpdateTime($pc{date}),
      HIDE     => $pc{hide},
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
  [ $::in{class},  'クラス「%s」' ],
  [ $::in{style},  'スタイル「%s」' ],
  [ $::in{works},  'ワークス「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
