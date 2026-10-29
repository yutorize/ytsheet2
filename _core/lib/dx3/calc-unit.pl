################## ユニット保存 ##################
use strict;
use utf8;

sub dataCalc {
  my %pc = %{$_[0]};
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = upgradeUnitData(\%pc);
  }

  ### カンパニー --------------------------------------------------
  $pc{companyExpUsed} = $pc{companyExp} + $pc{exteriorExp};
  $pc{companySlotUsed} = 0;
  foreach my $n (1 .. $pc{facilityNum}){
    $pc{companyExpUsed}  += $pc{"facility${n}Exp"};
    $pc{companySlotUsed} += $pc{"facility${n}Slot"}; 
  }
  
  ### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    'freeNote', grep { /^(?:member|order)[0-9]+Note$/ } keys %pc,
  );
  ### 保存処理でなければここまで --------------------------------------------------
  return %pc unless $::mode_save;

  ### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach keys %pc;
  $pc{tags} = normalizeHashtags($pc{tags});

  ### updatedLine --------------------------------------------------
  my %NL;
  foreach my $key ('unitName','playerName'){
    $NL{$key} = removeTags removeRuby unescapeTags $pc{$key};
    $NL{$key} = substr($NL{$key}, 0, 108);
  }
  my @leaders;
  foreach my $num (1 .. $pc{memberNum}){
    next unless $pc{"member${num}Name"};
    my $name = removeTags removeRuby unescapeTags $pc{"member${num}Name"};
    $name = substr($name, 0, 108).'..' if length($name) > 108;
    push @leaders, $name if $pc{"member${num}Leader"};
  }
  $NL{sheetSubType} = $pc{sheetSubType} if ($pc{sheetSubType} =~ /^(?:unit|company)$/);
  $NL{companySize}  = exists $set::companySize{$pc{companySize}} ? $pc{companySize} : 'その他';
  ### updatedLine --------------------------------------------------
  $::updatedLine = join('<>',
    $pc{id}, $::file, $pc{birthTime}, $::now,
    $NL{unitName}, $NL{playerName}, $pc{group},
    " $pc{tags} ", ($pc{hide}?1:''), $NL{sheetSubType}, $leaders[0], $NL{companySize},
  ).'<>';
  return %pc;
}

1;
