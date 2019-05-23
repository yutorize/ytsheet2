################## フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use HTML::Template;

my $LOGIN_ID = check;

require $set::data_races;

my $page_items = 10;
my $page = param("page") * $page_items;

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename => $set::skin_tmpl, utf8 => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1);

$INDEX->param(modeMaking => 1) if param('mode') eq 'making';

$INDEX->param(name => (getplayername($LOGIN_ID))[0]);

$INDEX->param(LOGIN_ID => $LOGIN_ID);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $main::ver);

my $i = 0;
open (my $FH,"<", $set::makelist);
my @lines = <$FH>;
close($FH);

@lines = grep { (split /<>/)[2]  eq param('id') } @lines if param('id');

my @posts;
foreach my $data (@lines) {
  $i++;
  chomp $data;
  
  my ($num, $date, $id, $name, $comment, $race, $stt) = split(/<>/, $data);
  next if param("num") && param("num") ne $num;
  next if !param("num") && (($i <= $page) || ($i > $page+$page_items));
  
  my $adventurer = ($race =~ s/（冒険者）//) ? 1 : 0;
  my @datalist;
  foreach my $stt_data (split(/\//, $stt)){
    my ($tec, $phy, $spi, $stt_A, $stt_B, $stt_C, $stt_D, $stt_E, $stt_F) = split(/,/, $stt_data);
    
    my $dicetotal = $data::race_dices{$race}{'A'}
                  + $data::race_dices{$race}{'B'}
                  + $data::race_dices{$race}{'C'}
                  + $data::race_dices{$race}{'D'}
                  + $data::race_dices{$race}{'E'}
                  + $data::race_dices{$race}{'F'};
    my $addtotal = $data::race_dices{$race}{'A+'}
                 + $data::race_dices{$race}{'B+'}
                 + $data::race_dices{$race}{'C+'}
                 + $data::race_dices{$race}{'D+'}
                 + $data::race_dices{$race}{'E+'}
                 + $data::race_dices{$race}{'F+'};
    
    my $average = ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F) / $dicetotal;
       $average = ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F + $tec + $phy + $spi) / 18 if $adventurer;
       
    my $url = "${tec}_${phy}_${spi}_"
            . ($stt_A + $data::race_dices{$race}{'A+'}) . '_'
            . ($stt_B + $data::race_dices{$race}{'B+'}) . '_'
            . ($stt_C + $data::race_dices{$race}{'C+'}) . '_'
            . ($stt_D + $data::race_dices{$race}{'D+'}) . '_'
            . ($stt_E + $data::race_dices{$race}{'E+'}) . '_'
            . ($stt_F + $data::race_dices{$race}{'F+'});
    
    push(@datalist, {
      "RACE" => $race.($adventurer?'（冒険者）':''),
      
      "TEC" => $tec,
      "PHY" => $phy,
      "SPI" => $spi,
      "A" => $stt_A.($data::race_dices{$race}{'A+'} ? "<span> +$data::race_dices{$race}{'A+'}</span>" : ''),
      "B" => $stt_B.($data::race_dices{$race}{'B+'} ? "<span> +$data::race_dices{$race}{'B+'}</span>" : ''),
      "C" => $stt_C.($data::race_dices{$race}{'C+'} ? "<span> +$data::race_dices{$race}{'C+'}</span>" : ''),
      "D" => $stt_D.($data::race_dices{$race}{'D+'} ? "<span> +$data::race_dices{$race}{'D+'}</span>" : ''),
      "E" => $stt_E.($data::race_dices{$race}{'E+'} ? "<span> +$data::race_dices{$race}{'E+'}</span>" : ''),
      "F" => $stt_F.($data::race_dices{$race}{'F+'} ? "<span> +$data::race_dices{$race}{'F+'}</span>" : ''),
      "DEX" => $tec + $stt_A + $data::race_dices{$race}{'A+'},
      "AGI" => $tec + $stt_B + $data::race_dices{$race}{'B+'},
      "STR" => $phy + $stt_C + $data::race_dices{$race}{'C+'},
      "VIT" => $phy + $stt_D + $data::race_dices{$race}{'D+'},
      "INT" => $spi + $stt_E + $data::race_dices{$race}{'E+'},
      "MND" => $spi + $stt_F + $data::race_dices{$race}{'F+'},
      "AVERAGE" => $dicetotal ? sprintf("%.5g", $average) : '―',
      "TOTAL" => $stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F + ($tec + $phy + $spi) * 2 + $addtotal,
      "URLRACE" => uri_escape_utf8($race),
      "URLSTT" => $url,
    });
  }
  push(@posts, {
    "NUM" => $num,
    "NAME" => $name,
    "COMMENT" => $comment,
    "Data" => \@datalist,
  });
}
$INDEX->param(Posts => \@posts);

$INDEX->param(pageId => '&id='.param('id')) if param('id');
$INDEX->param(pagePrev => ($page - $page_items) / $page_items);
$INDEX->param(pageNext => ($page + $page_items) / $page_items);
if(!param("num")) {
  $INDEX->param(pagePrevOn => $page - $page_items >= 0);
  $INDEX->param(pageNextOn => $page + $page_items < @lines);
}
$INDEX->param(formOn => 1) if !param('num') && !param('id');

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;