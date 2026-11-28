use strict;
use utf8;

package data::record_list;

# key は保存キーの接頭辞、label は画面に表示する呼び名。
# nameField は名称欄、titleField は複数レコード用のタイトル欄、fields はレコードの保存キーを指定する。
sub new {
  my ($class, %options) = @_;
  my $key = $options{key};
  return bless {
    %options,
    countKey => "${key}Num",
    orderKey => "${key}Order",
    formOrderKey => "${key}FormOrder",
    lastNumberKey => "${key}LastNumber",
    numberedField => qr/\A\Q$key\E([0-9]+)_(.*)\z/,
  }, $class;
}

sub key           { return $_[0]{key}; }
sub label         { return $_[0]{label}; }
sub nameField     { return $_[0]{nameField}; }
sub countKey      { return $_[0]{countKey}; }
sub formOrderKey  { return $_[0]{formOrderKey}; }
sub lastNumberKey { return $_[0]{lastNumberKey}; }

sub count {
  my ($self, $data) = @_;
  my $count = $data->{$self->{countKey}};
  return 1 if !defined($count) || $count !~ /\A[1-9][0-9]*\z/ || $count > keys(%$data);
  return $count;
}

sub sheetName {
  my ($self, $data) = @_;
  if(defined $self->{titleField} && $self->count($data) > 1){
    my $title = $data->{$self->{titleField}} // '';
    return $title if $title =~ /\S/;
  }
  return $data->{$self->{nameField}};
}

sub prefix {
  my ($self, $number) = @_;
  # 先頭の保存欄に従来の単体シートと同じキーを使う。
  return $number eq '1' ? '' : $self->{key}.$number.'_';
}

sub prefixes {
  my ($self, $data) = @_;
  return map { $self->prefix($_) } 1 .. $self->count($data);
}

sub _isNumber {
  my ($number) = @_;
  # 編集画面でも正確に採番できる整数の範囲を使う。
  return defined($number) && $number =~ /\A[1-9][0-9]*\z/ && $number <= 9_007_199_254_740_991;
}

sub _validOrder {
  my ($order) = @_;
  return 0 unless @$order;
  my %seen;
  return !grep { !_isNumber($_) || $seen{$_}++ } @$order;
}

sub order {
  my ($self, $data) = @_;
  my $count = $self->count($data);
  my @order = split /,/, ($data->{$self->{orderKey}} // ''), -1;
  return @order if @order == $count && _validOrder(\@order);
  return 1 .. $count;
}

sub _lastNumber {
  my ($self, $data, @numbers) = @_;
  my $last = 1;
  foreach my $number ($data->{$self->{lastNumberKey}}, @numbers){
    $last = $number if _isNumber($number) && $number > $last;
  }
  return $last;
}

sub _remapFields {
  my ($self, $data, $positions) = @_;
  my %fields;
  foreach my $key (keys %$data){
    my ($number, $field) = $key =~ $self->{numberedField};
    if(!defined $number){
      next unless $key =~ $self->{fields};
      ($number, $field) = (1, $key);
    }
    my $position = $positions->{$number};
    $fields{$self->prefix($position).$field} = $data->{$key}
      if defined($position) && $field =~ $self->{fields};
    delete $data->{$key};
  }
  @$data{keys %fields} = values %fields;
}

# 編集フォームの欄を固定番号で参照できるようにする。履歴編集では最新の採番も引き継ぐ。
sub prepareForm {
  my ($self, $data, $latest) = @_;
  my @order = $self->order($data);
  $latest //= {};
  $data->{$self->{formOrderKey}} = join ',', @order;
  $data->{$self->{lastNumberKey}} = $self->_lastNumber(
    $data, @order, $latest->{$self->{lastNumberKey}}, $latest->{$self->{countKey}},
  );
  $self->_remapFields($data, { map { $_ => $order[$_ - 1] } 1 .. @order });
  return @order;
}

# 保存時と入力途中のデータを読み込む際に、固定番号の欄を表示順に詰め直す。
sub normalizeForm {
  my ($self, $data) = @_;
  my $formOrderKey = $self->{formOrderKey};
  return unless exists $data->{$formOrderKey};
  my @order = split /,/, ($data->{$formOrderKey} // ''), -1;
  return "400:$self->{label}の並び順が不正です。"
    if !_validOrder(\@order)
    || grep { !exists $data->{$self->prefix($_).$self->{nameField}} } @order;

  delete $data->{$formOrderKey};
  $self->_remapFields($data, { map { $order[$_ - 1] => $_ } 1 .. @order });
  $data->{$self->{countKey}} = scalar @order;
  $data->{$self->{orderKey}} = join ',', @order;
  $data->{$self->{lastNumberKey}} = $self->_lastNumber($data, @order);
  return;
}

sub select {
  my ($self, $data, $number) = @_;
  return (undef, "400:$self->{label}番号は1以上の整数で指定してください。")
    if !defined($number) || $number !~ /\A[1-9][0-9]*\z/;
  my @order = $self->order($data);
  my ($position) = grep { $order[$_ - 1] eq $number } 1 .. @order;
  return (undef, "404:指定された番号の$self->{label}は見つかりませんでした。")
    if !defined $position;

  my %record = %$data;
  delete @record{$self->{orderKey}, $self->{lastNumberKey}};
  delete $record{$self->{titleField}} if defined $self->{titleField};
  $record{$self->{countKey}} = 1;
  $self->_remapFields(\%record, { $position => 1 });
  return (\%record, undef);
}

1;
