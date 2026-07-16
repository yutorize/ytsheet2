################## 一覧表示：共通 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

our $LOGIN_ID = check;

my %fields;

sub setFields {
  %fields = %{ $_[0] }
}

sub capField {
  my ($line, $key) = @_;
  return ($line =~ /^(?:[^<]*<>){$fields{$key}}([^<]*)/o)[0] // '';
}

sub splitField {
  my @array = split '<>', $_[0];
  my %hash;
  $hash{$_} = $array[ $fields{$_} ] foreach keys %fields;
  return \%hash;
}

sub renderUpdateTime {
  my $unixtime = shift;
  if($unixtime){
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($unixtime);
    return sprintf('<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>', $year+1900, $mon+1, $mday, $hour, $min);
  }
  return '';
}

sub renderTagLinks {
  my ($tags, $session) = @_;
  my $tagsLinks;
  $tagsLinks .= '<a href="./?'.($::in{type} ? "type=$::in{type}&" : "").'tag='.uri_escape_utf8($_).'">'.$_.'</a>' foreach(grep $_, split(/\s+/, $tags));
  $tagsLinks .= qq|<span class="session">$session</span>| if $session;
  return $tagsLinks;
}

sub renderCharacterName {
  my $name = shift;
  $name =~ s/^“(.*)”(.*)$/<span>“$1”<\/span><span>$2<\/span>/;
  return $name;
}

sub renderGender {
  my $gender = checkGender($_[0]);
  return
    ($gender eq 'none'  ) ? '<span data-gender="none">―</span>' :
    ($gender eq 'cross' ) ? '<span data-gender="cross">⚧</span>' :
    ($gender eq 'male'  ) ? '<span data-gender="male">♂</span>' :
    ($gender eq 'female') ? '<span data-gender="female">♀</span>' :
    '<span data-gender="unknown">？</span>'
}

sub renderAge {
  my $age = shift;
  $age =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
  $age =~ tr/０-９/0-9/;
  if($age =~ /[0-9]$/){ $age .= '歳'; }
  $age =~ s/([^0-9]+)/<span class="thin">$1<\/span>/g;
  return $age;
}

sub thinIfLong {
  my ($text, $length) = @_;
  return length($text) >= $length
    ? qq|<span class="thin">$text</span>|
    : $text;
}

### テンプレート操作 --------------------------------------------------
my $template;
my %pageTitleParts;
sub setupListTemplate {
  my (%args) = @_;
  my $type     = $args{type};
  my $typeName = $args{typeName};
  my $typeClass = $args{typeClass};
  my $pageTitle = $args{pageTitle} || $typeName || '';

  my $game =  (exists $set::lib_type{$type}) ? $set::lib_type{$type}{game} || $set::game : $set::game;
  my $systemId = (exists $set::lib_type{$type}) ? $set::lib_type{$type}{systemId} || $set::system_id : $set::system_id || $game;

  $pageTitleParts{type} = $pageTitle if $pageTitle;
  $template = HTML::Template->new(
    filename  => $set::skin_tmpl,
    utf8 => 1,
    path => ['./', $::core_dir."/skin/$game", $::core_dir."/skin/_common", $::core_dir],
    search_path_on_include => 1,
    die_on_bad_params => 0,
    die_on_missing_include => 0,
    case_sensitive => 1,
    global_vars => 1
  );

  $template->param(title => $set::title);
  $template->param(ver => $::ver);
  $template->param(coreDir => $::core_dir);
  $template->param(gameDir => $game);
  $template->param(systemId => $systemId);
  
  $template->param(mode => $::in{mode});
  
  $template->param("modeList".uc($type) => 1);
  $template->param("mylistURL" => qq|./?mode=mylist|.($type ? "&type=$type" : ''));

  $template->param(type => $type);
  $template->param(typeName => $typeName);
  $template->param(typeClass => $typeClass || $set::lib_type{$type}{sheetType} || 'chara');

  $template->param(LOGIN_ID => $LOGIN_ID);
  $template->param(OAUTH_MODE => $set::oauth_service);
  $template->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

  return $template;
}
## 最終アウトプット
sub printFinalizedList {
  my @pageTitles;
  foreach ('group','search','type') {
    push(@pageTitles, $pageTitleParts{$_}) if exists $pageTitleParts{$_};
  }
  $template->param(pageTitle => join(' - ', @pageTitles) . ' - ') if @pageTitles;
  print "Content-Type: text/html; charset=utf-8\n\n";
  print outputTemplate($template);
}
### クエリ関係の処理 --------------------------------------------------
my $indexMode;
sub listQueryInfo {
  my (%args) = @_;
  my @queryKeys = @{ $args{queryKeys} };
  my %excludeFromQLinks = %{ $args{excludeFromQLinks} || {} };
  
  my @canonicalQueries;
  foreach ('type','tag') {
    push(@canonicalQueries, "$_=$::in{$_}") if $::in{$_};
  }

  my @qLinks;
  foreach my $key (@queryKeys) {
    $::in{$key} = trim($::in{$key});
    next if $::in{$key} eq '';
    $::in{$key} = decode('utf8', $::in{$key});
    $::in{$key} = escapeThanSign($::in{$key});
    $template->param(kebabToCamel($key) => $::in{$key});

    if (exists $excludeFromQLinks{$key}){
      push(@canonicalQueries, $key.'='.uri_escape_utf8($::in{$key}));
    }
    else {
      push(@qLinks, $key.'='.uri_escape_utf8($::in{$key}));
    }
  }
  
  $template->param(canonicalURL =>
    url(-full => 1, -query => 0)
    . (@canonicalQueries ? '?'.join('&', @canonicalQueries) : '')
  );
  
  my $qLinks = @qLinks ? '&'.join('&', @qLinks) : '';
  $template->param(qLinks => $qLinks);

  $indexMode = 1;
  if($::in{mode} eq 'mylist') {
    $indexMode = 0;
    $template->param(modeMylist => 1);
  }
  else {
    foreach my $key (@queryKeys) {
      if($::in{$key}) {
        $indexMode = 0;
        last;
      }
    }
  }
  if($indexMode) {
    delete $pageTitleParts{type} if !$::in{type};
    $template->param(modeIndex => 1);
    $template->param(simpleList => 1) if $set::simplelist;
    $template->param(simpleIndex => 1) if $set::simpleindex;
  }

  return $indexMode, $qLinks;
}

