################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";

(our $file, my $type) = getfile_open(param('id'));
   if($type eq 'm'){ require $set::lib_view_mons; }
elsif($type eq 'i'){ require $set::lib_view_item; }
else               { require $set::lib_view_char; }


### サブルーチン #####################################################################################
sub tag_unescape {
  my $text = $_[0];
  my $old_on = $_[1];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  
  $text =~ s/{{([0-9\+\-\*\/\%\(\) ]+?)}}/s_eval($1);/eg;
  
  $text =~ s|(―+)|&ddash($1);|eg;
  
  $text =~ s/'''(.+?)'''/<span class="oblique">$1<\/span>/gi; # 斜体
  $text =~ s/''(.+?)''/<b>$1<\/b>/gi;  # 太字
  $text =~ s/%%(.+?)%%/<span class="strike">$1<\/span>/gi;  # 打ち消し線
  $text =~ s/__(.+?)__/<span class="underline">$1<\/span>/gi;  # 下線
  $text =~ s/[|｜]([^|｜]+?)《(.+?)》/<ruby>$1<rp>(<\/rp><rt>$2<\/rt><rp>)<\/rp><\/ruby>/gi; # なろう式ルビ
  $text =~ s/《《(.+?)》》/<span class="text-em">$1<\/span>/gi; # カクヨム式傍点
  
  $text =~ s/&lt;br&gt;/<br>/gi;
  
  $text =~ s/「((?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+)/"「".&text_convert_icon($1);/egi;
  
  return $text;
}
sub tag_unescape_lines {
  my $text = $_[0];
  $text =~ s/<br>/\n/gi;
  
  $text =~ s/^LEFT:/<\/p><p class="left">/gim;
  $text =~ s/^CENTER:/<\/p><p class="center">/gim;
  $text =~ s/^RIGHT:/<\/p><p class="right">/gim;
  
  $text =~ s/^-{4,}$/<\/p><hr><p>/gim;  
  $text =~ s/^( \*){4,}$/<\/p><hr class="dotted"><p>/gim;
  $text =~ s/^( \-){4,}$/<\/p><hr class="dashed"><p>/gim;
  $text =~ s/^\*\*\*\*(.*?)$/<\/p><h5>$1<\/h5><p>/gim;
  $text =~ s/^\*\*\*(.*?)$/<\/p><h4>$1<\/h4><p>/gim;
  $text =~ s/^\*\*(.*?)$/<\/p><h3>$1<\/h3><p>/gim;
  $text =~ s/\A\*(.*?)$/$main::pc{"head_$_"} = $1; ''/egim;
  $text =~ s/^\*(.*?)$/<\/p><h2>$1<\/h2><p>/gim;
  
  $text =~ s/^\|(.*?)\|$/&tablecall($1)/egim;
  $text =~ s/(<\/tr>)\n/$1/gi;
  $text =~ s/(?!<\/tr>|<table>)(<tr>.*?<\/tr>)(?!<tr>|<\/table>)/<\/p><table class="note-table">$1<\/table><p>/gi;
  $text =~ s/^\:(.*?)\|(.*?)$/<dt>$1<\/dt><dd>$2<\/dd>/gim;
  $text =~ s/(<\/dd>)\n/$1/gi;
  $text =~ s/(?!<\/dd>)(<dt>.*?<\/dd>)(?!<dt>)/<\/p><dl class="note-description">$1<\/dl><p>/gi;

  $text =~ s/\n<\/p>/<\/p>/gi;
  $text =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
  $text =~ s/<p><\/p>//gi;
  $text =~ s/\n/<br>/gi;
  
  return $text;
}

sub text_convert_icon {
  my $text = $_[0];
  
  $text =~ s{[○◯〇]}{<i class="s-icon passive">○</i>}gi;
  $text =~ s{[△]}{<i class="s-icon setup">△</i>}gi;
  $text =~ s{[＞▶〆]}{<i class="s-icon major">▶</i>}gi;
  $text =~ s{[☆≫»]|&gt;&gt;}{<i class="s-icon minor">≫</i>}gi;
  $text =~ s{[□☑🗨]}{<i class="s-icon active">☑</i>}gi;
  
  return $text;
} 

sub tablecall {
  my $out = '<tr>';
  my @td = split(/\|/, $_[0]);
  my $col_num;
  foreach(@td){
    $col_num++;
    if($_ eq '&gt;'){ $col_num++; next; }
    
    if($_ =~ /^~/){ $_ =~ s/^~//; $out .= '<th'.($col_num > 1 ? " colspan=\"$col_num\"" : '').'>'.$_.'</th>'; }
    else          {               $out .= '<td'.($col_num > 1 ? " colspan=\"$col_num\"" : '').'>'.$_.'</td>'; }
    $col_num = 0;
  }
  $out .= '</tr>';
  return $out;
}
sub colcall {
  my @out;
  my @col = split(/\|/, $_[0]);
  foreach(@col){
    push (@out, &tablestyle($_));
  }
  return @out;
}

sub ddash {
  my $dash = $_[0];
  $dash =~ s|―|<span>―</span>|g;
  return "<span class=\"d-dash\">$dash</span>";
}

1;