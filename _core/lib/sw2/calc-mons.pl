################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_mons;

sub data_calc {
  my %pc = %{$_[0]};

  ####  --------------------------------------------------
  $pc{partsNum} ||= 1;
  if(!$pc{taxa} && $pc{taxaSelect} eq 'その他'){ $pc{taxa} = 'その他' }

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{skills}      =~ s/\r\n?|\n/<br>/g;
  $pc{description} =~ s/\r\n?|\n/<br>/g;
  $pc{chatPalette} =~ s/\r\n?|\n/<br>/g;
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### newline --------------------------------------------------
  my $name = $pc{characterName} ? $pc{characterName} : $pc{monsterName};
  $name = "【${name}】" if $name eq $pc{monsterName} && $pc{mount};
  $name =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $pc{hide} = 'IN' if(!$pc{hide} && $pc{description} =~ /#login-only/i);
  my $taxa = ($pc{mount} ? '騎獣／':'')
           . (($pc{taxa} && !grep { @$_[0] eq $pc{taxa} } @data::taxa) ? 'その他:' : '')
           . $pc{taxa};
  my $lv = ($pc{mount} && $pc{lv} eq '') ? "$pc{lvMin}-$pc{lvMax}" : $pc{lv};
  my $disposition = $pc{mount} ? '' : $pc{disposition};
  my $initiative  = $pc{mount} ? '' : $pc{initiative};
  my $habitat     = $pc{mount} ? '' : $pc{habitat};
  my $price       = $pc{mount} ? "$pc{price}／$pc{priceRental}" : '';
  $::newline = "$pc{id}<>$::file<>".
                "$pc{birthTime}<>$::now<>$name<>$pc{author}<>$taxa<>$lv<>".
                "$pc{intellect}<>$pc{perception}<>$disposition<>$pc{sin}<>$initiative<>$pc{weakness}<>".
                "$pc{image}<> $pc{tags} <>$pc{hide}<>$pc{partsNum}<>$habitat<>$price";
  
  return %pc;
}

1;