### 一覧データ取得 --------------------------------------------------
sub loadLines {
  my (%args) = @_;

  if($set::simpleindex && $indexMode) {
    return ();
  }

  if($::in{mode} eq 'mylist') {
    return getMylist($LOGIN_ID);
  }

  if(open(my $READ, '<', $set::listfile)) {
    if(($set::masterid && $set::masterid eq $LOGIN_ID) || $::in{tag}) {
      return  <$READ>;
    }
    else {
      return grep { !/^(?:[^<]*<>){$fields{hide}}[^<0]/o } <$READ>;
    }
    # close($READ); # クローズ不要（GCに任せる）
  }
  
  return ();
}
## マイリスト取得
sub getMylist {
  my %mylist;
  open (my $FH, "<", $set::passfile);
  while(my $line = <$FH>){
    if($line =~ /^(.+?)<>\[$_[0]\]</){ $mylist{$1} = 1 }
  }
  close($FH);
  my @list;
  open (my $FH, "<", $set::listfile);
  foreach (<$FH>){
    if($_ =~ /^(.+?)<>/ && exists $mylist{$1}){
      push(@list, $_);
      delete $mylist{$1};
    }
    if(!%mylist){ last; }
  }
  close($FH);
  return @list;
}

### グループ設定 --------------------------------------------------
my %groups;
sub setupGroupList {
  %groups = groupArrayToHash();
  $groups{all}{name} = 'すべて' if $::in{group} eq 'all';
  $template->param(Groups => groupArrayToList());
  $template->param(group => $groups{$::in{group}}{name});
  return %groups;
}
sub groupArrayToHash {
  my @array = $_[0] ? @{$_[0]} : @set::groups;
  my %hash;
  foreach (@array){
    $hash{@$_[0]} = {
      "sort" => @$_[1],
      "name" => @$_[2],
      "text" => @$_[3],
    };
  }
  return %hash;
}
sub groupArrayToList {
  my @array = $_[1] ? @{$_[1]} : @set::groups;
  my @list;
  foreach (sort { $a->[1] cmp $b->[1] } @array){
    push(@list, {
      "ID" => @$_[0],
      "NAME" => @$_[2],
      "TEXT" => @$_[3],
      "SELECTED" => $::in{group} eq @$_[0] ? 'selected' : '',
    });
  }
  return \@list;
}

