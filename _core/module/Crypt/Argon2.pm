package Crypt::Argon2;
$Crypt::Argon2::VERSION = '0.030';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/
	argon2_raw argon2_pass argon2_verify
	argon2id_raw argon2id_pass argon2id_verify
	argon2i_raw argon2i_pass argon2i_verify
	argon2d_raw argon2_pass argon2_verify
	argon2_needs_rehash argon2_types/;
use XSLoader;
XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION || 0);

our $type_regex = qr/argon2(?:i|d|id)/;

my %multiplier = (
	k => 1,
	M => 1024,
	G => 1024 * 1024,
);

my $regex = qr/ ^ \$ (argon2(?:i|d|id)) \$ v=(\d+) \$ m=(\d+), t=(\d+), p=(\d+) \$ ([^\$]+) \$ (.*) $ /x;

sub argon2_needs_rehash {
	my ($encoded, $type, $t_cost, $m_cost, $parallelism, $output_length, $salt_length) = @_;
	$m_cost =~ s/ \A (\d+) ([kMG]) \z / $1 * $multiplier{$2} * 1024 /xmse;
	$m_cost /= 1024;
	my ($name, $version, $m_got, $t_got, $parallel_got, $salt, $hash) = $encoded =~ $regex or return 1;
	return 1 if $name ne $type or $version != 19 or $t_got != $t_cost or $m_got != $m_cost or $parallel_got != $parallelism;
	return 1 if int(3 / 4 * length $salt) != $salt_length or int(3 / 4 * length $hash) != $output_length;
	return 0;
}

sub argon2_types {
	return qw/argon2id argon2i argon2d/;
}

1;

# ABSTRACT: Perl interface to the Argon2 key derivation functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Argon2 - Perl interface to the Argon2 key derivation functions

=head1 VERSION

version 0.030

=head1 SYNOPSIS

 use Crypt::Argon2 qw/argon2id_pass argon2_verify/;

 sub add_pass {
   my ($user, $password) = @_;
   my $salt = get_random(16);
   my $encoded = argon2id_pass($password, $salt, 3, '32M', 1, 16);
   store_password($user, $encoded);
 }

 sub check_password {
   my ($user, $password) = @_;
   my $encoded = fetch_encoded($user);
   return argon2_verify($encoded, $password);
 }

=head1 DESCRIPTION

This module implements the Argon2 key derivation function, which is suitable to convert any password into a cryptographic key. This is most often used to for secure storage of passwords but can also be used to derive a encryption key from a password. It offers variable time and memory costs as well as output size.

To find appropriate parameters, the bundled program C<argon2-calibrate> can be used.

=head1 FUNCTIONS

=head2 argon2_pass($type, $password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

This function processes the C<$password> with the given C<$salt> and parameters. It encodes the resulting tag and the parameters as a password string (e.g. C<$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$wWKIMhR9lyDFvRz9YTZweHKfbftvj+qf+YFY4NeBbtA>).

=over 4

=item * C<$type>

The argon2 type that is used. This must be one of C<'argon2id'>, C<'argon2i'> or C<'argon2d'>.

=item * C<$password>

This is the password that is to be turned into a cryptographic key.

=item * C<$salt>

This is the salt that is used. It must be long enough to be unique.

=item * C<$t_cost>

This is the time-cost factor, typically a small integer that can be derived as explained above.

=item * C<$m_factor>

This is the memory costs factor. This must be given as a integer followed by an order of magnitude (C<k>, C<M> or C<G> for kilobytes, megabytes or gigabytes respectively), e.g. C<'64M'>.

=item * C<$parallelism>

This is the number of threads that are used in computing it.

=item * C<$tag_size>

This is the size of the raw result in bytes. Typical values are 16 or 32.

=back

=head2 argon2_verify($encoded, $password)

This verifies that the C<$password> matches C<$encoded>. All parameters and the tag value are extracted from C<$encoded>, so no further arguments are necessary.

=head2 argon2_raw($type, $password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

This function processes the C<$password> with the given C<$salt> and parameters much like C<argon2_pass>, but returns the binary tag instead of a formatted string.

=head2 argon2id_pass($password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

=head2 argon2i_pass($password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

=head2 argon2d_pass($password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

This function processes the C<$password> much like C<argon2_pass> does, but the C<$type> argument is set like the function name.

=head2 argon2id_verify($encoded, $password)

=head2 argon2i_verify($encoded, $password)

=head2 argon2d_verify($encoded, $password)

This verifies that the C<$password> matches C<$encoded> and the given type. All parameters and the tag value are extracted from C<$encoded>, so no further arguments are necessary.

=head2 argon2id_raw($password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

=head2 argon2i_raw($password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

=head2 argon2d_raw($password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)

This function processes the C<$password> much like C<argon2_raw> does, but the C<$type> argument is set like the function name.

=head2 argon2_needs_rehash($encoded, $type, $t_cost, $m_cost, $parallelism, $output_length, $salt_length)

This function checks if a password-encoded string needs a rehash. It will return true if the C<$type> (valid values are C<argon2i>, C<argon2id> or C<argon2d>), C<$t_cost>, C<$m_cost>, C<$parallelism>, C<$output_length> or C<$salt_length> arguments mismatches any of the parameters of the password-encoded hash.

=head2 argon2_types

This returns all supported argon2 subtypes. Currently that's C<'argon2id'>, C<'argon2i'> and C<'argon2d'>.

=head2 ACKNOWLEDGEMENTS

This module is based on the reference implementation as can be found at L<https://github.com/P-H-C/phc-winner-argon2>.

=head2 SEE ALSO

You will also need a good source of randomness to generate good salts. Some possible solutions include:

=over 4

=item * L<Net::SSLeay|Net::SSLeay>

Its RAND_bytes function is OpenSSL's pseudo-randomness source.

=item * L<Crypt::URandom|Crypt::URandom>

A minimalistic abstraction around OS-provided non-blocking (pseudo-)randomness.

=item * C</dev/random> / C</dev/urandom>

A Linux/BSD specific pseudo-file that will allow you to read random bytes.

=back

Implementations of other similar algorithms include:

=over 4

=item * L<Crypt::Bcrypt|Crypt::Bcrypt>

An implementation of bcrypt, a battle-tested algorithm that tries to be CPU but not particularly memory intensive.

=item * L<Crypt::ScryptKDF|Crypt::ScryptKDF>

An implementation of scrypt, a older scheme that also tries to be memory hard.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Daniel Dinu, Dmitry Khovratovich, Jean-Philippe Aumasson, Samuel Neves, Thomas Pornin and Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
