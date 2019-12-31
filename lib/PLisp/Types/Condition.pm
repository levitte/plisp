# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Condition;
use parent qw(PLisp::Types::T);

use Scalar::Util qw(refaddr);

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub print_object {
    my $self = shift;
    my $stream = shift;

    return $stream->print($self->stringify());
}

1;
