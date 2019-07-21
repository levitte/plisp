# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Readtable;
use parent qw(PLisp::Types::T);

use Carp;

sub new {
    my $class = shift;
    my $copyfrom = shift;

    # character => [ type, dataref ]
    my $data = { };
    $data = { %{$copyfrom} } if defined $copyfrom;

    return bless $data, $class;
}

use constant {
    c_constituent               => 1,
    c_invalid                   => 2,
    c_t_macro_character         => 3,
    c_nt_macro_character        => 4,
    c_multiple_escape           => 5,
    c_single_escape             => 6,
    c_whitespace                => 7,
};

# Returns one of the constants
sub type {
    my $self = shift;
    my $char = shift;

    return c_invalid unless defined $char and defined $self->{$char};
    return $self->{$char}->[0];
}

sub data {
    my $self = shift;
    my $char = shift;
    my $type = $self->type($char);

    return undef if $type == c_invalid;
    return $self->{$char}->[1];
}

sub set_macro {
    my $self = shift;
    my $char = shift;
    my $macro = shift;
    my $term_flag = shift;

    $self->{$char} = [ $term_flag ? c_t_macro_character : c_nt_macro_character,
                       $macro ];
}

sub set_type {
    my $self = shift;
    my $char = shift;
    my $type = shift;

    croak "Invalid type"
        if $type == c_t_macro_character || $type == c_nt_macro_character;
    $self->{$char} = [ $type ];
}

sub normalize {
    my $self = shift;
    my $char = shift;

    return uc $char;
}

1;
