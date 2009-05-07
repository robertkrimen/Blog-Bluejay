package Blog::Jive::Journal::Schema;

use strict;
use warnings;

use base qw/DBIx::Class::Schema Class::Accessor::Fast/;
our $schema = __PACKAGE__;

__PACKAGE__->mk_accessors(qw/journal/);
__PACKAGE__->load_namespaces;

package Blog::Jive::Journal::Schema::Result::Post;

use strict;
use warnings;

use base qw/DBIx::Class/;

use JSON;

__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);
__PACKAGE__->table('post');
__PACKAGE__->add_columns(
    qw/ id uuid folder title abstract /,
    qw/ creation modification /,
);
#__PACKAGE__->add_columns(creation => { data_type => 'datetime' }, modification => { data_type => 'datetime' });
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( uuid => [qw/ uuid /]);

$schema->register_class(substr(__PACKAGE__, 10 + length $schema) => __PACKAGE__);

1;
