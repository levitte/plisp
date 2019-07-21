# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::BuiltinValues;

use Carp;
use Exporter qw(import);

our @EXPORT = qw(T NIL);


use PLisp::Types::T;
use PLisp::Types::Null;

# The T object
my $T;
sub T {
    $T = PLisp::Types::T->new() unless defined $T;
    return $T;
}

# The NIL object
my $NIL;
sub NIL {
    $NIL = PLisp::Types::Null->new() unless defined $NIL;
    return $NIL;
}

1;
