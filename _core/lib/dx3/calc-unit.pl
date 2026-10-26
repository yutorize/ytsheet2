################## ユニット保存 ##################
use strict;
use utf8;

sub dataCalc {
  my %pc = %{$_[0]};
  convertNewlinesToBrTag(\%pc,
    'freeNote', grep { /^(?:member|order)[0-9]+Note$/ } keys %pc,
  );
  return %pc unless $::mode_save;

  $pc{$_} = escapePcData($pc{$_}) foreach keys %pc;
  $pc{tags} = normalizeHashtags($pc{tags});

  my %line;
  foreach my $key ('unitName','playerName'){
    $line{$key} = removeTags removeRuby unescapeTags $pc{$key};
    $line{$key} = substr($line{$key}, 0, 108);
  }
  my @members;
  my @leaders;
  foreach my $num (1 .. $pc{memberNum}){
    next unless $pc{"member${num}Name"};
    my $name = removeTags removeRuby unescapeTags $pc{"member${num}Name"};
    push @members, $name;
    push @leaders, $name if $pc{"member${num}Leader"};
  }
  $::updatedLine = join('<>',
    $pc{id}, $::file, $pc{birthTime}, $::now,
    $line{unitName}, $line{playerName}, $pc{group},
    " $pc{tags} ", $pc{hide}, join('／', @members), join('／', @leaders),
  ).'<>';
  return %pc;
}

1;
