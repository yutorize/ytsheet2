use HTML::Parser ();
use LWP::UserAgent;

sub get_parsed_enemy_data_from_ytsheet_one_mons {
  my %simple_column_table = (
    '知能' => 'intellect',
    '知覚' => 'perception',
    '反応' => 'disposition',
    '言語' => 'language',
    '生息地' => 'habitat',
    '弱点'=> 'weakness',
    '先制値' => 'initiative',
    '移動速度' => 'mobility',
  );
  my %parentheses_column_table = (
    '生命抵抗力' => {raw => 'vitResist', fix => 'vitResistFix'},
    '精神抵抗力' => {raw => 'mndResist', fix => 'mndResistFix'},
  );
  my $browser = LWP::UserAgent->new;
  my $response = $browser->get("https://yutorize.2-d.jp/ms_sw2/s/data/1579365932.html");
  my $parse_target_html = $response->content;
  my %result = ();
  my $mode = "";

  my $parser = HTML::Parser->new(
    api_version => 3,
    start_h     => [\&ytsheet_one_mons_when_open_tag_found, "self, tagname, attr"],
    end_h       => [\&ytsheet_one_mons_when_close_tag_found, "self, tagname"],
    text_h      => [\&ytsheet_one_mons_when_text_found, "self, text"],
  );
  $parser->parse($parse_target_html);

  sub ytsheet_one_mons_when_open_tag_found {
    my ($self, $tagname, $attr) = @_;
    if($tagname eq 'title') {
      $mode = $tagname;
    }
  }

  sub ytsheet_one_mons_when_close_tag_found {
    my ($self, $tagname) = @_;
    if($tagname eq 'title') {
      $mode = '';
    }
  }

  sub ytsheet_one_mons_when_text_found {
    my ($self, $text) = @_;
    if($mode eq 'title') {
      my @title = split(/：/, $text);
      $result{'monsterName'} = $title[0];
      $result{'taxa'} = $title[1];
      $result{'lv'} = $title[2];
      $result{'lv'} =~ s/レベル//;
    }
    elsif($text eq '知名度／弱点値') {
      $mode = $text;
    }
    elsif($mode eq '知名度／弱点値') {
      my @reputations = split(/／/, $text);
      $result{'reputation'} = $reputations[0];
      $result{'reputation'} =~ s/://;
      $result{'reputation+'} = $reputations[1];
      $mode = "";
    }
    elsif($simple_column_table{$text}) {
      $mode = $text;
    }
    elsif($simple_column_table{$mode}) {
      $result{$simple_column_table{$mode}} = $text;
      $result{$simple_column_table{$mode}} =~ s/://;
      $mode = "";
    }
    elsif($parentheses_column_table{$text}) {
      $mode = $text;
    }
    elsif($parentheses_column_table{$mode}) {
      if($text =~ /(\d+)\((\d+)\)/) {
        $result{$parentheses_column_table{$mode}{raw}} = $1;
        $result{$parentheses_column_table{$mode}{fix}} = $2;
        print "$1 and $2 \n";
      }
      else {
        $result{$parentheses_column_table{$mode}{raw}} = "-";
        $result{$parentheses_column_table{$mode}{fix}} = "-";
      }
      $mode = "";
    }
    
  }
  while (my ($key, $value) = each(%result)) {
    $result{$key} =~ s/^[ 　\t\n\r\f]*(.*?)[ 　\t\n\r\f]*$/$1/;
  }
  return %result;
}

my %result = get_parsed_enemy_data_from_ytsheet_one_mons();
while (my ($key, $value) = each(%result)) {
  print "$key = [$value]\n";
}
