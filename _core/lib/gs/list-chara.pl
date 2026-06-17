################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

require $set::data_class;



### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group name player race exp-min exp-max class rank faith image
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
  exp     => 11,
  level   => 12,
  classes => 13,
  race    => 14,
  racebase=> 15,
  gender  => 16,
  age     => 17,
  rank    => 18,
  faith   => 19,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type     => '',
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
@lines = filterContainsRegex(lines => \@lines, key => 'race') if $::in{race};
@lines = filterContainsRegex(lines => \@lines, key => 'faith') if $::in{faith};

@lines = filterRange(
  lines => \@lines,
  key => 'exp',
) if hasInteger($::in{'exp-min'}, $::in{'exp-max'});

## 職業検索 --------------------------------------------------
my @classQuery = split(/\s/, $::in{class});
if(@classQuery){
  my %num;
  my $i = 0;
  foreach (@data::class_list){ $num{$_} = $i; $i++; }
  foreach my $class (@classQuery){
    my $op = ''; my $lv = '';
    $class =~ s/&lt;/</g;
    $class =~ s/&gt;/>/g;
    (my $name = $class) =~ s/(?<op>\>=?|\<=?)?(?<lv>[0-9]+)$/$op = $+{op};$lv = $+{lv};''/e;
    if($lv ne ''){
      if   ($op eq '>='){ @lines = grep { (split '/',(/^(?:[^<]*<>){13}([^<]*)/)[0])[$num{$name}] >= $lv } @lines; }
      elsif($op eq '<='){ @lines = grep { (split '/',(/^(?:[^<]*<>){13}([^<]*)/)[0])[$num{$name}] <= $lv } @lines; }
      elsif($op eq '>' ){ @lines = grep { (split '/',(/^(?:[^<]*<>){13}([^<]*)/)[0])[$num{$name}] >  $lv } @lines; }
      elsif($op eq '<' ){ @lines = grep { (split '/',(/^(?:[^<]*<>){13}([^<]*)/)[0])[$num{$name}] <  $lv } @lines; }
      else              { @lines = grep { (split '/',(/^(?:[^<]*<>){13}([^<]*)/)[0])[$num{$name}] == $lv } @lines; }
    }
    else { @lines = grep { (split '/',(/^(?:[^<]*<>){13}([^<]*)/)[0])[$num{$name}] >= 1 } @lines; }
  }
}
$INDEX->param(class => "@classQuery");

## ランク --------------------------------------------------
@lines = filterExactRegex(lines => \@lines, key => 'rank', emptyKeyword => 'なし') if $::in{rank};
my %sortRank = map { $_->[0] => $_->[1] } grep{ ref($_) eq 'ARRAY' } @set::adventurer_rank;
my @rankList = makeSelectOptions(
  values   => \@set::adventurer_rank,
  selected => $::in{rank},
  labelOf  => sub { my $value = shift; return ($value =~ /^label=(.+)/)[0] },
);
unshift(@rankList, {
  ID => 'なし',
  NAME => 'なし',
  SELECTED => $::in{rank} eq 'なし' ? 'selected' : '',
});
$sortRank{''} = -1;
$INDEX->param(Ranks => \@rankList);

### ソート ###########################################################################################
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name'){ my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'pl')  { my @t = map { capField($_,'player') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date'){ my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'exp') { my @t = map { capField($_,'exp')    } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'rank'){ my @t = map { sortKeyRank($_)       } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'lv')  { my @t = map { sortKeyLv($_)         } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
}
sub sortKeyRank { return $sortRank{capField($_[0],'rank')}; }
sub sortKeyLv   { return max( split /\//, capField($_,'classes') ); }

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
      EXP    => $pc{exp},
      LV     => max((split '/', $pc{classes})),
      RANK   => $pc{rank},
      HIDE   => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
  ## 通常リスト
  else {
    #技能レベル
    my @levels = (split /\//, $pc{classes});
    my $level = max(@levels);
    my %lv;
    @lv{@data::class_list} = @levels;
    my $class;
    foreach (sort {$lv{$b} <=> $lv{$a}} keys %lv){
      $class .= "<span>$_$lv{$_}</span>" if $lv{$_};
    }

    #出力用配列へ
    my @characters;
    push(@characters, {
      ID     => $pc{id},
      NAME   => renderCharacterName($pc{name}),
      PLAYER => $pc{player},
      GROUP  => $pc{group},
      EXP    => commify($pc{exp}),
      LV     => $level,
      CLASS  => $class,
      RACE   => renderRace($pc{race}),
      GENDER => renderGender($pc{gender}),
      AGE    => renderAge($pc{age}),
      FAITH  => $pc{faith},
      RANK   => $pc{rank},
      TAGS   => renderTagLinks($pc{tags}, $pc{session}),
      DATE   => renderUpdateTime($pc{date}),
      HIDE   => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
}

## 種族 --------------------------------------------------
sub renderRace {
  my $race = shift;
  $race =~ s/^その他://g;
  $race =~ s/[（(].*[)）]|［.*］//;
  return thinIfLong($race, 6);
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
  [ $::in{race},   '種族「%s」' ],
  [ $::in{rank},   'ランク「%s」' ],
  [ $::in{exp},    '経験点「%s」' ],
  [ "@classQuery", '技能「%s」' ],
  [ $::in{faith},  '信仰「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
