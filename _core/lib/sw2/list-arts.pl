################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

my $mode = $::in{mode};
my $sort = $::in{sort};

#require $set::data_item;

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

$INDEX->param(modeArtsList => 1);
$INDEX->param(modeMylist => 1) if $mode eq 'mylist';
$INDEX->param(typeName => '魔法');

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);
$INDEX->param(type => 'a');

### データ処理 #######################################################################################
### クエリ --------------------------------------------------
my $index_mode;
foreach (keys %::in) {
  $::in{$_} =~ s/</&lt;/g;
  $::in{$_} =~ s/>/&gt;/g;
}
if(!($mode eq 'mylist' || $::in{tag} || $::in{name} || $::in{category} || $::in{sub} || $::in{author})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
}
my @q_links;
foreach(
  'mode',
  'tag',
  'name',
  #'category',
  'sub',
  'author',
  ){
  push( @q_links, $_.'='.uri_escape_utf8(decode('utf8', param($_))) ) if param($_);
}
my $q_links = @q_links ? '&'.join('&', @q_links) : '';

### ファイル読み込み --------------------------------------------------
## マイリスト取得
my @mylist;
if($mode eq 'mylist'){
  $INDEX->param( playerName => (getplayername($LOGIN_ID))[0] );
  open (my $FH, "<", $set::passfile);
  while(my $line = <$FH>){
    if($line =~ /^(.+?)<>\[$LOGIN_ID\]</){ push(@mylist, $1) }
  }
  close($FH);
}

## リスト取得
my @list;
#if($set::simpleindex && $index_mode){ #グループ見出しのみ
#  my @grouplist;
#    push(@grouplist, {
#      "ID" => 'all',
#      "NAME" => 'すべて',
#    });
#  $INDEX->param(ListGroups => \@grouplist);
#}
#else { #通常
  open (my $FH, "<", $set::listfile);
  @list = <$FH>;
  close($FH);
#}
### フィルタ処理 --------------------------------------------------
## マイリスト
if($mode eq 'mylist'){
  my $regex = join('|', @mylist);
  @list = grep { $_ =~ /^(?:$regex)\</ } @list;
}
## 非表示除外
elsif (
     !($set::masterid && $set::masterid eq $LOGIN_ID)
  && !($mode eq 'mylist')
  && !$::in{tag}
){
  @list = grep { $_ !~ /^(?:[^<]*?<>){11}[^<0]/ } @list;
}

## カテゴリ検索
my %category = ('magic'=>'魔法','god'=>'神格','school'=>'流派');
my $category_query = $::in{category};
if($category_query && $::in{category} ne 'all'){
  @list = grep { $_ =~ /^(?:[^<]*?<>){6}(\Q$category_query\E)?</ } @list;
  $INDEX->param(category => $category{$category_query});
}
{
  my @categories;
  foreach ('magic','god','school'){
    push(@categories, {
      "ID" => $_,
      "NAME" => $category{$_},
      "SELECTED" => $category_query eq $_ ? 'selected' : '',
    });
  }
  $INDEX->param(Groups => \@categories);
}

## 小分類検索
my $sub_query = decode('utf8', $::in{sub});
if($sub_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){7}[^<]*?\Q$sub_query\E/i } @list; }
$INDEX->param(sub => $sub_query);

## タグ検索
my $tag_query = normalizeHashtags(decode('utf8', $::in{tag}));
if($tag_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){10}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{name});
if($name_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

### ソート --------------------------------------------------
if   ($sort eq 'name')  { my @tmp = map { (split /<>/)[4] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'author'){ my @tmp = map { (split /<>/)[5] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'date')  { my @tmp = map { (split /<>/)[3] } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }

### リストを回す --------------------------------------------------
my %count;
my %grouplist;
my $page = $::in{page} || 1;
my $pagestart = $page * $set::pagemax - $set::pagemax + 1;
my $pageend   = $page * $set::pagemax;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $author, $category, $sub, $summary,
    $image, $tag, $hide
  ) = (split /<>/, $_)[0..13];
  
  #カウント
  $count{$category}++;

  #表示域以外は弾く
  if (
    ( $index_mode && $count{$category} > $set::list_maxline && $set::list_maxline) || #TOPページ
    ( !$::in{category} && !$::in{tag} && $mode ne 'mylist' && $count{$category} > $set::list_maxline && $set::list_maxline) || #検索結果（分類指定なし／マイリストでもなし）
    (!$index_mode && $set::pagemax && ($count{$category} < $pagestart || $count{$category} > $pageend)) #それ以外
  ){
    next;
  }
  
  #名前
  if($category =~ /magic|school/){ $name = '【'.$name.'】'; }
  
  #グループ（分類）
  my $category_text = $category{$category};
  if($sub =~ /妖精/){ $sub =~ s#(／[0-9]+)#$1ランク#; }
  else { $sub =~ s#(／[0-9]+)#$1レベル#; }
  $sub = subTextShape($sub);

  #タグ
  my $tags_links;
  foreach(grep $_, split(/ /, $tag)){ $tags_links .= '<a href="./?type=a&tag='.uri_escape_utf8($_).'">'.$_.'</a>'; }

  #更新日時
  my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
  $year += 1900; $mon++;
  $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
  
  #出力用配列へ
  my @characters;
  push(@characters, {
    "ID" => $id,
    "NAME" => $name,
    "AUTHOR" => $author,
    "CATEGORY" => $category_text,
    "SUB" => $sub,
    "SUMMARY" => $summary,
    "TAGS" => $tags_links,
    "DATE" => $updatetime,
    "HIDE" => $hide,
  });
  
  push(@{$grouplist{$category}}, @characters);
}
sub subTextShape {
  my @texts = split('／', shift);
  foreach(@texts){ $_ = "<span>$_</span>"; }
  return '<div>'.join('／', @texts).'</div>';
}

### 出力用配列 --------------------------------------------------
my @characterlists;
foreach my $id ('magic','god','school'){
  next if !$count{$id};

  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode && ($::in{category} || $mode eq 'mylist')){
    my $lastpage = ceil($count{$id} / $set::pagemax);
    if($lastpage > 1){
      foreach(1 .. $lastpage){
        if($_ == $page){
          $navbar .= '<b>'.$_.'</b> ';
        }
        elsif(
          ($_ <= $page + 4 && $_ >= $page - 4) ||
          $_ == 1 ||
          $_ == $lastpage
        ){
          $navbar .= '<a href="./?type=a&category='.$id.$q_links.'&page='.$_.'&sort='.$::in{sort}.'">'.$_.'</a> '
        }
        else { $navbar .= '...' }
      }
      $navbar =~ s/\.{3,}/... /g;
    }
    $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  }

  ##
  push(@characterlists, {
    "URL" => $id,
    "NAME" => $category{$id},
    "NUM" => $count{$id},
    "Characters" => [@{$grouplist{$id}}],
    "NAV" => $navbar,
  });
}

$INDEX->param(qLinks => $q_links);

$INDEX->param(Lists => \@characterlists);


$INDEX->param(ogUrl => self_url());
$INDEX->param(ogDescript => 
  ($name_query ? "名称「${name_query}」を含む " : '') .
  ($tag_query  ? "タグ「${tag_query}」 " : '') .
  ($category_query ? "大分類「$category{$category_query}」 " : '') .
  ($sub_query      ? "小分類「${sub_query}」 " : '')
);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;