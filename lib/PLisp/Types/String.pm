# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

# Currently cutting short compared to the Common Lisp type tree
package PLisp::Types::String;
use parent qw(PLisp::Types::T);

use Carp;

sub new {
    my $class = shift;
    my $string = shift;

    croak "Invalid string" unless defined $string;

    return bless \$string, $class;
}

sub print_object {
    my $self = shift;
    my $stream = shift;

    $stream->print($$self);
}

# Get a perl string
sub as_str {
    my $self = shift;

    return $$self;
}

1;