### 検索フィルタ --------------------------------------------------
## 名前キー
sub sortKeyName {
  $_[0] =~ /^(?:[^<]*<>){$fields{name}}(?:“\s*(.*?)”)?\s*(.*?)</o; return $2 || $1;
}
## グループ
sub filterGroup {
  my @lines = @_;
  if($::in{group} eq $set::group_default){
    return grep { /^(?:[^<]*<>){$fields{group}}(\Q$::in{group}\E)?</o } @lines;
  }
  return grep { /^(?:[^<]*<>){$fields{group}}\Q$::in{group}\E</o } @lines;
}
## タグ
sub filterTag {
  my @lines = @_;
  my $tagQuery = normalizeHashtags($::in{tag});
  return grep { /^(?:[^<]*<>){$fields{tags}}[^<]*? \Q$tagQuery\E /o } @lines;
}
## 画像
sub filterImage {
  my @lines = @_;
  if($::in{image} eq '1') {
    $template->param(image => 1);
    return grep { /^(?:[^<]*<>){$fields{image}}[^<0]/o } @lines;
  }
  elsif($::in{image} eq 'N') {
    $template->param(image => 0);
    return grep { /^(?:[^<]*<>){$fields{image}}[<0]/o } @lines;
  }
  elsif($::in{image}) {
    return grep { /^(?:[^<]*<>){$fields{image}}[^<]*?\Q$::in{image}\E/o } @lines;
  }
  return @lines;
}
## 性別
sub filterGender {
  my @lines = @_;

  my $value = $::in{gender};
  if($value =~ /^(male|female|cross|none)$/){
    $template->param('gender'.ucfirst($value) => 'checked');
    $::in{gender} = renderGender($value);
  }

  return grep {
    my ($gender) = $_ =~ /^(?:[^<]*<>){$fields{gender}}([^<]*)/o;
    $value eq checkGender($gender // '');
  } @lines;
}
## 汎用：部分一致
sub filterContainsRegex {
  my (%args) = @_;
  my $key   = $args{key};
  my $flags = $args{flags} || '';
  my $query = exists $args{query} ? $args{query} : $::in{$key};

  return @{ $args{lines} } if !$query;

  my $regex;
  if($flags =~ /i/) {
    $regex = qr/^(?:[^<]*<>){$fields{$key}}[^<]*?\Q$query\E/i;
  }
  else {
    $regex = qr/^(?:[^<]*<>){$fields{$key}}[^<]*?\Q$query\E/;
  }
  return grep { $_ =~ $regex } @{ $args{lines} };
}
## 汎用：完全一致
sub filterExactRegex {
  my (%args) = @_;
  my $key   = $args{key};
  my $flags = $args{flags} || '';
  my $empty = $args{emptyKeyword} || '';

  return @{ $args{lines} } if !$::in{$key};

  my $query = ($::in{$key} eq $empty) ? '' : $::in{$key};

  my $regex;
  if($flags =~ /i/) {
    $regex = qr/^(?:[^<]*<>){$fields{$key}}\Q$query\E</i;
  }
  else {
    $regex = qr/^(?:[^<]*<>){$fields{$key}}\Q$query\E</;
  }
  return grep { $_ =~ $regex } @{ $args{lines} };
}
## 汎用：I/O
sub filterFlagRegex {
  my (%args) = @_;
  my $key = $args{key};

  return @{ $args{lines} } if !exists $::in{$key} || $::in{$key} eq '';

  my $regex = qr/^(?:[^<]*<>){$fields{$key}}[^<0]/i;
  if($::in{$key} eq '1') {
    $template->param(kebabToCamel($key) => 1);
    return grep { $_ =~ $regex } @{ $args{lines} };
  }
  elsif($::in{$key} eq 'N') {
    $template->param(kebabToCamel($key) => 0);
    return grep { $_ !~ $regex } @{ $args{lines} };
  }
  return @{ $args{lines} };
}
## 汎用：範囲
sub filterRange {
  my (%args) = @_;
  my $key    = $args{key};
  my $minKey = $args{minKey} || "${key}-min";
  my $maxKey = $args{maxKey} || "${key}-max";
  my $minValueOf = $args{minValueOf};
  my $maxValueOf = $args{maxValueOf};

  if   ($::in{$minKey} eq $::in{$maxKey}){ $::in{$key} = $::in{$minKey}; }
  elsif($::in{$minKey} || $::in{$maxKey}){ $::in{$key} = $::in{$minKey}.'～'.$::in{$maxKey}; }
  $template->param(kebabToCamel($key) => $::in{$key});

  my @lines = @{ $args{lines} };
  my $regex = qr/^(?:[^<]*<>){$fields{$key}}([^<]*)/;
  if($::in{$minKey} ne '') {
    @lines = grep {
      my $value = $minValueOf ? $minValueOf->(($_ =~ $regex)[0]) : ($_ =~ $regex)[0];
      $value >= $::in{$minKey}
    } @lines;
  }
  if($::in{$maxKey} ne '') {
    @lines = grep {
      my $value = $maxValueOf ? $maxValueOf->(($_ =~ $regex)[0]) : ($_ =~ $regex)[0];
      $value <= $::in{$maxKey}
    } @lines;
  }
  return @lines;
}
### ページ切り出し --------------------------------------------------
sub prepareGroupedPage {
  my (%args) = @_;
  my @lines         = @{ $args{lines} };
  my $selectedGroup = $args{selectedGroup};
  my $hasTagQuery   = $args{hasTagQuery};
  my $countExtraOf  = $args{countExtraOf};

  my %count = ( PC => {}, PL => {} );
  my $page = $::in{page} || 1;
  my $pageStart = $page * $set::pagemax - $set::pagemax + 1;
  my $pageEnd   = $page * $set::pagemax;

  # グループ指定があり、pagemax が有効な場合:
  # 既に検索・分類フィルタ済みの @lines 全体が、そのグループの対象件数になる
  if($selectedGroup && $set::pagemax) {
    $count{PC}{$selectedGroup} = scalar(@lines);
    $count{PL}{$selectedGroup} = {};

    if($countExtraOf){
      foreach my $line (@lines) {
        my $extraKey = $countExtraOf->($line);
        $count{PL}{$selectedGroup}{$extraKey}++ if defined $extraKey && $extraKey ne '';
      }
    }

    $pageEnd = $count{PC}{$selectedGroup} if $pageEnd > $count{PC}{$selectedGroup};
    @lines = @lines[$pageStart-1 .. $pageEnd-1] if @lines;
  }

  my $shouldSkip = sub {
    my (%row) = @_;
    my $group = $row{group};
    my $extra = $row{extra};

    # グループ指定時は、上でページ切り出し済みなのでここでは数え直さない
    return 0 if $selectedGroup && $set::pagemax;

    $count{PC}{$group}++;
    $count{PL}{$group}{$extra}++ if defined $extra && $extra ne '';

    # TOPページ: グループごとに list_maxline 件まで。
    return 1 if (
      $indexMode &&
      $set::list_maxline &&
      $count{PC}{$group} > $set::list_maxline
    );

    # 検索結果でグループ未指定・タグ検索でもマイリストでもない場合
    return 1 if (
      !$selectedGroup &&
      !$hasTagQuery &&
      $::in{mode} ne 'mylist' &&
      $set::list_maxline &&
      $count{PC}{$group} > $set::list_maxline
    );

    # グループ未指定時の通常ページング
    return 1 if (
      !$indexMode &&
      $set::pagemax &&
      ($count{PC}{$group} < $pageStart || $count{PC}{$group} > $pageEnd)
    );

    return 0;
  };
  return (\@lines, \%count, $page, $pageStart, $pageEnd, $shouldSkip);
}

### 出力用配列生成 --------------------------------------------------
## キャラクター用
sub makeCharacterGroup {
  my (%args) = @_;
  my $id = $args{id};

  return {
    ID      => $id,
    NAME    => $groups{$id}{name},
    TEXT    => $groups{$id}{text},
    NUM     => $args{count}{PC}{$id},
    'NUM-PL'=> $args{count}{PL}{$id},
    Lines   => $args{lines},
    PAGER   => $args{pager},
    MORE    => $args{more},
  };
}
## 汎用
sub makeGroupedLists {
  my (%args) = @_;
  my @groupOrder   = @{ $args{groupOrder} };
  my %groupedLists = %{ $args{groupedLists} };
  my %count        = %{ $args{count} };

  my $showEmptyGroups  = exists $args{showEmptyGroups} ? $args{showEmptyGroups} : 0;

  my $makePager = $args{makePager};
  my $makeGroup = $args{makeGroup};

  my @lists;

  foreach my $group (@groupOrder) {
    my $id  = groupId($group);
    my $num = $count{PC}{$id} || 0;

    next if !$num && !$showEmptyGroups;

    my $lines = $groupedLists{$id} ? [@{$groupedLists{$id}}] : [];

    my $pager = $makePager ? $makePager->(
      id    => $id,
      group => $group,
      count => $num,
    ) : '';

    push(@lists, $makeGroup->(
      id    => $id,
      group => $group,
      count => \%count,
      num   => $num,
      lines => $lines,
      pager => $pager,
      more  => (!$pager && $num > scalar(@$lines)) ? 1 : 0,
    ));
  }

  return @lists;
}
sub groupId {
  my $group = shift;

  if(ref($group) eq 'HASH') {
    return $group->{id};
  }
  elsif(ref($group) eq 'ARRAY') {
    return $group->[0];
  }

  return $group;
}
## ページネーション生成
sub makePager {
  my (%args) = @_;
  my $count      = $args{count};
  my $page       = $args{page};
  my $enabled    = $args{enabled};
  my $queryBase = $args{queryBase}.($::in{sort} ? "&sort=$::in{sort}" : '');

  return '' if !$set::pagemax;
  return '' if $indexMode;
  return '' if !$enabled;
  
  my $OUTPUT;
  my $lastpage = ceil($count / $set::pagemax);
  
  if($lastpage > 1){
    foreach(1 .. $lastpage){
      if($_ == $page){
        $OUTPUT .= '<b>'.$_.'</b> ';
      }
      elsif(
        ($_ <= $page + 4 && $_ >= $page - 4) ||
        $_ == 1 ||
        $_ == $lastpage
      ){
        $OUTPUT .= '<a href="./?'.$queryBase.'&page='.$_.'">'.$_.'</a> ';
      }
      else { $OUTPUT .= '...' }
    }
    $OUTPUT =~ s/\.{3,}/... /g;
  }
  $OUTPUT = qq|<div class="pager">$OUTPUT</div>| if $OUTPUT;
}

### セレクトボックス用配列生成 --------------------------------------------------
sub makeSelectOptions {
  my (%args) = @_;
  my @values   = @{ $args{values} || [] };
  my $selected = $args{selected};

  my $idOf     = $args{idOf};
  my $nameOf   = $args{nameOf};
  my $labelOf  = $args{labelOf};
  my $extraOf  = $args{extraOf};

  my @options;

  foreach my $value (@values) {
    my $label = $labelOf ? $labelOf->($value) : undef;
    if(defined $label && $label ne '') {
      push(@options, { LABEL => $label });
      next;
    }

    my $id   = $idOf    ? $idOf->($value)    : defaultOptionValue($value);
    my $name = $nameOf  ? $nameOf->($value)  : $id;
    my %option = (
      ID       => $id,
      NAME     => $name,
      SELECTED => defined($selected) && defined($id) && $selected eq $id ? 'selected' : '',
    );

    if($extraOf) {
      my $extra = $extraOf->($value, $id, $name);
      %option = (%option, %$extra) if $extra;
    }

    push(@options, \%option);
  }

  return @options;
}

sub defaultOptionValue {
  my $value = shift;

  if(ref($value) eq 'ARRAY') {
    return $value->[0];
  }
  elsif(ref($value) eq 'HASH') {
    return $value->{id} // $value->{ID} // $value->{name} // $value->{NAME};
  }

  return $value;
}
### 検索サマリ --------------------------------------------------
sub setSearchSummary {
  my %args; my @array;
  foreach (@_){
    if   (ref($_) eq 'HASH') { %args = (%args, %$_) }
    elsif(ref($_) eq 'ARRAY'){ push @array, $_ }
  }
  my @summary;
  if($::in{mode} eq 'mylist') { push(@summary, 'マイリスト') }
  if($groups{$::in{group}}{name}){ push(@summary, $groups{$::in{group}}{name}) }
  foreach (
    [ $::in{tag},  'タグ「%s」' ],
    [ $::in{name}, ($args{nameHeader} || '名前').'に「%s」を含む' ],
    [ $::in{player}, 'ＰＬ名に「%s」を含む' ],
    [ $::in{author}, '製作者名に「%s」を含む' ],
    [ $::in{gender}, '性別「%s」' ],
    @array,
    [ $::in{image}, ($::in{image} eq '1' ? '画像あり' : $::in{image} eq 'N' ? '画像なし' : '画像「%s」') ],
  ) {
    my ($value, $format) = @$_;
    next if !defined($value) || $value eq '';
    push(@summary,
      $format =~ /%s/
      ? sprintf($format, $value)
      : $format
    );
  }

  if(@summary){
    $template->param(searchSummary => join('／', map { "<span>$_</span>" } @summary));
    $template->param(ogDescript => removeTags(join ',', @summary));
    $pageTitleParts{search} = removeTags(join ' ', @summary);
  }
}

1;
