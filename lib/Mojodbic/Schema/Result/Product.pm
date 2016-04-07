package Mojodbic::Schema::Result::Product;

use DBIx::Class::Candy -autotable => 'singular';

primary_column product_id => { data_type => 'serial', };

column company_id => { data_type => 'integer', };
column name       => { data_type => 'text', };

belongs_to company => 'Mojodbic::Schema::Result::Company', 'company_id';

1;

