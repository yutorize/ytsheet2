################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

# グループがないので、simpleindexを強制的に0にする
if($set::simpleindex){
  $set::simpleindex = 0;
}
### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group image name author stage etype works breed syndrome hp init armor encroach
);
setFields({
  id        => 0,
  date      => 3,
  name      => 4,
  author    => 5,
  group     => 6,
  image     => 7,
  tags      => 8,
  hide      => 9,
  etype     => 10,
  stage     => 11,
  syndrome  => 12,
  hp        => 13,
  init      => 14,
  armor     => 15,
  encroach  => 16,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type => 'e',
  typeName => 'エネミー',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
  excludeFromQLinks => { group => 1 },
);
my %groups = setupGroupList();

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
@lines = filterGroup(@lines)  if $::in{group} && $::in{group} ne 'all';
@lines = filterTag(@lines)    if $::in{tag};
@lines = filterImage(@lines)  if $::in{image};
@lines = filterGender(@lines) if $::in{gender};
@lines = filterContainsRegex(lines => \@lines, key => 'name', flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'author', flags => 'i') if $::in{author};
@lines = filterContainsRegex(lines => \@lines, key => 'etype', flags => 'i') if $::in{etype};
@lines = filterContainsRegex(lines => \@lines, key => 'syndrome', query => $_) foreach split /\s/,$::in{syndrome};
@lines = filterContainsRegex(lines => \@lines, key => 'stage') if $::in{stage};

## ブリード検索
$INDEX->param(Breeds => [makeSelectOptions(
  values   => [ [1, 'ピュア'], [2, 'クロス'], [3, 'トライ'] ],
  selected => $::in{breed},
  nameOf   => sub { $_[0]->[1] },
)]);
if($::in{breed}){
  if   ($::in{breed} == 1){ @lines = grep { m{^(?:[^<]*<>){12}[^/]+//<}           } @lines; $::in{breed} = 'ピュア'; }
  elsif($::in{breed} == 2){ @lines = grep { m{^(?:[^<]*<>){12}[^/]+/[^/]+/<}      } @lines; $::in{breed} = 'クロス'; }
  elsif($::in{breed} == 3){ @lines = grep { m{^(?:[^<]*<>){12}[^/]+/[^/]+/[^<]+<} } @lines; $::in{breed} = 'トライ'; }
}

### ソート --------------------------------------------------
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name'  ){ my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'author'){ my @t = map { capField($_,'author') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date'  ){ my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'age'   ){ my @t = map { capField($_,'age')    } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
}

### リストを回す --------------------------------------------------
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines => \@lines,
  selectedGroup => 'すべて',
  hasTagQuery   => $::in{tag},
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };

  next if $shouldSkip->(
    group => 'すべて',
  );

  ## シンプルリスト
  if($indexMode && $set::simplelist){
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID     => $pc{id},
      NAME   => renderCharacterName($pc{name}),
      AUTHOR => $pc{author},
      GROUP  => $pc{group},
      HIDE   => $pc{hide},
    });
    push(@{$groupedLists{'すべて'}}, @characters);
  }
  ## 通常リスト
  else {
    #シンドローム
    my @syndromes = map { "<span>$_</span>" } split '/', $pc{syndrome} =~ s#(^|/)その他:#$1#gr;
    my @dloises   = map { "<span>$_</span>" } split '/', $pc{dlois};
    
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID       => $pc{id},
      NAME     => renderCharacterName($pc{name}),
      AUTHOR   => $pc{author},
      GROUP    => $pc{group},
      TYPE     => $pc{etype},
      SYNDROME => join('', @syndromes),
      STAGE    => $pc{stage},
      TAGS     => renderTagLinks($pc{tags}, $pc{session}),
      DATE     => renderUpdateTime($pc{date}),
      HIDE     => $pc{hide},
    });
    push(@{$groupedLists{'すべて'}}, @characters);
  }
}

### テンプレートへ入力 ###############################################################################
our @categories = ( ['すべて'] );
$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => \@categories,
  groupedLists => \%groupedLists,
  count => $count,
  
  makePager => sub {
    my (%args) = @_;

    return makePager(
      count     => $args{count},
      page      => $page,
      enabled   => ($args{id} || $::in{mode} eq 'mylist'),
      queryBase => "type=e$qLinks",
    );
  },

  makeGroup => sub {
    my (%args) = @_;
    my $id = $args{id};

    return {
      NAME  => $args{id},
      NUM   => $args{num},
      Lines => $args{lines},
      PAGER => $args{pager},
      MORE  => $args{more},
    };
  },
) ]);

## 検索サマリー --------------------------------------------------
setSearchSummary(
  [ $::in{enemyType},'種別「%s」' ],
  [ $::in{breed},    'ブリード「%s」' ],
  [ $::in{syndrome}, 'シンドローム「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
