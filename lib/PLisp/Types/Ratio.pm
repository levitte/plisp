# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Ratio;
use parent qw(PLisp::Types::Rational);

use Math::BigRat try => 'GMP';

sub new {
    my $class = shift;
    my $number = Math::BigRat->new(shift);

    return bless \$number, $class;
}

sub format {
    my $self = shift;

    return join('/', "$$self->parts");
}
1;
