# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Number;
use parent qw(PLisp::Types::T);

sub print_object {
    my $self = shift;
    my $stream = shift;

    $stream->print($$self);
}

sub stringify {
    my $self = shift;

    my $type = uc ref $self;
    $type =~ s|^PLisp::Types::||i;
    $type =~ s|_|-|g;
    return sprintf "#<%s 0x%p: %s>", $type, refaddr $self, "$$self";
}

1;
