################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group name player exp-min exp-max factor belong missing image
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  player  => 5,
  group   => 6,
  factor  => 7,
  core    => 8,
  style   => 9,
  gender  => 10,
  age     => 11,
  ageapp  => 12,
  belong  => 13,
  missing => 14,
  level   => 15,
  session => 16,
  image   => 17,
  tags    => 18,
  hide    => 17,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type => '',
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
@lines = filterContainsRegex(lines => \@lines, key => 'belong', query => $_) foreach split /\s/,$::in{belong};
@lines = filterContainsRegex(lines => \@lines, key => 'missing', query => $_) foreach split /\s/,$::in{missing};

## ファクター検索
foreach my $q (split /\s/,$::in{factor}) { @lines = grep { /^(?:[^<]*<>){7,8}[^<]*?\Q$q\E/ } @lines; }

### ソート --------------------------------------------------
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
      TYPE   => $pc{factor},
      HIDE   => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
  ## 通常リスト
  else {
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID      => $pc{id},
      NAME    => renderCharacterName($pc{name}),
      PLAYER  => $pc{player},
      GROUP   => $pc{group},
      AGE     => renderAge(($pc{ageapp} ? "$pc{ageapp}／" : '') . $pc{age}),
      GENDER  => renderGender($pc{gender}),
      FACTOR  => $pc{factor},
      FACTORS => $pc{core}.'／'.$pc{style},
      BELONG  => $pc{belong},
      MISSING => $pc{missing},
      LEVEL   => $pc{level},
      TAGS    => renderTagLinks($pc{tags}, $pc{session}),
      DATE    => renderUpdateTime($pc{date}),
      HIDE    => $pc{hide},
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
  [ $::in{level},  '強度「%s」' ],
  [ $::in{factor}, 'ファクター「%s」' ],
  [ $::in{belong}, '所属「%s」' ],
  [ $::in{missing},'喪失／欠落「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
