################## フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

require $set::data_races;

unless(isInteger($::in{page}) && $::in{page} >= 0){
  $::in{page} = 0;
}
my $page_items = 10;
my $page = $::in{page} * $page_items;

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type     => '',
  typeName => '能力値作成',
  typeClass => 'making',
  pageTitle => ($::in{mylist} ? 'あなたの能力値作成履歴' : '能力値作成'),
);
$INDEX->param(mode => '');
$INDEX->param(modeList => 0);
$INDEX->param(modeMaking => 1) if $::in{mode} eq 'making';
$INDEX->param(mylistURL => './?mode=making&mylist=1');
$INDEX->param(canonicalURL => url(-full => 1, -query => 0) . "?mode=making");

$INDEX->param(name => (getPlayerName($::LOGIN_ID))[0]);

my @raceMakeList;
foreach my $name (@data::race_names){
  if($data::races{$name}{dice}){
    push(@raceMakeList, { VALUE => $name });
  }
  if($data::races{$name}{variant}){
    foreach my $varname (@{ $data::races{$name}{variantSort} }){
      if($data::races{$name}{variant}{$varname}{dice}){
        push(@raceMakeList, { VALUE => "${name}（${varname}）" });
      }
    }
  }

  if($name eq '人間'){
    push(@raceMakeList, { VALUE => "人間（冒険者）" });
  }

  if($name =~ /^label=(.+)$/){
    push(@raceMakeList, { LABEL => $1 });
  }
}
$INDEX->param(MakeList => \@raceMakeList);

my $i = 0;
my @lines = ();
if(open (my $FH,"<", $set::makelist)){
  @lines = <$FH>;
  close($FH);
}

