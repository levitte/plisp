# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Package;
use parent qw(PLisp::Types::T);

use PLisp::Types::Symbol;
use PLisp::BuiltinValues;
use PLisp::BuiltinKeywords;
use Carp;

sub new {
    my $class = shift;
    my $name = shift;
    my %opts = @_;

    croak "undefined-package-name" unless defined $name;

    my $data = {
        name      => PLisp::Types::String->new($name), # Package name
        nicknames => $opts{nicknames} // [],           # Nicknames
        use       => $opts{use} // [],                 # Inherited packages
        symbols   => {},                               # The symbol hash table
    };

    return bless $data, $class;
}

sub name {
    my $self = shift;

    return $self->{name};
}

sub find_symbol {
    my $self = shift;
    my $name = shift;

    if (ref $name eq 'PLisp::Types::String') {
        $name = $name->as_str();
    }

    my $check = $self->{symbols}->{$name};

    return @$check if defined $check;

    foreach (@{$self->{use}}) {
        my @symbol = $_->find_symbol($name);
        next if $symbol[0] == NIL || $symbol[1] == K_INTERNAL;

        return ( $symbol[0], K_INHERITED );
    }

    return ( NIL, NIL );
}

sub intern {
    my $self = shift;
    my $name = shift;
    my %opts = @_;

    if (ref $name eq 'PLisp::Types::String') {
        $name = $name->as_str();
    }

    my $check = $self->{symbols}->{$name};

    return @$check if defined $check;

    my $symbol = PLisp::Types::Symbol->new($name, package => $self);
    $self->{symbols}->{$name} = [ $symbol, $opts{_status} // K_INTERNAL ];

    return ( $symbol, NIL );
}

1;
