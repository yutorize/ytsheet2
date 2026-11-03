################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group image name author taxon element mob lv-min lv-max
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  author  => 5,
  group   => 6,
  image   => 7,
  tags    => 8,
  hide    => 9,
  taxon   => 10,
  element => 11,
  lv      => 12,
  mob     => 13,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type     => 'e',
  typeName => 'エネミー',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
  excludeFromQLinks => { group => 1 },
  groupList => \@set::groups_enemy,
);
my %groups = setupGroupList(\@set::groups_enemy);

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
@lines = filterGroup(@lines) if $::in{group} && $::in{group} ne 'all';
@lines = filterTag(@lines)   if $::in{tag};
@lines = filterImage(@lines) if $::in{image};
@lines = filterContainsRegex(lines => \@lines, key => 'name', flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'author', flags => 'i') if $::in{author};
@lines = filterContainsRegex(lines => \@lines, key => 'taxon', flags => 'i') if $::in{taxon};
@lines = filterContainsRegex(lines => \@lines, key => 'element', flags => 'i') if $::in{element};
@lines = filterFlagRegex(lines => \@lines, key => 'mob') if $::in{mob};

@lines = filterRange(
  lines => \@lines,
  key => 'lv',
) if hasInteger($::in{'lv-min'}, $::in{'lv-max'});

### ソート ###########################################################################################
### ソート --------------------------------------------------
if($::in{sort}){
  if($::in{sort} eq 'name'){
    my @keys = map { sortKeyName($_) } @lines;
    @lines = @lines[sort { $keys[$a] cmp $keys[$b] } 0 .. $#keys];
  }
  elsif($::in{sort} eq 'author'){
    my @keys = map { capField($_, 'author') } @lines;
    @lines = @lines[sort { $keys[$a] cmp $keys[$b] } 0 .. $#keys];
  }
  elsif($::in{sort} eq 'date'){
    my @keys = map { capField($_, 'date') } @lines;
    @lines = @lines[sort { $keys[$b] <=> $keys[$a] } 0 .. $#keys];
  }
  elsif($::in{sort} eq 'lv'){
    my @keys = map { capField($_, 'lv') } @lines;
    @lines = @lines[sort { $keys[$a] <=> $keys[$b] } 0 .. $#keys];
  }
}

### ページ処理 #######################################################################################
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines => \@lines,
  selectedGroup => $indexMode ? '' : $::in{group},
  hasTagQuery   => $::in{tag},
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };
  $pc{group} = normalizeListGroup($pc{group});
  
  next if $shouldSkip->(
    group => $pc{group},
  );
  
  ## シンプルリスト
  if($indexMode && $set::simplelist){
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID     => $pc{id},
      NAME   => renderCharacterName($pc{name}),
      PLAYER => $pc{author},
      GROUP  => $pc{group},
      LV     => $pc{lv},
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
      PLAYER  => $pc{author},
      GROUP   => $pc{group},
      TAXON   => $pc{taxon},
      LV      => $pc{lv},
      TYPE    => ($pc{mob} ? 'モブ' : 'ソロ'),
      ELEMENT => $pc{element},
      TAGS    => renderTagLinks($pc{tags}, $pc{session}),
      DATE    => renderUpdateTime($pc{date}),
      HIDE    => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
}

### テンプレートへ入力 ###############################################################################
$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => [ sort { $groups{$a}{sort} <=> $groups{$b}{sort} } keys %{ $count->{PC} } ],
  groupedLists => \%groupedLists,
  count => $count,
  
  makePager => sub {
    my (%args) = @_;

    return makePager(
      count     => $args{count},
      page      => $page,
      enabled   => ($args{id} || $::in{mode} eq 'mylist'),
      queryBase => "type=e&group=$::in{group}$qLinks",
    );
  },

  makeGroup => \&makeCharacterGroup,
) ]);

## 検索サマリー --------------------------------------------------
setSearchSummary(
  { nameHeader => '名称' },
  [ $::in{taxon},  '分類「%s」' ],
  [ $::in{element},'属性「%s」' ],
  [ $::in{lv},     'レベル「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
