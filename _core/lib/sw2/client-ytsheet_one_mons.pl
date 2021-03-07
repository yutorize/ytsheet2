use HTML::Parser ();
use LWP::UserAgent;
use Encode;

sub get_parsed_enemy_data_from_ytsheet_one_mons {
  my $url = @_[0];
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
  my @parts_columns = ('Style', 'Accuracy', 'Damage', 'Evasion', 'Defense', 'Hp', 'Mp');
  my @loots_columns = ('', 'Num', '', 'Item'); # 改行についてスキップするために空白のカラムを挿入

  my $browser = LWP::UserAgent->new;
  my $response = $browser->get($url);
  my $parse_target_html = Encode::is_utf8($response->content) ? $response->content : Encode::decode('utf8', $response->content);
  if( index($parse_target_html, 'ゆとシートM') == -1 ) {
    return 0;
  }
  my %result = ();
  my $mode = '';
  my $partsCount = -1; # カラム名行をノーカンにするために -1 スタート
  my $lootsCount = -1; # カラム名行をノーカンにするために -1 スタート
  my $partsInternalCursor = 0;
  my $lootsInternalCursor = 0;

  my $parser = HTML::Parser->new(
    api_version => 3,
    start_h     => [\&ytsheet_one_mons_when_open_tag_found, 'self, tagname, attr'],
    end_h       => [\&ytsheet_one_mons_when_close_tag_found, 'self, tagname'],
    text_h      => [\&ytsheet_one_mons_when_text_found, 'self, text'],
  );
  $parser->parse($parse_target_html);

  sub ytsheet_one_mons_when_open_tag_found {
    my ($self, $tagname, %attr) = @_;
    if($tagname eq 'title') {
      $mode = $tagname;
    }
    elsif($_[2]{class} eq 'statu') {
      $mode = 'parts';
    }
    elsif($tagname eq 'tr' && $mode eq 'parts') {
      $partsCount++;
      $partsInternalCursor = 0;
      $result{'statusNum'} = $partsCount;
    }
    elsif($mode eq 'pre_skills' && $_[2]{class} eq 'text') {
      $mode = 'skills';
      $result{'skills'} = '';
    }
    elsif($mode eq 'pre_description' && $_[2]{class} eq 'text') {
      $mode = 'description';
      $result{'description'} = '';
    }
    elsif($_[2]{class} eq 'senri') {
      $mode = 'loots';
    }
    elsif($tagname eq 'tr' && $mode eq 'loots') {
      $lootsCount++;
      $lootsInternalCursor = 0;
      $result{'lootsNum'} = $lootsCount;
    }
    elsif($_[2]{class} eq 'hist') {
      $mode = 'author';
    }
    elsif($mode eq 'skills' && ($tagname eq 'div')) {
      $result{'skills'} = "$result{'skills'}&lt;br&gt;";
    }
    elsif($mode eq 'description' && ($tagname eq 'br')) {
      $result{'description'} = "$result{'description'}&lt;br&gt;";
    }
  }

  sub ytsheet_one_mons_when_close_tag_found {
    my ($self, $tagname) = @_;
    if($tagname eq 'table') {
      $mode = '';
    }
    elsif($mode eq 'skills' && ($tagname eq 'div')) {
      $result{'skills'} = "$result{'skills'}&lt;br&gt;";
    }
    elsif($mode eq 'description' && ($tagname eq 'br' || $tagname eq 'div' || $tagname eq 'span')) {
      $result{'description'} = "$result{'description'}&lt;br&gt;";
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
      $mode = '';
    }
    elsif($mode eq 'parts' && ($partsCount > 0) ) {
      if($parts_columns[$partsInternalCursor] eq 'Accuracy' || $parts_columns[$partsInternalCursor] eq 'Evasion') {
        if($text =~ /(\d+)\((\d+)\)/) {
          $result{"status$partsCount$parts_columns[$partsInternalCursor]"} = $1;
          $result{"status$partsCount$parts_columns[$partsInternalCursor]Fix"} = $2;
        } else {
          $result{"status$partsCount$parts_columns[$partsInternalCursor]"} = '-';
          $result{"status$partsCount$parts_columns[$partsInternalCursor]Fix"} = '-';
        }
      } else {
        $result{"status$partsCount$parts_columns[$partsInternalCursor]"} = $text;
      }
      $partsInternalCursor++;
    }
    elsif($mode eq 'loots' && ($lootsCount > 0)) {
      $result{"loots$lootsCount$loots_columns[$lootsInternalCursor]"} = $text;
      $lootsInternalCursor++;
    }
    elsif($text eq '知名度／弱点値') {
      $mode = $text;
    }
    elsif($mode eq '知名度／弱点値') {
      my @reputations = split(/／/, $text);
      $result{'reputation'} = $reputations[0];
      $result{'reputation'} =~ s/://;
      $result{'reputation+'} = $reputations[1];
      $mode = '';
    }
    elsif($text eq '部位数') {
      $mode = 'partsList'
    }
    elsif($mode eq 'partsList') {
      if($text =~ /^:\d+（(.*)）　$/) {
        $result{'parts'} = $1;
      } else {
        $result{'parts'} = '-';
      }
      $mode = '';
    }
    elsif($text eq 'コア部位') {
      $mode = 'corePartsInfo';
    }
    elsif($mode eq 'corePartsInfo') {
      $result{'coreParts'} = $text;
      $result{'coreParts'} =~ s/://;
      $result{'coreParts'} = $result{'coreParts'};
      $mode = '';
    }
    elsif($text eq '特殊能力') {
      $mode = 'pre_skills';
    }
    elsif($text eq '解説') {
      $mode = 'pre_description';
    }
    elsif($mode eq 'skills') {
      $text =~ s/\n/&lt;br&gt;/g;
      $result{'skills'} = "$result{'skills'}$text";
    }
    elsif($mode eq 'description') {
      $text =~ s/\n/&lt;br&gt;/g;
      $result{'description'} = "$result{'description'}$text";
    }
    elsif($mode eq 'author') {
      $result{'author'} = $text;
      $result{'author'} =~ s/作成者：//;
      $mode = '';
    }
    elsif($simple_column_table{$text}) {
      $mode = $text;
    }
    elsif($simple_column_table{$mode}) {
      $result{$simple_column_table{$mode}} = $text;
      $result{$simple_column_table{$mode}} =~ s/://;
      $mode = '';
    }
    elsif($parentheses_column_table{$text}) {
      $mode = $text;
    }
    elsif($parentheses_column_table{$mode}) {
      if($text =~ /(\d+)\((\d+)\)/) {
        $result{$parentheses_column_table{$mode}{raw}} = $1;
        $result{$parentheses_column_table{$mode}{fix}} = $2;
      } else {
        $result{$parentheses_column_table{$mode}{raw}} = '-';
        $result{$parentheses_column_table{$mode}{fix}} = '-';
      }
      $mode = '';
    }
    
  }
  while (my ($key, $value) = each(%result)) {
    # JavaScript でいう所の String#trim() を行っている
    $result{$key} =~ s/^\s*(.*?)[\s　]*$/$1/;
  }
  $result{'convertSource'} = '旧ゆとシートM';
  $result{'type'} = 'm';
  $result{'ver'} = 0;
  return %result;
}

1;
