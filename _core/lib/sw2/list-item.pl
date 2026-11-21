################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

#require $set::data_item;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag image category name author age
);
setFields({
  id       => 0,
  date     => 3,
  name     => 4,
  author   => 5,
  category => 6,
  price    => 7,
  age      => 8,
  summary  => 9,
  type     => 10,
  image    => 11,
  tags     => 12,
  hide     => 13,
});

### テンプレート読み込み #############################################################################
$set::simplelist = 0; # アイテムは簡易表示なし
$set::simpleindex = 0; # アイテムは簡易インデックスなし
my $INDEX = setupListTemplate(
  type     => 'i',
  typeName => 'アイテム',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
);

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
@lines = filterTag(@lines)   if $::in{tag};
@lines = filterImage(@lines) if $::in{image};
@lines = filterContainsRegex(lines => \@lines, key => 'author', flags => 'i') if $::in{author};
@lines = filterContainsRegex(lines => \@lines, key => 'age') if $::in{age};

## 名称とカテゴリ
if($::in{category} eq 'all'){
  $::in{category} = '';
}
my @categoryQuery = split(/\s+/, $::in{category});
$INDEX->param(category => "@categoryQuery");
my @categoryTerms = map {
  my $term = $_;
  my $exclude = $term =~ s/^-//;
  [$exclude, qr/\Q$term\E/];
} @categoryQuery;
my $namePattern = $::in{name} ne '' ? qr/\Q$::in{name}\E/i : undef;
if($namePattern || @categoryTerms){
  @lines = grep { matchItemListSearch(splitField($_), $namePattern, \@categoryTerms) } @lines;
}

sub matchItemListSearch {
  my ($row, $namePattern, $categoryTerms) = @_;
  if($namePattern){
    return 0 unless grep { /$namePattern/ } splitItemListValues($row->{name}, $row->{type});
  }
  return 1 unless @$categoryTerms;

  my @categories = splitItemListValues($row->{category}, $row->{type});
  foreach my $term (@$categoryTerms){
    my ($exclude, $pattern) = @$term;
    my $matches = grep { /$pattern/ } @categories;
    return 0 if $exclude ? $matches : !$matches;
  }
  return 1;
}

### ソート --------------------------------------------------
if($::in{sort}){
  my $s = $::in{sort};
  if($s eq 'name'){
    my @titles = map {
      my $row = splitField($_);
      (splitItemListValues($row->{name}, $row->{type}))[0];
    } @lines;
    @lines = @lines[sort { $titles[$a] cmp $titles[$b] } 0 .. $#titles];
  }
  elsif($s eq 'author'){ my @t = map { capField($_,'author') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date')  { my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
}
### ページ処理 #######################################################################################
if($indexMode && $set::list_maxline) { $set::pagemax = $set::list_maxline; }
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines         => \@lines,
  selectedGroup => 'すべて',
  hasTagQuery   => $::in{tag},
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };

  next if $shouldSkip->(
    group => 'すべて',
  );
  
  #名称とカテゴリの表示
  ($pc{name}) = splitItemListValues($pc{name}, $pc{type});
  $pc{category} = commonItemListCategory(splitItemListValues($pc{category}, $pc{type})) // 'さまざま';
  $pc{category} =~ s/[ 　]/<br>/g;

  #価格
  $pc{price} = commify($pc{price}) if $pc{price} =~ /\d{4,}/;
  $pc{price} =~ s/[+＋\/／]/<wbr>$&<wbr>/g;
  
  #出力用配列へ
  my @items;
  push(@items, {
    ID       => $pc{id},
    NAME     => $pc{name},
    AUTHOR   => $pc{author},
    CATEGORY => $pc{category},
    PRICE    => $pc{price},
    AGE      => $pc{age},
    SUMMARY  => $pc{summary},
    MAGIC    => ($pc{type} =~ /\[ma\]/ ? "<img class=\"${set::icon_dir}item_magic.png\">" : ''),
    TAGS     => renderTagLinks($pc{tags}),
    DATE     => renderUpdateTime($pc{date}),
    HIDE     => $pc{hide},
  });
  
  push(@{$groupedLists{'すべて'}}, @items);
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
      enabled   => 1,
      queryBase => "type=i$qLinks",
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
  { nameHeader => '名称' },
  [ $::in{category}, 'カテゴリ「%s」' ],
  [ $::in{age},      '製作時期「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
