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
    %pc = upgradeGuildData(\%pc);
  }

  ### レベル・経験点 --------------------------------------------------
  $pc{expTotal} = 0;
  $pc{expTotal} += s_eval($pc{"history".$_."Exp"}) foreach (1 .. $pc{historyNum});
  $pc{historyExpTotal} = $pc{expTotal};
  $pc{level} = ($pc{guildSupportNum} || 0) - 1;
  $pc{expUsed} = ($pc{level} - $pc{makeLv}) * ($pc{makeLv} + $pc{level} - 1) / 2 * 10;
  $pc{expRest} = $pc{expTotal} - $pc{expUsed};
  
  ### 収支履歴計算 --------------------------------------------------
  $pc{moneyTotal} = 0;
  my $cashbook = $pc{cashbook};
  $cashbook =~ s/::((?:[\+\-\*\/]?[0-9]+)+)/$pc{moneyTotal} += eval($1)/eg;
  
  ### 0を消去 --------------------------------------------------

  #### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    qw/items cashbook freeNote freeHistory chatPalette/,
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
  foreach ('guildName','playerName','masterName'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{guildName}<>$NL{playerName}<>$pc{group}<>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>$pc{lastSession}<>"

    . "$NL{masterName}<>"
    . "$pc{level}<>"
  ;

  return %pc;
}

1;
