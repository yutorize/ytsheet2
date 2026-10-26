################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_class;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  nameKeys          => [qw/guildName/],
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  unescapeSkipRe    => qr/^image|URL$/,
  convertViewMap    => [qw/freeNote freeHistory/],
  groups            => \@set::groups_guild,
  updateSub => \&upgradeGuildData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{guildName} = noiseText(6,14);
    $pc->{group} = $pc->{areaTags} = $pc->{tags} = '';
    
    $pc->{masterName} = noiseText(3,12);

    $pc->{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }

  $pc->{makeLv}   = noiseText(1);
  $pc->{level}   = noiseText(1);
  $pc->{expRest} = noiseText(1,2);
  $pc->{expUsed} = noiseText(1,2);

  $pc->{memberNum} = int(rand 4) + 2;
  foreach my $n (1..$pc->{memberNum}){
    $pc->{"member${n}Name"}   = noiseText(5,10) unless($forbidden eq 'battle');
    $pc->{"member${n}CL"}     = noiseText(1);
    $pc->{"member${n}Race"}   = noiseText(3,6);
    $pc->{"member${n}MClass"} = noiseText(5,6);
    $pc->{"member${n}SClass"} = noiseText(5,6);
    $pc->{"member${n}Player"} = noiseText(5,10) unless($forbidden eq 'battle');
    $pc->{"member${n}Note"}   = noiseText(5,10) unless($forbidden eq 'battle');
  }

  $pc->{guildSupportNum} = int(rand 4) + 2;
  foreach my $n (1..$pc->{guildSupportNum}){
    $pc->{"guildSupport${n}Name"}      = noiseText(5,10);
    $pc->{"guildSupport${n}Timing"}    = noiseText(3,6);
    $pc->{"guildSupport${n}Lv"}        = noiseText(1);
    $pc->{"guildSupport${n}Stackable"} = noiseText(1);
    $pc->{"guildSupport${n}Note"}      = noiseText(5,6);
    $pc->{"guildSupport${n}Used"}      = '';
    $pc->{"guildSupport${n}Selected"}  = '';
  }

  $pc->{money} = noiseText(1,3);
  $pc->{cashbook} = '';

  $pc->{items} = '';
  foreach(1..int(rand 5)+4){
    $pc->{items} .= '　'.noiseText(5,20)."<br>";
  }

  $pc->{historyNum} = 0;
  $pc->{historyExpTotal} = noiseText(1,3);
}

### メンバー --------------------------------------------------
{
  my @row;
  my @fields = qw/Name URL CL Race MClass SClass Player Note/;
  foreach my $n (1..$pc{memberNum}){
    next if (!existsRow "member${n}", grep { $_ ne "URL" } @fields);

    my %print;
    $print{uc $_} = $pc{"member${n}$_"} for @fields;

    if($print{URL}){ $print{NAME} = qq|<a href="$print{URL}">$print{NAME}</a>| }

    $print{RACE} =~ s/([(（])/<br>$1/;

    foreach (qw/RACE MCLAS SCLASS PLAYER/){
      my $length = max(0, map { length } split /<br>/, $print{$_});
      my $class;
      if   ($length > 6){ $class = "thiner" }
      elsif($length > 5){ $class = "thin" }

      if($class){ $print{$_} = qq|<span class="$class">$print{$_}</span>|; }
      else { $print{$_} = $print{$_} }
    }
    push(@row, \%print);
  }
  $SHEET->param(Members => \@row);
}
### ギルドサポート --------------------------------------------------
{
  my @row;
  my @fields = qw/Name Timing Lv Stackable Note Used Selected/;
  foreach my $n (1..$pc{guildSupportNum}){
    next if (!existsRow "guildSupport${n}", @fields);
    
    my %print;
    $print{uc $_} = $pc{"guildSupport${n}$_"} for @fields;

    $print{GL} = ($n >= 2) ? ($n - 1) : $n unless $pc{forbiddenMode};

    foreach (qw/USED SELECTED/){
      $print{$_} = $print{$_} ? 'checked' : '';
    }
  
    push(@row, \%print);
  }
  $SHEET->param(AcademySupports => \@row);
}

### 履歴 --------------------------------------------------
{
  my @row;
  my @fields = qw/Date Title Exp Gm Member Note/;
  my $h_num = 0;
  $pc{history0Title} = "シート作成（レベル：$pc{makeLv}）";
  foreach my $n (0 .. $pc{historyNum}){
    next if(!existsRow "history${n}", @fields);

    my %print;
    $print{uc $_} = $pc{"history${n}$_"} for @fields;

    $h_num++ if $print{GM};
    if ($set::log_dir && $print{DATE} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
      my $room = $1;
      (my $date = $print{DATE}) =~ y#\-\/##d;
      $print{DATE} = "<a href=\"$set::log_dir$date$room.html\">$print{DATE}<\/a>";
    }
    if ($set::sessionlist && $print{TITLE} =~ s/^#([0-9]+)//){
      $print{TITLE} = "<a href=\"$set::sessionlist?num=$1\" data-num=\"$1\">$print{TITLE}<\/a>";
    }
    my $members;
    $print{MEMBER} =~ s/((?:\G|>)[^<]*?)[,、 ]+/$1　/g;
    foreach my $mem (split(/　/,$print{MEMBER})){
      $members .= '<span>'.$mem.'</span>';
    }
    $print{MEMBER} = $members;
    $print{EXP} = formatHistoryFigures($print{EXP});
    $print{NUM} = $print{GM} ? $h_num : '';
    push(@row, \%print);
  }
  $SHEET->param(History => \@row);
}

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "レベル:$pc{level}　爵位:$pc{peerage}　ロード:$pc{lordName}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
