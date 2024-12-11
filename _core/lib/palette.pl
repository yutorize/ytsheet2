################## チャットパレット ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

require $set::lib_palette_sub;

my $id   = $::in{id};
my $tool = $::in{tool} || $::in{paletteTool};
my $log  = $::in{log}; #バックアップ情報読み込み
my $editing = $::in{editingMode};

if($editing){ outputChatPaletteTemplate(); } else { outputChatPalette(); }
### チャットパレット出力 #############################################################################
sub outputChatPalette {
  my ($file, $type, $author) = getfile_open($id);

  changeFileByType($type);

  our %pc = ();
  if($::in{propertiesall}){ $pc{chatPalettePropertiesAll} = 1 }

  my $datatype = ($::in{log}) ? 'logs' : 'data';

  my @lines;
  open my $IN, '<', "${set::char_dir}${file}/${datatype}.cgi" or error('データがありません');
  if($datatype eq 'logs'){
    my $hit = 0;
    while (<$IN>){
      if (index($_, "=") == 0){
        if (index($_, "=$::in{log}=") == 0){ $hit = 1; next; }
        if ($hit){ last; }
      }
      if (!$hit) { next; }
      push(@lines, $_);
    }
  }
  else {
    @lines = <$IN>;
  }
  close($IN);

  foreach (@lines){
    chomp;
    my ($key, $value) = split(/<>/, $_, 2);
    $pc{$key} = $value;
  }
  
  if($pc{forbidden}){
    my $LOGIN_ID = check;
    if($::in{log}){
      ($pc{protect}, $pc{forbidden}) = getProtectType("${set::char_dir}${file}/data.cgi");
    }
    unless(
      ($pc{protect} eq 'none') || 
      ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
    ){
      print "Content-type: text/plain; charset=UTF-8\n\n";
      say "エラー：閲覧権限がありません。\n";
      exit;
    }
  }
  
  if($pc{paletteRemoveTags}){
    $_ = removeTags(unescapeTags($_) =~ s/<br>/\n/gr) foreach values %pc;
  }
  else {
    $_ = unescapeTagsPalette($_) foreach values %pc;
  }
  $pc{chatPalette} =~ s/<br>/\n/gi;
  $pc{skills} =~ s/<br>/\n/gi;

  $pc{ver} =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($pc{ver} < 1.11001){ $pc{paletteUseBuff} = 1; }

  my $preset = $pc{paletteUseVar} ? palettePreset($tool,$type) :  palettePresetSimple($tool,$type) ;

  $preset = deletePalettePresetBuff($preset) if !$pc{paletteUseBuff};
  if(!$tool){ $preset = swapWordAndCommand($preset); }

  if ($pc{paletteInsertType} eq 'begin'){ $pc{chatPalette} = $pc{chatPalette}."\n".$preset; }
  elsif($pc{paletteInsertType} eq 'end'){ $pc{chatPalette} = $preset."\n".$pc{chatPalette}; }
  else {
    $pc{chatPalette} = $preset if !$pc{chatPalette};
  }

  my $properties;
  $properties .= $_."\n" foreach( $pc{chatPalettePropertiesAll} ? paletteProperties($tool,$type) : filterByUsedOnly($pc{chatPalette},$tool,$type) );

  $properties =~ s/\n+$//g;

  $pc{chatPalette} =~ s/&lt;/\</gi;
  $pc{chatPalette} =~ s/&gt;/\>/gi;
  $properties =~ s/&lt;/\</gi;
  $properties =~ s/&gt;/\>/gi;

  ### 出力 --------------------------------------------------
  print "Content-type: text/plain; charset=UTF-8\n\n";
  say $pc{chatPalette},"\n";
  say $properties;
}

