################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group name player stage exp-min exp-max works breed syndrome dlois sign image fellow
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  player  => 5,
  group   => 6,
  exp     => 7,
  gender  => 8,
  age     => 9,
  sign    => 10,
  blood   => 11,
  works   => 12,
  syndrome=> 13,
  dlois   => 14,
  session => 15,
  image   => 16,
  tags    => 17,
  hide    => 18,
  stage   => 19,
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
@lines = filterContainsRegex(lines => \@lines, key => 'works') if $::in{works};
@lines = filterContainsRegex(lines => \@lines, key => 'syndrome', query => $_) foreach split /\s/,$::in{syndrome};
@lines = filterContainsRegex(lines => \@lines, key => 'dlois', query => $_) foreach split /\s/,$::in{dlois};
@lines = filterContainsRegex(lines => \@lines, key => 'stage') if $::in{stage};

@lines = filterRange(
  lines => \@lines,
  key => 'exp',
  minKey => 'exp-min',
  maxKey => 'exp-max',
  minValueOf => sub { return $_[0] - 130 },
  maxValueOf => sub { return $_[0] - 130 },
) if hasInteger($::in{'exp-min'}, $::in{'exp-max'});

## ブリード検索
$INDEX->param(Breeds => [makeSelectOptions(
  values   => [ [1, 'ピュア'], [2, 'クロス'], [3, 'トライ'] ],
  selected => $::in{breed},
  nameOf   => sub { $_[0]->[1] },
)]);
if($::in{breed}){
  if   ($::in{breed} == 1){ @lines = grep { m{^(?:[^<]*<>){13}[^/]+//<}           } @lines; $::in{breed} = 'ピュア'; }
  elsif($::in{breed} == 2){ @lines = grep { m{^(?:[^<]*<>){13}[^/]+/[^/]+/<}      } @lines; $::in{breed} = 'クロス'; }
  elsif($::in{breed} == 3){ @lines = grep { m{^(?:[^<]*<>){13}[^/]+/[^/]+/[^<]+<} } @lines; $::in{breed} = 'トライ'; }
}
## 星座検索
if($::in{sign}) {
  my @signs = (
    ['山羊|磨羯|やぎ',        '山羊座（磨羯宮）'],
    ['水瓶|宝瓶|みずがめ',    '水瓶座（宝瓶宮）'],
    ['双?魚|うお',            '魚座（双魚宮）'],
    ['[牡雄お]羊|おひつじ',   '牡羊座（白羊宮）'],
    ['[牡雄お]牛|おうし',     '牡牛座（金牛宮）'],
    ['双[子児]|ふたご',       '双子座（双児宮）'],
    ['蟹|かに',               '蟹座（巨蟹宮）'],
    ['獅子|しし',             '獅子座（獅子宮）'],
    ['[乙処]女|おとめ',       '乙女座（処女宮）'],
    ['天秤|てんびん',         '天秤座（天秤宮）'],
    ['蠍|天蝎|さそり|サソリ', '蠍座（天蝎宮）'],
    ['人馬|射手|いて',        '射手座（人馬宮）'],
    ['(蛇|へび)(使|遣|つか)', '蛇遣座'],
  );
  my $match = "\Q$::in{sign}\E";
  foreach my $sign (@signs) {
    my ($regex, $label) = @$sign;
    if ($::in{sign} =~ /$regex/) {
      $::in{sign} = $label;
      $match = $regex;
      last;
    }
  }
  @lines = grep { /^(?:[^<]*<>){10}[^<]*?(?:$match)/o } @lines;
}

### ソート --------------------------------------------------
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name'){ my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'pl')  { my @t = map { capField($_,'player') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date'){ my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'exp') { my @t = map { capField($_,'exp')    } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'age') { my @t = map { capField($_,'age')    } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
}

### リストを回す --------------------------------------------------
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
      "ID" => $pc{id},
      "NAME" => renderCharacterName($pc{name}),
      "PLAYER" => $pc{player},
      "GROUP" => $pc{group},
      "HIDE" => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
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
      PLAYER   => $pc{player},
      GROUP    => $pc{group},
      EXP      => commify($pc{exp}-130),
      AGE      => renderAge($pc{age}),
      GENDER   => renderGender($pc{gender}),
      SIGN     => $pc{sign},
      BLOOD    => $pc{blood},
      WORKS    => $pc{works},
      SYNDROME => join('', @syndromes),
      DLOIS    => join(' ', @dloises),
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
  [ $::in{stage},   'ステージ「%s」' ],
  [ $::in{exp},     '経験点＋「%s」' ],
  [ $::in{breed},   'ブリード「%s」' ],
  [ $::in{syndrome},'シンドローム「%s」' ],
  [ $::in{dlois},   'Ｄロイス「%s」' ],
  [ $::in{works},   'ワークス「%s」' ],
  [ $::in{sign},    '星座「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;
