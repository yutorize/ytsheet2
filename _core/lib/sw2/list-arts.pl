################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

my $mode = $::in{mode};
my $sort = $::in{sort};

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag image category name author sub
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  author  => 5,
  category => 6,
  sub      => 7,
  summary  => 8,
  image    => 9,
  tags     => 10,
  hide     => 11,
});

### テンプレート読み込み #############################################################################
$set::simplelist = 0; # 魔法は簡易表示なし
$set::simpleindex = 0; # 魔法は簡易インデックスなし
my $INDEX = setupListTemplate(
  type     => 'a',
  typeName => '魔法/神格/流派/特殊能力',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
  excludeFromQLinks => { category => 1 },
);

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
## カテゴリ検索 --------------------------------------------------
my %categories = (magic => '魔法', god => '神格', school => '流派', skill => '特殊能力', all => 'すべて');
if($::in{category} && $::in{category} ne 'all'){
  @lines = grep { /^(?:[^<]*<>){6}\Q$::in{category}\E</o } @lines;
  $INDEX->param(category => $categories{$::in{category}});
}
$INDEX->param(Categories => [makeSelectOptions(
  values   => [qw(magic god school skill)],
  selected => $::in{category},
  nameOf   => sub { $categories{$_[0]} },
)]);


@lines = filterTag(@lines)   if $::in{tag};
@lines = filterImage(@lines) if $::in{image};
@lines = filterContainsRegex(lines => \@lines, key => 'sub') if $::in{sub};
@lines = filterContainsRegex(lines => \@lines, key => 'name', flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'author', flags => 'i') if $::in{author};

### ソート --------------------------------------------------
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name')  { my @t = map { capField($_,'name')   } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'author'){ my @t = map { capField($_,'author') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date')  { my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
}
### ページ処理 #######################################################################################
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines         => \@lines,
  selectedGroup => $::in{category},
  hasTagQuery   => $::in{tag},
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };

  #分類
  my $renderCategory = $categories{$pc{category}};
  if($pc{sub} =~ /(?:属性|特殊)妖精魔法|秘奥魔法/){ $pc{sub} =~ s#／([0-9]+)#／ランク$1#; }
  else { $pc{sub} =~ s#(／[0-9-～]+)#$1レベル#; }
  $pc{sub} = '―' if $pc{category} eq 'skill';
  $pc{category} = 'all' if $::in{category} eq 'all';
  
  next if $shouldSkip->(
    group => $pc{category},
  );
  
  #名前
  if($pc{category} =~ /magic|school/){
    (my $divineMark, $pc{name}) = extractDivineMark($pc{name}) if $pc{category} =~ /magic/ && $pc{sub} =~ /神聖魔法/;
    $pc{name} = '【'.$pc{name}.'】';
    $pc{name} =~ s/\s?[－―‐–—─\-](.+?)[－―‐–—─\-]】$/】<span>－$1－<\/span>/;
    $pc{name} = $divineMark.$pc{name} if defined $divineMark;
  }

  #サブ分類
  
  #出力用配列へ
  my @characters;
  push(@characters, {
    "ID" => $pc{id},
    "NAME" => $pc{name},
    "AUTHOR" => $pc{author},
    "CATEGORY" => thinIfLong($renderCategory, 4),
    "SUB" => renderSub($pc{sub}),
    "SUMMARY" => $pc{summary},
    "TAGS"   => renderTagLinks($pc{tags}, $pc{session}),
    "DATE"   => renderUpdateTime($pc{date}),
    "HIDE" => $pc{hide},
  });
  
  push(@{$groupedLists{$pc{category}}}, @characters);
}
sub renderSub {
  my @texts = split('／', shift);
  foreach(@texts){
    s/(\p{Han}+)/<wbr>$1<wbr>/g;
    $_ = "<span>$_</span>";
  }
  return '<div>'.join('／', @texts).'</div>';
}

### テンプレートへ入力 ###############################################################################
$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => [qw(magic god school skill all)],
  groupedLists => \%groupedLists,
  count => $count,

  makePager => sub {
    my (%args) = @_;

    return makePager(
      count     => $args{count},
      page      => $page,
      enabled   => ($::in{category} || $mode eq 'mylist'),
      queryBase => "type=a&category=$args{id}$qLinks",
    );
  },

  makeGroup => sub {
    my (%args) = @_;
    my $id = $args{id};

    return {
      URL   => $id,
      NAME  => $categories{$id},
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
  [ $categories{$::in{category}}, '大分類「%s」' ],
  [ $::in{sub}, '小分類「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;