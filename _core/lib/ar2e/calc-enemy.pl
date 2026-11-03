################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;

sub dataCalc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    #%pc = upgradeEnemyData(\%pc);
  }

  ## 上限カット --------------------------------------------------
  $pc{level} = 9999 if $pc{level} > 9999;
  $pc{level} = 0 if $pc{level} < 0;

  ### 属性 --------------------------------------------------
  $pc{element} = join ',', deduplicate split(',', $pc{element});
  $pc{element} ||= '―';

  ### 能力値 --------------------------------------------------
  foreach my $key (qw/Str Dex Agi Int Sen Mnd Luk/) {
    $pc{"stt$key"} = int($pc{"stt${key}Base"} / 3);
  }

  #### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    qw/skills description chatPalette/,
  );

  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### updatedLine --------------------------------------------------
  my %NL;
  foreach ('enemyName','author'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{$_} = $pc{$_} foreach qw/taxon race element/;
  $NL{taxon}   = 'その他' unless (grep  { $_ eq $NL{taxon} } @set::enemyTaxa);
  $NL{element} = '他' unless ($NL{element} =~ /\A[―地水火風光闇,]+\z/);
  $NL{race}   = substr($NL{race}, 0, 30).'..' if length($NL{race}) > 30;

  $::updatedLine = join('<>',
    $pc{id}, $::file, $pc{birthTime}, $::now,
    $NL{enemyName}, $NL{author}, $pc{group},
    setUpdatatLineImage(\%pc), " $pc{tags} ", ($pc{hide}?1:''),
    $NL{taxon}.($NL{race}?"($NL{race})":''), $NL{element}, $pc{level}, ($pc{isMob}?1:''),
  ).'<>';
  return %pc;
}

1;
