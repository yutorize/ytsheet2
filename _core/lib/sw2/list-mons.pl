################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

require $set::data_mons;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag taxa name author lv-max lv-min parts-max parts-min intellect perception disposition habitat weakness
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  author  => 5,
  taxa    => 6,
  lv      => 7,
  intellect   => 8,
  perception  => 9,
  disposition => 10,
  sin         => 11,
  initiative  => 12,
  weakness    => 13,
  image   => 14,
  tags    => 15,
  hide    => 16,
  parts   => 17,
  habitat => 18,
  price   => 19
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type     => 'm',
  typeName => '魔物/騎獣',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
  excludeFromQLinks => { taxa => 1 },
);

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
@lines = filterTag(@lines) if $::in{tag};
@lines = filterContainsRegex(lines => \@lines, key => 'name', flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'author', flags => 'i') if $::in{author};
@lines = filterContainsRegex(lines => \@lines, key => 'intellect') if $::in{intellect};
@lines = filterContainsRegex(lines => \@lines, key => 'perception') if $::in{perception};
@lines = filterContainsRegex(lines => \@lines, key => 'disposition') if $::in{disposition};
@lines = filterContainsRegex(lines => \@lines, key => 'habitat') if $::in{habitat};
@lines = filterContainsRegex(lines => \@lines, key => 'weakness') if $::in{weakness};

@lines = filterRange(
  lines => \@lines,
  key => 'lv',
  minValueOf => \&lvMaxCheck,
  maxValueOf => \&lvMinCheck,
) if hasInteger($::in{'lv-min'}, $::in{'lv-max'});

@lines = filterRange(
  lines => \@lines,
  key => 'parts',
) if hasInteger($::in{'parts-min'}, $::in{'parts-max'});

sub lvMinCheck {
  my ($min, $max) = split('-', shift);
  return $min || $max;
}
sub lvMaxCheck {
  my ($min, $max) = split('-', shift);
  return $max || $min;
}

## 分類検索 --------------------------------------------------
if($::in{mount}) {
  if($::in{taxa} eq 'all'){ $::in{taxa} = '' }
  @lines = grep { /^(?:[^<]*<>){6}騎獣／\Q$::in{taxa}\E/o } @lines;
}
elsif($::in{taxa}) {
  @lines = grep { !/^(?:[^<]*<>){6}騎獣／/ } @lines;
  if($::in{taxa} eq 'その他') {
    @lines = grep { /^(?:[^<]*<>){6}その他/ } @lines;
  }
  elsif($::in{taxa} ne 'all') {
    @lines = grep { /^(?:[^<]*<>){6}\Q$::in{taxa}\E</o } @lines;
  }
}
if($::in{mount}){ $INDEX->param(group => '騎獣'.($::in{taxa}?"／$::in{taxa}":'')      ); }
else            { $INDEX->param(group => $::in{taxa} eq 'all' ? 'すべて' : $::in{taxa}); }
$INDEX->param(mount => $::in{mount} ? 'checked' : '');

$INDEX->param(Taxa => [makeSelectOptions(
  values   => [sort { $a->[1] cmp $b->[1] } @data::taxa],
  selected => $::in{taxa},
)]);

