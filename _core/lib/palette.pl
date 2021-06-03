################## チャットパレット ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

require $set::lib_palette_sub;

### バックアップ情報読み込み #########################################################################
my $backup = $::in{'backup'};

### キャラクターデータ読み込み #######################################################################
my $id = $::in{'id'};
my $tool = $::in{'tool'};
my ($file, $type) = getfile_open($id);

my $data_dir;
   if($type eq 'm'){ $data_dir = $set::mons_dir; }
elsif($type eq 'i'){ $data_dir = $set::item_dir; }
else               { $data_dir = $set::char_dir; }

our %pc = ();

my $IN;
if($backup eq "") {
  open $IN, '<', "${data_dir}${file}/data.cgi" or "";
} else {
  open $IN, '<', "${data_dir}${file}/backup/${backup}.cgi" or "";
}
if($tool){
  $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = tag_unescape($2);/egi while <$IN>;
  $pc{'chatPalette'} =~ s/<br>/\n/g;
  $pc{'skills'} =~ s/<br>/\n/gi;
  $_ = tag_delete($_) foreach values %pc;
}
else {
  $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = tag_unescape_ytc($2);/egi while <$IN>;
  $pc{'chatPalette'} =~ s/<br>/\n/g;
  $pc{'skills'} =~ s/<br>/\n/gi;
}
close($IN);
$_ =~ s/&lt;/\</gi foreach values %pc;
$_ =~ s/&gt;/\>/gi foreach values %pc;

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

### 出力 #############################################################################################
print "Content-type: text/plain; charset=UTF-8\n\n";
say $pc{'chatPalette'},"\n";
say $properties;

1;
