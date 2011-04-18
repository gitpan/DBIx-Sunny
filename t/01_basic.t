use strict;
use warnings;
use Test::More;
use DBIx::Sunny;
use Encode;
use Test::Requires 'DBD::SQLite';

eval {
    DBIx::Sunny->connect('dbi:unknown:', '', '');
};
ok $@, "dies with unknown driver, automatically.";

my $dbh = DBIx::Sunny->connect('dbi:SQLite::memory:', '', '');
$dbh->do(q{CREATE TABLE foo (e varchar(10))});
ok( $dbh->query(q{INSERT INTO foo (e) VALUES(?)}, 3) );
ok( $dbh->query(q{INSERT INTO foo (e) VALUES(?)}, 4) );
is $dbh->select_one(q{SELECT COUNT(*) FROM foo}), 2;
is_deeply $dbh->select_row(q{SELECT * FROM foo ORDER BY e}), { e => 3 };
is join('|', map { $_->{e} } @{$dbh->select_all(q{SELECT * FROM foo ORDER BY e})}), '3|4';

subtest 'utf8' => sub {
    use utf8;
    ok( $dbh->query(q{CREATE TABLE bar (x varchar(10))}) );
    ok( $dbh->query(q{INSERT INTO bar (x) VALUES (?)}, "こんにちは") );
    my ($x) = $dbh->selectrow_array(q{SELECT x FROM bar});
    is $x, "こんにちは";
    ok( Encode::is_utf8($x) );
};

eval {
    $dbh->query(q{INSERT INTO bar (e) VALUES (?)}, '1');
};
ok $@;
like $@, qr/for Statement/;
like $@, qr!/\* .+ line \d+ \*/!;

my @func = qw/selectall_arrayref selectrow_arrayref selectrow_array/;
for my $func (@func) {
    eval {
        $dbh->$func('select e from bar where e=?',{},'bar');
    };
    ok $@;
    like $@, qr/for Statement/;
    like $@, qr!/\* .+ line \d+ \*/!;
}

is $dbh->connect_info->[0], 'dbi:SQLite::memory:';

done_testing();

