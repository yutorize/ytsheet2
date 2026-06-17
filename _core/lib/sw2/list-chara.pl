################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

require $set::data_class;
require $set::data_races;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group name player race exp-min exp-max class rank faith image fellow
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  player  => 5,
  group   => 6,
  exp     => 7,
  rank    => 8,
  race    => 9,
  gender  => 10,
  age     => 11,
  faith   => 12,
  classes => 13,
  session => 14,
  image   => 15,
  tags    => 16,
  hide    => 17,
  fellow  => 18,
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
@lines = filterFlagRegex(lines => \@lines, key => 'image') if $::in{image};
@lines = filterContainsRegex(lines => \@lines, key => 'faith') if $::in{faith};
@lines = filterFlagRegex(lines => \@lines, key => 'fellow') if $::in{fellow};

@lines = filterRange(
  lines => \@lines,
  key => 'exp',
) if hasInteger($::in{'exp-min'}, $::in{'exp-max'});

## 種族検索 --------------------------------------------------
if($::in{race}) {
  if   (!$::SW2_0 && $::in{race} eq 'ドレイク'          ){ @lines = grep { /^(?:[^<]*<>){9}(ドレイク|ドレイク（ナイト）)</ } @lines; }
  elsif(!$::SW2_0 && $::in{race} eq 'ドレイクブロークン'){ @lines = grep { /^(?:[^<]*<>){9}(ドレイクブロークン|ドレイク（ブロークン）)</ } @lines; }
  else {
    if($::in{race} =~ s/（通常種）$//){
      @lines = grep { /^(?:[^<]*<>){9}\Q$::in{race}\E</o } @lines;
      $::in{race} .= '（通常種）';
    }
    else {
      @lines = grep { /^(?:[^<]*<>){9}\Q$::in{race}\E/o } @lines;
    }
  }
}
my @raceList;
foreach (@data::race_names){
  if(s/^label=//){
    push(@raceList, { LABEL => $_ });
  }
  else {
    push(@raceList, { NAME => $_, SELECTED => ($_ eq $::in{race}) ? 'selected' : '' });
  }

  if($data::races{$_}{variant}){
    if($data::races{$_}{ability}){
      push(@raceList, {
        NAME => $_.'（通常種）',
        SELECTED => ($_.'（通常種）' eq $::in{race}) ? 'selected' : '',
      });
    }
    foreach my $varname (@{ $data::races{$_}{variantSort} }){ 
      push(@raceList, {
        NAME => $_."（$varname）",
        SELECTED => ($_."（$varname）" eq $::in{race}) ? 'selected' : '',
      });
    }
  }
}
push(@raceList, {
  NAME => 'その他',
  SELECTED => ('その他' eq $::in{race}) ? 'selected' : '',
});
$INDEX->param(RaceList => \@raceList);