### ソート ###########################################################################################
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name')  { my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'author'){ my @t = map { capField($_,'author') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date')  { my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'lv')    { my @t = map { capField($_,'lv')     } @lines; @lines = @lines[sort {$t[$a] <=> $t[$b]} 0 .. $#t]; }
  elsif($s eq 'parts') { my @t = map { capField($_,'parts')  } @lines; @lines = @lines[sort {$t[$a] <=> $t[$b]} 0 .. $#t]; }
}

### ページ処理 #######################################################################################
my $selectedTaxaGroup = $::in{mount} ? '騎獣' : $::in{taxa} eq 'all' ? 'すべて' : $::in{taxa};

my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines         => \@lines,
  selectedGroup => $selectedTaxaGroup,
  hasTagQuery   => $::in{tag},
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };
  
  #グループ
  my $renderedTaxa = $pc{taxa} =~ s/^その他://r;
  $renderedTaxa = "<span class=\"small\">$renderedTaxa</span>" if length($renderedTaxa) >= 6;
  if($pc{taxa} =~ /^騎獣／/){ $pc{taxa} = '騎獣'; }
  else {
    if (!$pc{taxa}){ $pc{taxa} = '未分類' }
    elsif($pc{taxa} =~ /^その他/){ $pc{taxa} = 'その他' }

    if($::in{taxa} eq 'all'){
      $pc{taxa} = 'すべて';
    }
    elsif (!$indexMode){
      $pc{taxa} = $::in{taxa} || 'すべて';
    }
  }
  
  next if $shouldSkip->(
    group => $pc{taxa},
  );

  # 適正レベル
  $pc{lv} =~ s/^(\d+)-(\d+)$/$1～$2/;

  # 価格
  $pc{price} =~ s#^／#―／#;
  $pc{price} =~ s#／$#／―#;
  $pc{price} = commify($pc{price});
  
  #出力用配列へ
  my @monsters;
  push(@monsters, {
    ID      => $pc{id},
    NAME    => $pc{name},
    AUTHOR  => $pc{author},
    TAXA    => $renderedTaxa,
    LV      => $pc{lv},
    PARTS   => $pc{parts},
    DISPOSITION => $pc{disposition},
    HABITAT => $pc{habitat},
    PRICE   => $pc{price},
    TAGS    => renderTagLinks($pc{tags}),
    DATE    => renderUpdateTime($pc{date}),
    HIDE    => $pc{hide},
  });
  
  push(@{$groupedLists{$pc{taxa}}}, @monsters);
}
### テンプレートへ出力 ###############################################################################
@data::taxa = sort { $a->[1] <=> $b->[1] } @data::taxa;

my @taxaGroups = $indexMode || ($::in{taxa} && $::in{taxa} ne 'all')
  ? @data::taxa
  : ['すべて',''];
push(@taxaGroups, ['騎獣', 'XX', '']);

$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => \@taxaGroups,
  groupedLists => \%groupedLists,
  count => $count,
  
  makePager => sub {
    my (%args) = @_;

    return makePager(
      count     => $args{count},
      page      => $page,
      enabled   => ($args{id} || $::in{mode} eq 'mylist'),
      queryBase => "type=m&taxa=".monsTaxaUrl($args{id}, $::in{taxa})."$qLinks",
    );
  },

  makeGroup => sub {
    my (%args) = @_;
    my $id = $args{id};

    return {
      QUERYBASE => 'type=m&taxa='.monsTaxaUrl($args{id}, $::in{taxa}),
      NAME      => $args{id},
      TEXT      => monsTaxaText($args{id}, $::in{taxa}),
      NUM       => $args{num},
      MOUNT     => ($args{id} eq '騎獣' ? 1 : 0),
      Lines     => $args{lines},
      PAGER     => $args{pager},
      MORE      => $args{more},
    };
  },
) ]);

sub monsTaxaUrl {
  my ($name, $query) = @_;

  my $urltaxa;
  if($name eq '騎獣'){
    if($query && $query ne 'all'){ $urltaxa = uri_escape_utf8($query)  }
    else { $urltaxa = 'all' }
    if(!$::in{mount}){ $urltaxa .= '&mount=1' }
  }
  elsif($name eq 'すべて'){ $urltaxa = 'all' }
  else { $urltaxa = uri_escape_utf8($name) }

  return $urltaxa;
}
sub monsTaxaText {
  my ($name, $query) = @_;

  if($name eq 'すべて'){ return '騎獣以外のすべての魔物' }
  if($name eq '騎獣'){ return $query ? "／$query" : 'すべての騎獣' }
  return '';
}

## 検索サマリー --------------------------------------------------
setSearchSummary(
  { nameHeader => '名称' },
  [ ($::in{mount} ? join('／', grep { $_ } "騎獣",$::in{taxa}) : $selectedTaxaGroup), '分類「%s」' ],
  [ $::in{lv},     'レベル「%s」' ],
  [ $::in{parts},  '部位数「%s」' ],
  [ $::in{intellect},   '知能「%s」' ],
  [ $::in{perception},  '知覚「%s」' ],
  [ $::in{disposition}, '反応「%s」' ],
  [ $::in{habitat},     '生息地「%s」' ],
  [ $::in{weakness},    '弱点「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;