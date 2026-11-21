################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

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

  validateItemListValues($pc{pageTitle}, map { ($pc{"${_}itemName"}, $pc{"${_}category"}) } @prefixes);
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### updatedLine --------------------------------------------------
  my %NL;
  $NL{type} = $pc{magic} ? '[ma]' : '';
  foreach (qw/author price age summary/){
    $NL{$_} = itemListText($pc{$_});
  }
  my @names = (itemListText(itemSheetName(\%pc)));
  my @categories = map { itemListText($pc{"${_}category"}) } @prefixes;
  if($itemNum > 1){
    my $commonCategory = commonItemListCategory(@categories);
    if(defined $commonCategory){
      $NL{price} = join '／', map { itemListText($pc{"${_}price"}) } @prefixes;
    }
    else {
      $NL{price} = 'さまざま';
    }

    my $forbidden = $pc{forbidden} // '';
    if($forbidden eq '' || $forbidden eq 'battle'){
      push @names, map { itemListText($pc{"${_}itemName"}) } @prefixes;
    }
    @categories = ($commonCategory // 'さまざま') if $forbidden ne '';
  }
  $NL{itemName} = joinItemListValues(deduplicate(@names));
  $NL{category} = joinItemListValues(@categories);
  $NL{author}  = substr($NL{author} , 0,  25).'..' if length($NL{author} ) >  25;
  $NL{summary} = substr($NL{summary}, 0,  35).'..' if length($NL{summary}) >  35;
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{itemName}<>$NL{author}<>"
    . "$NL{category}<>$NL{price}<>$NL{age}<>$NL{summary}<>$NL{type}<>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>";
  
  return %pc;
}

sub itemListText {
  my $text = shift // '';
  $text =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  return trim(removeTags(unescapeTags($text)));
}

1;
