use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;

require "$FindBin::Bin/../_core/lib/data-record-list.pl";

my $records = data::record_list->new(
  key => 'enemy',
  label => '魔物',
  nameField => 'monsterName',
  fields => qr/\A(?:monsterName|hp|part[0-9]+Name)\z/,
);

my %data = (
  enemyNum => 2,
  monsterName => 'Wolf',
  hp => 12,
  enemy2_monsterName => 'Bear',
  enemy2_hp => 30,
  enemy2_part1Name => 'Claw',
  description => 'Common description',
  other2_hp => 10,
);

is_deeply([$records->order(\%data)], [1, 2], 'Legacy records use storage order');
is_deeply([$records->prepareForm(\%data)], [1, 2], 'Legacy records open for editing');
is($data{enemyFormOrder}, '1,2', 'The edit order uses the configured key');
is($data{enemyLastNumber}, 2, 'Legacy IDs determine the initial counter');

$data{enemyFormOrder} = '2,1';
is($records->normalizeForm(\%data), undef, 'A valid reorder can be saved');
is_deeply(
  \%data,
  {
    enemyNum => 2,
    enemyOrder => '2,1',
    enemyLastNumber => 2,
    monsterName => 'Bear',
    hp => 30,
    part1Name => 'Claw',
    enemy2_monsterName => 'Wolf',
    enemy2_hp => 12,
    description => 'Common description',
    other2_hp => 10,
  },
  'Storage fields follow display order, with a separate list of stable IDs',
);

my ($wolf, $error) = $records->select(\%data, 1);
is($error, undef, 'The original fixed ID remains valid');
is_deeply(
  $wolf,
  { enemyNum => 1, monsterName => 'Wolf', hp => 12,
    description => 'Common description', other2_hp => 10 },
  'Selecting one record retains common fields and drops the other record',
);

is_deeply([$records->prepareForm(\%data, { enemyLastNumber => 5 })], [2, 1], 'Saved order is restored');
is($data{enemyLastNumber}, 5, 'Historical editing uses the current high-water mark');
is($data{enemy2_part1Name}, 'Claw', 'Form fields use the stable ID again');

my %invalid = (%data, enemyFormOrder => '2,2');
my %original = %invalid;
is(substr($records->normalizeForm(\%invalid), 0, 4), '400:', 'Duplicate IDs cause a validation error');
is_deeply(\%invalid, \%original, 'Invalid input leaves the data intact');

$data{enemyNum} = 1;
$data{enemyFormOrder} = '2';
is($records->normalizeForm(\%data), undef, 'A single record can retain a higher ID');
is((($records->select(\%data, 2))[0])->{monsterName}, 'Bear', 'The remaining record is still addressable');
is(substr(($records->select(\%data, 1))[1], 0, 4), '404:', 'A removed ID no longer resolves');
is($data{enemyLastNumber}, 5, 'Deleting records does not roll back the counter');

done_testing();
