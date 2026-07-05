################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_mons;

sub dataCalc {
  my %pc = %{$_[0]};

  ####  --------------------------------------------------
  $pc{partsNum} ||= 1;
  if(!$pc{taxa} && $pc{taxaSelect} eq 'その他'){ $pc{taxa} = 'その他' }

  #### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    qw/skills description chatPalette/,
  );

  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### updatedLine --------------------------------------------------
  my %NL;
  $NL{name} = $pc{characterName} ? $pc{characterName} : $pc{monsterName};
  $NL{name} = "【$NL{name}】" if $NL{name} eq $pc{monsterName} && $pc{mount};
  $NL{taxa} = ($pc{mount} ? '騎獣／':'')
           . (($pc{taxa} && !grep { @$_[0] eq $pc{taxa} } @data::taxa) ? 'その他:' : '')
           . $pc{taxa};
  $NL{lv} = ($pc{mount} && $pc{lv} eq '') ? "$pc{lvMin}-$pc{lvMax}" : $pc{lv};
  $NL{$_} = $pc{$_} foreach ('author','intellect','perception','weakness');
  $NL{$_} = $pc{mount} ? '' : $pc{$_} foreach ('disposition','initiative','habitat');
  $NL{price} = $pc{mount} ? "$pc{price}／$pc{priceRental}" : '';
  foreach (keys %NL){
    $NL{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{name}    = substr($NL{name}   , 0, 108).'..' if length($NL{name}   ) > 108;
  $NL{author}  = substr($NL{author} , 0,  25).'..' if length($NL{author} ) >  25;
  $NL{taxa}    = substr($NL{taxa}   , 0,  20).'..' if length($NL{taxa}   ) >  20;
  $NL{intellect}   = substr($NL{intellect}  , 0, 15).'..' if length($NL{intellect}  ) >  15;
  $NL{perception}  = substr($NL{perception} , 0, 15).'..' if length($NL{perception} ) >  15;
  $NL{disposition} = substr($NL{disposition}, 0, 15).'..' if length($NL{disposition}) >  15;
  $NL{initiative}  = substr($NL{initiative} , 0, 10).'..' if length($NL{initiative} ) >  10;
  $NL{weakness}    = substr($NL{weakness}   , 0, 25).'..' if length($NL{weakness}   ) >  25;
  $NL{habitat}     = substr($NL{habitat}    , 0, 35).'..' if length($NL{habitat}    ) >  35;
  $pc{hide} = 'IN' if(!$pc{hide} && $pc{description} =~ /#login-only/i);
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{name}<>$pc{author}<>$NL{taxa}<>$NL{lv}<>"
    . "$pc{intellect}<>$pc{perception}<>$NL{disposition}<>$pc{sin}<>$NL{initiative}<>$NL{weakness}<>"
    . $pc{"image".imageSuffix($pc{mainImage})}."<> $pc{tags} <>$pc{hide}<>"
    . "$pc{partsNum}<>$NL{habitat}<>$NL{price}<>";

  return %pc;
}

1;
