use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use lib 'lib';

my $t      = Test::Mojo->new('Mojodbic');
my $schema = $t->app->schema;

$schema->deploy( { add_drop_table => 1, } );

$schema->resultset('Company')->populate(
	[
		{
			name     => 'ACME',
			products => [ { name => 'anvil' }, { name => 'dynamite' }, ]
		},
		{
			name     => 'Google',
			products => [ { name => 'Gmail' }, { name => 'Maps' }, ]
		},
		{
			name     => 'Apple',
			products => [ { name => 'iPad' }, { name => 'iPhone' }, ]
		},
		{
			name     => 'America',
			products => [ { name => 'Freedom' }, { name => 'Ass Kickings' }, ]
		},
	]
);

my $rs = $schema->resultset('Company')->search(
	{ 'me.name' => { -like => 'A%' } },
	{
		prefetch     => 'products',
		order_by     => 'me.name',
		result_class => 'DBIx::Class::ResultClass::HashRefInflator',
	}
);

my ( $count_sql, @count_bind_params ) = @{ ${ $rs->count_rs->as_query } };
my @count_bind_values = map { pop @$_ } @count_bind_params;

$rs = $rs->search( undef, { rows => 2 } );
my ( $data_sql, @data_bind_params ) = @{ ${ $rs->as_query } };
my @data_bind_values = map { pop @$_ } @data_bind_params;

my $pg = $t->app->pg;

Mojo::IOLoop->delay(
	sub {
		my $delay = shift;

		# First query, just get the time
		$pg->db->query( 'select now() as now' => $delay->begin );

		# Second query, get some data
		$pg->db->query( $data_sql => @data_bind_values => $delay->begin );

		# Third query, get the count (has same bind params as data)
		$pg->db->query( $count_sql => @count_bind_values => $delay->begin );
	},
	sub {
		my ( $delay, $time_err, $time, $stuffs_err, $stuffs, $count_err, $count ) = @_;
		if ( my $err = $time_err || $stuffs_err || $count_err ) { die $err }

		# First query results
		diag $time->hash->{now};

		# Second query results
		my $data_r = $stuffs->arrays->to_array;
		diag explain $data_r;

		# ...construct results manually
		$rs->{_stashed_rows} = $data_r;
		my @rows = $rs->_construct_results('fetch_all');
		diag explain \@rows;

		# Third query results
		diag sprintf( 'Count: %i', $count->array->[0] );
	}
)->wait;

done_testing();
