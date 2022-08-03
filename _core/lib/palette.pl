################## チャットパレット ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

require $set::lib_palette_sub;

my $id   = $::in{'id'};
my $tool = $::in{'tool'};
my $log  = $::in{'log'}; #バックアップ情報読み込み
my $editing = $::in{'editingMode'};

if($editing){ outputChatPaletteTemplate(); } else { outputChatPalette(); }
### チャットパレット出力 #############################################################################
sub outputChatPalette {
  my ($file, $type, undef) = getfile_open($id);

  my $datadir;
    if($type eq 'm'){ $datadir = $set::mons_dir; }
  else              { $datadir = $set::char_dir; }

  our %pc = ();
  if($::in{'propertiesall'}){ $pc{'chatPalettePropertiesAll'} = 1 }

  my $datatype = ($::in{'log'}) ? 'logs' : 'data';

  my @lines;
  open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or &login_error;
  if($datatype eq 'logs'){
    my $hit = 0;
    while (<$IN>){
      if (index($_, "=") == 0){
        if (index($_, "=$::in{'log'}=") == 0){ $hit = 1; next; }
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

  if($tool){
    foreach (@lines){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = tag_unescape($value);
    }
    $pc{'chatPalette'} =~ s/<br>/\n/g;
    $pc{'skills'} =~ s/<br>/\n/gi;
    $_ = tag_delete($_) foreach values %pc;
  }
  else {
    foreach (@lines){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = tag_unescape_ytc($value);
    }
    $pc{'chatPalette'} =~ s/<br>/\n/g;
    $pc{'skills'} =~ s/<br>/\n/gi;
  }

  $pc{'ver'} =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($pc{'ver'} < 1.11001){ $pc{'paletteUseBuff'} = 1; }

  my $preset = $pc{'paletteUseVar'} ? palettePreset($tool,$type) :  palettePresetSimple($tool,$type) ;
  $preset = palettePresetBuffDelete($preset) if !$pc{'paletteUseBuff'};

  if ($pc{'paletteInsertType'} eq 'begin'){ $pc{'chatPalette'} = $pc{'chatPalette'}."\n".$preset; }
  elsif($pc{'paletteInsertType'} eq 'end'){ $pc{'chatPalette'} = $preset."\n".$pc{'chatPalette'}; }
  else {
    $pc{'chatPalette'} = $preset if !$pc{'chatPalette'};
  }

  my $properties;
  $properties .= $_."\n" foreach( $pc{'chatPalettePropertiesAll'} ? paletteProperties($type) : palettePropertiesUsedOnly($pc{'chatPalette'},$type) );

  $properties =~ s/\n+$//g;

  $pc{'chatPalette'} =~ s/&lt;/\</gi;
  $pc{'chatPalette'} =~ s/&gt;/\>/gi;
  $properties =~ s/&lt;/\</gi;
  $properties =~ s/&gt;/\>/gi;

  ### 出力 --------------------------------------------------
  print "Content-type: text/plain; charset=UTF-8\n\n";
  say $pc{'chatPalette'},"\n";
  say $properties;
}

sub outputChatPaletteTemplate {
  use JSON::PP;
  my $type = $::in{'type'};
  if   ($type eq 'm'){ require $set::lib_calc_mons; }
  else               { require $set::lib_calc_char; }
  our %pc;
  for (param()){ $pc{$_} = decode('utf8', param($_)) }
  %pc = data_calc(\%pc);
  my %json;
  $json{'preset'} = $pc{'paletteUseVar'} ? palettePreset($tool,$type) :  palettePresetSimple($tool,$type);
  $json{'preset'} = palettePresetBuffDelete($json{'preset'}) if !$pc{'paletteUseBuff'};
  $json{'properties'} .= "$_\n" foreach( paletteProperties($type) );
  print "Content-type: text/javascript; charset=UTF-8\n\n";
  print JSON::PP->new->canonical(1)->encode( \%json );
}

1;
