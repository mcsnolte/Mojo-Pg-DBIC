package Mojodbic::Schema::Result::Company;

use DBIx::Class::Candy -autotable => 'singular';

primary_column company_id => { data_type => 'serial', };

column name => { data_type => 'text', };

has_many products => 'Mojodbic::Schema::Result::Product', 'company_id';

1;

