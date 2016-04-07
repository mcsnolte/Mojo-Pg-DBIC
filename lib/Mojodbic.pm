package Mojodbic;
use Mojo::Base 'Mojolicious';

use Mojo::Pg;
use Mojodbic::Schema;

has pg => sub {
	return Mojo::Pg->new('postgresql://snolte@/mojodbic');
};

# This method will run once at server start
sub startup {
	my $self = shift;

	$self->helper(
		schema => sub {

			# use callback to connect with a DB handle from Mojo::Pg
			return Mojodbic::Schema->connect( sub { $self->pg->db->dbh } );
		}
	);
	$self->helper( pg => sub { $self->app->pg } );

	# Documentation browser under "/perldoc"
	$self->plugin('PODRenderer');

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get('/')->to('example#welcome');
}

1;
