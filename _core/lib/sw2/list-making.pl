################## フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

require $set::data_races;

my $page_items = 10;
my $page = $::in{page} * $page_items;

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename => $set::skin_tmpl, utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1);

$INDEX->param(modeMaking => 1) if $::in{mode} eq 'making';
$INDEX->param(typeName => 'キャラ');

$INDEX->param(name => (getplayername($LOGIN_ID))[0]);

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

my @race_makelist;
foreach my $name (@data::race_names){
  if($data::races{$name}{dice}){
    push(@race_makelist, {VALUE => $name});
  }
  if($data::races{$name}{variant}){
    foreach my $varname (@{ $data::races{$name}{variantSort} }){
      if($data::races{$name}{variant}{$varname}{dice}){
        push(@race_makelist, "${name}（${varname}）");
      }
    }
  }

  if($name eq '人間'){
    push(@race_makelist, {VALUE => "人間（冒険者）"});
  }

  if($name =~ /^label=(.+)$/){
    push(@race_makelist, {"LABEL" => $1});
  }
}
$INDEX->param(MakeList => \@race_makelist);

my $i = 0;
open (my $FH,"<", $set::makelist);
my @lines = <$FH>;
close($FH);

## 検索
if($::in{mylist}){
  @lines = grep { $_ =~ /^(?:[^<]*?<>){2}\Q$LOGIN_ID\E</ } @lines;
  $INDEX->param(modeMylist => 1);
}
elsif($::in{id}){
  @lines = grep { $_ =~ /^(?:[^<]*?<>){2}\Q$::in{id}\E</ } @lines;
}
if($::in{tag}){
  my $tag_query = decode('utf8', $::in{tag}) =~ s/[#＃]//r;
  @lines = grep { $_ =~ /^(?:[^<]*?<>){4}[^<]*?[#＃]\Q$tag_query\E(\s|[#＃]|<)/ } @lines if $::in{tag};
  $INDEX->param(tag => $tag_query);
}

my ($in_num, $in_trial) = split('-', $::in{num});

my @posts;
foreach my $data (@lines) {
  $i++;
  chomp $data;
  
  next if $in_num && $data !~ /^$in_num</;
  next if !$in_num && (($i <= $page) || ($i > $page+$page_items));
  my ($num, $date, $id, $name, $comment, $race, $stt, $curse) = split(/<>/, $data);

  if(!$::SW2_0){
    if   ($race eq 'ドレイク（ナイト）'    ){ $race = 'ドレイク' }
    elsif($race eq 'ドレイク（ブロークン）'){ $race = 'ドレイクブロークン' }
  }
  
  my $adventurer = ($race =~ s/（冒険者）//) ? 1 : 0;
  my @datalist;
  my $trial = 0;
  foreach my $stt_data (split(/\//, $stt)){
    $trial++;
    my ($tec, $phy, $spi, $stt_A, $stt_B, $stt_C, $stt_D, $stt_E, $stt_F) = split(/,/, $stt_data);
    
    my $dicetotal = $data::races{$race}{dice}{'A'}
                  + $data::races{$race}{dice}{'B'}
                  + $data::races{$race}{dice}{'C'}
                  + $data::races{$race}{dice}{'D'}
                  + $data::races{$race}{dice}{'E'}
                  + $data::races{$race}{dice}{'F'};
    my $addtotal = $data::races{$race}{dice}{'A+'}
                 + $data::races{$race}{dice}{'B+'}
                 + $data::races{$race}{dice}{'C+'}
                 + $data::races{$race}{dice}{'D+'}
                 + $data::races{$race}{dice}{'E+'}
                 + $data::races{$race}{dice}{'F+'};
    
    my $average = $dicetotal ? ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F) / $dicetotal : 0;
       $average = ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F + $tec + $phy + $spi) / 18 if $adventurer;
       
    my $url = "${tec}_${phy}_${spi}_"
            . ($stt_A + $data::races{$race}{dice}{'A+'}) . '_'
            . ($stt_B + $data::races{$race}{dice}{'B+'}) . '_'
            . ($stt_C + $data::races{$race}{dice}{'C+'}) . '_'
            . ($stt_D + $data::races{$race}{dice}{'D+'}) . '_'
            . ($stt_E + $data::races{$race}{dice}{'E+'}) . '_'
            . ($stt_F + $data::races{$race}{dice}{'F+'});
    
    push(@datalist, {
      RACE => $race.($adventurer?'（冒険者）':''),
      
      TEC => $tec,
      PHY => $phy,
      SPI => $spi,
      A => $stt_A.($data::races{$race}{dice}{'A+'} ? "<span> +$data::races{$race}{dice}{'A+'}</span>" : ''),
      B => $stt_B.($data::races{$race}{dice}{'B+'} ? "<span> +$data::races{$race}{dice}{'B+'}</span>" : ''),
      C => $stt_C.($data::races{$race}{dice}{'C+'} ? "<span> +$data::races{$race}{dice}{'C+'}</span>" : ''),
      D => $stt_D.($data::races{$race}{dice}{'D+'} ? "<span> +$data::races{$race}{dice}{'D+'}</span>" : ''),
      E => $stt_E.($data::races{$race}{dice}{'E+'} ? "<span> +$data::races{$race}{dice}{'E+'}</span>" : ''),
      F => $stt_F.($data::races{$race}{dice}{'F+'} ? "<span> +$data::races{$race}{dice}{'F+'}</span>" : ''),
      DEX => $tec + $stt_A + $data::races{$race}{dice}{'A+'},
      AGI => $tec + $stt_B + $data::races{$race}{dice}{'B+'},
      STR => $phy + $stt_C + $data::races{$race}{dice}{'C+'},
      VIT => $phy + $stt_D + $data::races{$race}{dice}{'D+'},
      INT => $spi + $stt_E + $data::races{$race}{dice}{'E+'},
      MND => $spi + $stt_F + $data::races{$race}{dice}{'F+'},
      AVERAGE => $dicetotal ? sprintf("%.5g", $average) : '―',
      TOTAL => $stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F + ($tec + $phy + $spi) * 2 + $addtotal,
      URLRACE => uri_escape_utf8($race),
      URLSTT => $url,
      NUM => $num,
      TRIAL => $trial,
      SELECTED => ($in_trial eq $trial ? 'selected' : ''),
    });
  }

  my @curses = split('/', $curse);
  $_ = $_.':'.$set::curseList{$_} foreach (@curses);

  $comment =~ s/([#＃])(.+?)(?=\s|[#＃]|$)/<a href=".\/?mode=making&tag=$2">$1$2<\/a>/g;

  my ($sec, $min, $hour, $day, $mon, $year) = localtime($date);
  push(@posts, {
    NUM     => $num,
    DATE    => sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year+1900, $mon+1, $day, $hour, $min, $sec),
    NAME    => $name,
    COMMENT => $comment,
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
if(!$in_num) {
  $INDEX->param(pagePrevOn => $page - $page_items >= 0);
  $INDEX->param(pageNextOn => $page + $page_items < @lines);
}
if($in_num || $::in{tag}) {
  $INDEX->param(isMakingResult => 1);
}
$INDEX->param(formOn => 1) if !$::in{num} && !$::in{id};

$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;