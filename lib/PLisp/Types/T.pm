# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::T;

use Class::ISA;
use Carp;

my $defined = 0;
sub new {
    my $class = shift;

    confess "The T object has already been created" if $defined;
    $defined = 1;

    return bless {}, $class;
}

sub typep {
    my $self = shift;
    my $type = uc shift;

    foreach (Class::ISA::self_and_super_path(ref $self)) {
        croak "Dafuq? : $_" unless m|^PLisp::Types::|;

        my $l_type = uc $';
        return 1 if $type eq $l_type;
    }
    return 0;
}

sub format {
    my $self = shift;

    croak "Dunno how to format this...";
}

#sub AUTOLOAD {
#    croak "undefined-method $AUTOLOAD";
#}

1;
