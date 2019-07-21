# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Symbol;
use parent qw(PLisp::Types::T);

use PLisp::BuiltinValues;
use PLisp::Types::String;
use Carp;

sub new {
    my $class = shift;
    my $name = shift;
    my %opts = @_;

    my $data = [
        PLisp::Types::String->new($name), # Lisp symbol name
        $opts{package},                   # Package
        NIL,                              # Property list
        $opts{value},                     # Value binding
        $opts{function},                  # Function binding
    ];

    return bless $data, $class;
}

sub name {
    my $self = shift;

    return $self->[0];
}

sub package {
    my $self = shift;

    return $self->[1];
}

sub plist {
    my $self = shift;
    my $plist = shift;

    return $self->[2] unless defined $plist;
    return $self->[2] = $plist;
}

sub value {
    my $self = shift;
    my $value = shift;

    return $self->[3] unless defined $value;
    return $self->[3] = $value;
}

sub function {
    my $self = shift;
    my $function = shift;

    return $self->[4] unless defined $function;
    return $self->[4] = $function;
}

sub format {
    my $self = shift;

    return $self->name->format;
}

1;