## 技能検索 --------------------------------------------------
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
    if(exists $num{$name}){
      if($lv ne ''){
        if   ($op eq '>='){ @lines = grep { (split '/',(m/^(?:[^<]*<>){13}([^<|]*)/)[0])[$num{$name}] >= $lv } @lines; }
        elsif($op eq '<='){ @lines = grep { (split '/',(m/^(?:[^<]*<>){13}([^<|]*)/)[0])[$num{$name}] <= $lv } @lines; }
        elsif($op eq '>' ){ @lines = grep { (split '/',(m/^(?:[^<]*<>){13}([^<|]*)/)[0])[$num{$name}] >  $lv } @lines; }
        elsif($op eq '<' ){ @lines = grep { (split '/',(m/^(?:[^<]*<>){13}([^<|]*)/)[0])[$num{$name}] <  $lv } @lines; }
        else              { @lines = grep { (split '/',(m/^(?:[^<]*<>){13}([^<|]*)/)[0])[$num{$name}] == $lv } @lines; }
      }
      else { @lines = grep { (split '/',(m/^(?:[^<]*<>){13}([^<|]*)/)[0])[$num{$name}] >= 1 } @lines; }
    }
    else {
      if($lv ne ''){
        if   ($op eq '>='){ @lines = grep { (split '/', m/^(?:[^<]*<>){13}[^<|]*\|[^<]*?$name([0-9]+)/)[0] >= $lv } @lines; }
        elsif($op eq '<='){ @lines = grep { (split '/', m/^(?:[^<]*<>){13}[^<|]*\|[^<]*?$name([0-9]+)/)[0] <= $lv } @lines; }
        elsif($op eq '>' ){ @lines = grep { (split '/', m/^(?:[^<]*<>){13}[^<|]*\|[^<]*?$name([0-9]+)/)[0] >  $lv } @lines; }
        elsif($op eq '<' ){ @lines = grep { (split '/', m/^(?:[^<]*<>){13}[^<|]*\|[^<]*?$name([0-9]+)/)[0] <  $lv } @lines; }
        else              { @lines = grep { (split '/', m/^(?:[^<]*<>){13}[^<|]*\|[^<]*?$name([0-9]+)/)[0] == $lv } @lines; }
      }
      else { @lines = grep { (split '/', m/^(?:[^<]*<>){13}[^<|]*\|[^<]*?$name([0-9]+)/)[0] >= 1 } @lines; }
    }
  }
}
$INDEX->param(class => "@classQuery");

## ランク --------------------------------------------------
@lines = filterExactRegex(lines => \@lines, key => 'rank', emptyKeyword => 'なし') if $::in{rank};
my @rankValues = (
  "label=冒険者ランク",
  @set::adventurer_rank,
  "label=蛮族栄光ランク",
  @set::barbaros_rank
);
my %sortRank = map { $_->[0] => $_->[1] } grep{ ref($_) eq 'ARRAY' } @rankValues;
my @rankList = makeSelectOptions(
  values   => \@rankValues,
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

  #技能レベル
  my ($classes, $freeclasses) = split '\|', $pc{classes};
  my @levels = split '/', $classes;
  my $level = max(@levels);
  my %lv;
  @lv{@data::class_list} = @levels;
  foreach (split '/',$freeclasses) {
    if(m/^(.+?)([0-9]+)$/){
      $lv{$1} = $2;
      $level = $2 if $2 > $level;
    }
  }
  my $renderClass;
  foreach (sort {$lv{$b} <=> $lv{$a}} keys %lv){
    $renderClass .= $_.$lv{$_} if $lv{$_};
  }
  
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
      LV     => $level,
      RANK   => $pc{rank},
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
      EXP    => commify($pc{exp}),
      LV     => $level,
      CLASS  => decorateClasses($renderClass),
      RACE   => renderRace($pc{race}),
      GENDER => renderGender($pc{gender}),
      AGE    => renderAge($pc{age}),
      FAITH  => $pc{faith},
      RANK   => thinIfLong($pc{rank}, 6),
      FELLOW => ($pc{fellow} != 1) ? 0 : 1,
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

## 技能色分け --------------------------------------------------
sub decorateClasses {
  my $text = shift;
  $text =~ s/((?:.*?)(?:[0-9]+))/<span>$1<\/span>/g;
  $text =~ s/<span>((?:ファイター|グラップラー|フェンサー|バトルダンサー)(?:[0-9]+?))<\/span>/<span class="melee">$1<\/span>/;
  $text =~ s/<span>((?:プリースト|フェアリーテイマー|アビスゲイザー)(?:[0-9]+?))<\/span>/<span class="healer">$1<\/span>/;
  $text =~ s/<span>((?:スカウト|ウォーリーダー|レンジャー)(?:[0-9]+?))<\/span>/<span class="initiative">$1<\/span>/;
  $text =~ s/<span>((?:セージ)(?:[0-9]+?))<\/span>/<span class="knowledge">$1<\/span>/;
  return $text;
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
  [ $::in{fellow}, 'フェローあり' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
