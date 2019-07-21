# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Cons;
use parent qw(PLisp::Types::List);

use PLisp::BuiltinValues;
use Carp;

sub new {
    my $class = shift;
    my $car = shift // NIL;
    my $cdr = shift // NIL;

    croak "Invalid type for 1st argument" unless $car->isa("PLisp::Types::T");
    croak "Invalid type for 2st argument" unless $cdr->isa("PLisp::Types::T");

    return bless [ $car, $cdr ], $class;
}

sub car {
    my $self = shift;
    my $val = shift;

    my $old = $self->[0];
    $self->[0] = $val if defined $val;
    return $old;
}

sub cdr {
    my $self = shift;
    my $val = shift;

    my $old = $self->[1];
    $self->[1] = $val if defined $val;
    return $old;
}

sub stringify {
    my $self = shift;

    return "#<CONS ( "
        . $self->car->stringify() . " . " . $self->cdr->stringify()
        . " )>";
}

1;
