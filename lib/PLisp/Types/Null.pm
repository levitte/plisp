# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Null;
use parent qw(PLisp::Types::List);

use Carp;

my $defined = 0;
sub new {
    my $class = shift;

    confess "The NIL object has already been created" if $defined;
    $defined = 1;

    return bless {}, $class;
}

1;
