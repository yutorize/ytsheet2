################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP ();

#require $set::data_item;

sub dataCalc {
  my %pc = %{$_[0]};

  my $itemNum = itemDataCount(\%pc);
  $pc{itemNum} = $itemNum;
  delete $pc{pageTitle} if $itemNum == 1;

  my @prefixes = map { itemDataPrefix($_) } 1 .. $itemNum;
  foreach my $prefix (@prefixes){
    $pc{"${prefix}category"} =~ tr/ａ-ｚＡ-Ｚ/a-zA-Z/;
  }
  convertNewlinesToBrTag(\%pc, 'description', map { "${_}effects" } @prefixes);
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### updatedLine --------------------------------------------------
  my %NL;
  $NL{type} = $pc{magic} ? '[ma]' : '';
  foreach (qw/author category price age summary/){
    $NL{$_} = itemListText($pc{$_});
  }
  $NL{itemName} = itemListText(itemSheetName(\%pc));
  my $itemSearch = '';
  if($itemNum > 1){
    my @categories = map { itemListText($pc{"${_}category"}) } @prefixes;
    my @categorySets = map { join ' ', sort(deduplicate(split /\s+/, $_)) } @categories;
    if(grep { $_ ne $categorySets[0] } @categorySets){
      $NL{category} = $NL{price} = 'さまざま';
    }
    else {
      $NL{category} = join ' ', split /\s+/, $categories[0];
      $NL{price} = join '／', map { itemListText($pc{"${_}price"}) } @prefixes;
    }

    my $forbidden = $pc{forbidden} // '';
    if($forbidden eq '' || $forbidden eq 'battle'){
      my %search = (
        version => 1,
        names   => [ map { itemListText($pc{"${_}itemName"}) } @prefixes ],
      );
      $search{categories} = \@categories if $forbidden eq '';
      $itemSearch = escapeThanSign(JSON::PP->new->canonical(1)->encode(\%search));
    }
  }
  $NL{author}  = substr($NL{author} , 0,  25).'..' if length($NL{author} ) >  25;
  $NL{summary} = substr($NL{summary}, 0,  35).'..' if length($NL{summary}) >  35;
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{itemName}<>$NL{author}<>"
    . "$NL{category}<>$NL{price}<>$NL{age}<>$NL{summary}<>$NL{type}<>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>$itemSearch<>";
  
  return %pc;
}

sub itemListText {
  my $text = shift // '';
  $text =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  return trim(removeTags(unescapeTags($text)));
}

1;