## 検索
if($::in{mylist}){
  @lines = grep { $_ =~ /^(?:[^<]*<>){2}\Q$::LOGIN_ID\E</o } @lines;
  $INDEX->param(modeMylist => 1);
  $INDEX->param(mode => 'mylist');
}
elsif($::in{id}){
  @lines = grep { $_ =~ /^(?:[^<]*<>){2}\Q$::in{id}\E</o } @lines;
}
if($::in{tag}){
  my $tag_query = decode('utf8', $::in{tag}) =~ s/[#＃]//r;
  @lines = grep { $_ =~ /^(?:[^<]*<>){4}[^<]*?[#＃]\Q$tag_query\E(\s|[#＃]|<)/o } @lines if $::in{tag};
  $INDEX->param(tag => $tag_query);
}

my ($inNum, $inTrial) = split('-', $::in{num});
$inNum   = '' unless defined($inNum)   && $inNum   =~ /^[0-9]+$/;
$inTrial = '' unless defined($inTrial) && $inTrial =~ /^[0-9]+$/;

my @posts;
foreach my $data (@lines) {
  $i++;
  chomp $data;
  
  next if $inNum && $data !~ /^$inNum</o;
  next if !$inNum && (($i <= $page) || ($i > $page+$page_items));
  my %pc = %{ splitMakingLine($data) };

  if(!$::SW2_0){
    if   ($pc{race} eq 'ドレイク（ナイト）'    ){ $pc{race} = 'ドレイク' }
    elsif($pc{race} eq 'ドレイク（ブロークン）'){ $pc{race} = 'ドレイクブロークン' }
  }
  
  my $adventurer = ($pc{race} =~ s/（冒険者）//) ? 1 : 0;

  my $diceTotal;
  my $addTotal;
  foreach ('A','B','C','D','E','F'){
    $diceTotal += $data::races{$pc{race}}{dice}{$_} || 0;
    $addTotal  += $data::races{$pc{race}}{dice}{$_.'+'} || 0;
  }

  my @datalist;
  my $trial = 0;
  foreach my $sttData (split('/', $pc{stt})){
    $trial++;
    my %stt = %{ splitMakingStt($sttData) };
    
    my $url = "$stt{tec}_$stt{phy}_$stt{spi}_";
    foreach ('A','B','C','D','E','F'){
      $url .= ($stt{$_} + $data::races{$pc{race}}{dice}{$_.'+'}) . '_'
    }
    $url =~ s/_$//;
    
    my $average = $diceTotal ? ($stt{A} + $stt{B} + $stt{C} + $stt{D} + $stt{E} + $stt{F}) / $diceTotal : 0;
       $average = ($stt{A} + $stt{B} + $stt{C} + $stt{D} + $stt{E} + $stt{F} + $stt{tec} + $stt{phy} + $stt{spi}) / 18 if $adventurer;
    
    push(@datalist, {
      RACE => $pc{race}.($adventurer?'（冒険者）':''),
      
      TEC => $stt{tec},
      PHY => $stt{phy},
      SPI => $stt{spi},
      A => $stt{A}.($data::races{$pc{race}}{dice}{'A+'} ? "<span> +$data::races{$pc{race}}{dice}{'A+'}</span>" : ''),
      B => $stt{B}.($data::races{$pc{race}}{dice}{'B+'} ? "<span> +$data::races{$pc{race}}{dice}{'B+'}</span>" : ''),
      C => $stt{C}.($data::races{$pc{race}}{dice}{'C+'} ? "<span> +$data::races{$pc{race}}{dice}{'C+'}</span>" : ''),
      D => $stt{D}.($data::races{$pc{race}}{dice}{'D+'} ? "<span> +$data::races{$pc{race}}{dice}{'D+'}</span>" : ''),
      E => $stt{E}.($data::races{$pc{race}}{dice}{'E+'} ? "<span> +$data::races{$pc{race}}{dice}{'E+'}</span>" : ''),
      F => $stt{F}.($data::races{$pc{race}}{dice}{'F+'} ? "<span> +$data::races{$pc{race}}{dice}{'F+'}</span>" : ''),
      DEX => $stt{tec} + $stt{A} + $data::races{$pc{race}}{dice}{'A+'},
      AGI => $stt{tec} + $stt{B} + $data::races{$pc{race}}{dice}{'B+'},
      STR => $stt{phy} + $stt{C} + $data::races{$pc{race}}{dice}{'C+'},
      VIT => $stt{phy} + $stt{D} + $data::races{$pc{race}}{dice}{'D+'},
      INT => $stt{spi} + $stt{E} + $data::races{$pc{race}}{dice}{'E+'},
      MND => $stt{spi} + $stt{F} + $data::races{$pc{race}}{dice}{'F+'},
      AVERAGE => $diceTotal ? sprintf("%.5g", $average) : '―',
      TOTAL => $stt{A} + $stt{B} + $stt{C} + $stt{D} + $stt{E} + $stt{F} + ($stt{tec} + $stt{phy} + $stt{spi}) * 2 + $addTotal,
      URLRACE => uri_escape_utf8($pc{race}),
      URLSTT => $url,
      NUM => $pc{num},
      TRIAL => $trial,
      SELECTED => ($inTrial eq $trial ? 'selected' : ''),
    });
  }

  my @curses = split('/', $pc{curse});
  $_ = $_.':'.$set::curseList{$_} foreach (@curses);

  if($pc{comment}){
    $pc{comment} = escapeThanSign($pc{comment});
    $pc{comment} =~ s{([#＃])(.+?)(?=\s|[#＃]|$)}{
      my $mark = $1;
      my $tag  = $2;
      my $url  = uri_escape_utf8($tag);
      qq|<a href="./?mode=making&tag=$url">$mark$tag</a>|
    }eg;
  }

  my ($sec, $min, $hour, $day, $mon, $year) = localtime($pc{date});
  push(@posts, {
    NUM     => $pc{num},
    DATE    => sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year+1900, $mon+1, $day, $hour, $min, $sec),
    NAME    => $pc{name},
    COMMENT => $pc{comment},
    Data    => \@datalist,
    CURSE   => join('／', @curses),
  });
}
$INDEX->param(Posts => \@posts);

my $paginationUrl;
$paginationUrl .= '&id='.$::in{id} if $::in{id};
$paginationUrl .= '&tag='.uri_escape_utf8(decode('utf8', $::in{tag})) if $::in{tag};
$paginationUrl .= '&mylist=1' if $::in{mylist};
$INDEX->param(paginationUrl => $paginationUrl);
$INDEX->param(pagePrev => ($page - $page_items) / $page_items);
$INDEX->param(pageNext => ($page + $page_items) / $page_items);
if(!$inNum) {
  $INDEX->param(pagePrevOn => $page - $page_items >= 0);
  $INDEX->param(pageNextOn => $page + $page_items < @lines);
}
if($inNum || $::in{tag}) {
  $INDEX->param(isMakingResult => 1);
}
$INDEX->param(formOn => 1) if !$::in{num} && !$::in{id};


### 出力 #############################################################################################
printFinalizedList();

### サブルーチン #####################################################################################
sub splitMakingLine {
  my $line = shift;
  my ($num, $date, $id, $name, $comment, $race, $stt, $curse) = split(/<>/, $line);
  return {
    num => $num,
    date => $date,
    id => $id,
    name => $name,
    comment => $comment,
    race => $race,
    stt => $stt,
    curse => $curse,
  };
}
sub splitMakingStt {
  my $data = shift;
  my ($tec, $phy, $spi, $sttA, $sttB, $sttC, $sttD, $sttE, $sttF) = split(/,/, $data);
  return {
    tec => $tec,
    phy => $phy,
    spi => $spi,
    A => $sttA,
    B => $sttB,
    C => $sttC,
    D => $sttD,
    E => $sttE,
    F => $sttF,
  };
}


1;