### サブルーチン #####################################################################################
sub swapWordAndCommand {
  my @palette = split(/\n/, shift);
  foreach (@palette){
    if($_ =~ /^[0-9a-z:+\-\{\(]/i){
      my ($command, $word) = split(/ /, $_, 2);
      if($command && $word){
        $_ = "$word $command";
      }
    }
  }
  return join("\n", @palette);
}

# 抽選コマンドをつくる
sub makeChoiceCommand {
  my $count = shift;
  my @sourceItems = @{shift;};
  my %bot = %{shift;};

  sub validateItems {
    my @sources = @{shift;};
    my %_bot = %{shift;};

    my @validated = ();

    foreach my $item (@sources) {
      next if $item =~ /^[\s　]*$/;

      if ($_bot{YTC}) {
        $item =~ s/,/_/g;
      }
      elsif ($_bot{BCD}) {
        $item =~ s/ /_/g;
      }
      else {
        next;
      }

      push(@validated, $item);
    }

    return @validated;
  }

  my @validatedItems = validateItems(\@sourceItems, \%bot);
  return '' unless @validatedItems;

  if ($bot{YTC}) {
    return "${count}\$" . join(',', @validatedItems) . "\n";
  }

  if ($bot{BCD}) {
    return ($count > 1 ? "x${count} " : '') . 'choice ' . join(' ', @validatedItems) . "\n";
  }

  return '';
}

sub outputChatPaletteTemplate {
  use JSON::PP;
  my $type = $::in{type};
  require $set::lib_calc_char;
  our %pc;
  for (param()){ $pc{$_} = decode('utf8', param($_)) }
  %pc = data_calc(\%pc);
  if($pc{paletteRemoveTags}){
    $_ = removeTags(unescapeTags($_) =~ s/<br>/\n/gr) foreach values %pc;
  }
  else {
    $_ = unescapeTagsPalette($_) foreach values %pc;
  }
  my %json;
  $json{preset} = $pc{paletteUseVar} ? palettePreset($tool,$type) :  palettePresetSimple($tool,$type);
  $json{preset} = deletePalettePresetBuff($json{preset}) if !$pc{paletteUseBuff};
  if(!$pc{paletteTool}){ $json{preset} = swapWordAndCommand($json{preset}); }
  $json{properties} .= "$_\n" foreach( paletteProperties($tool,$type) );

  $json{unitStatus} = createUnitStatus(\%pc);
  print "Content-type: application/json; charset=UTF-8\n\n";
  print JSON::PP->new->canonical(1)->encode( \%json );
}

sub deletePalettePresetBuff {
  my $text = shift;
  my %property;
  $_ =~ s|^//(.+?)=(.*?)$|$property{$1} = $2;|egi foreach split("\n",$text);
  my $hit;
  foreach(0 .. 100){
    $hit = 0;
    foreach (keys %property){
      if($text =~ s|\{$_\}|$property{$_}|g){ $hit = 1; }
    }
    last if !$hit
  }
  $text =~ s#^//.+?=.*?(\n|$)##gm;
  $text =~ s/\$\+0//g;
  $text =~ s/\#0//g;
  $text =~ s/\+0//g;
  $text =~ s/\+\(\)//g;
  $text =~ s/^### ■バフ・デバフ\n//g;
  
  return $text;
}

sub filterByUsedOnly {
  my $palette = shift;
  my $tool = shift;
  my $type = shift;
  my %used;
  my @propaties_in = paletteProperties($tool,$type);
  my @propaties_out;
  my $hit = 1;
  foreach (0 .. 100){
    $hit = 0;
    foreach my $line (@propaties_in){
      if($line =~ "^//(.+?)="){
        my $var = $1;
        if   ($palette =~ "^//\Q$var\E="){ ; }
        elsif($palette =~ /\{\Q$var\E\}/){ $palette .= $line."\n"; $hit = 1 }
      }
    }
    last if !$hit;
  }
  foreach (@propaties_in){
    if($_ =~ "^//(.+?)="){
      my $var = $1;
      if($palette =~ /\{\Q$var\E\}/){ push @propaties_out, $_; }
    }
    else {
      push @propaties_out, $_;
    }
  }
  return @propaties_out;
}

sub unescapeTagsPalette {
  my $text = shift;
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;

  if($set::game eq 'sw2'){
    $text =~ s/\[(魔|刃|打)\]/&#91;$1&#93;/;
  }
  
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/$1/gi; # リンク削除
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/$1/gi; # シート内リンク削除
  
  $text =~ s/&#91;(.)&#93;/[$1]/g;
  
  $text =~ s/\n/<br>/gi;
  return $text;
}

1;
