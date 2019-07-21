# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::BuiltinReadtables;

use Carp;
use Exporter qw(import);

our @EXPORT =qw(READTABLE);

use PLisp::StandardReadtable;

my $READTABLE;
sub READTABLE {
    $READTABLE = STANDARD_READTABLE unless defined $READTABLE;
    $READTABLE;
}

1;
