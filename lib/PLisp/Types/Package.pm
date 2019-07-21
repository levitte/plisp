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
use PLisp::BuiltinPackages;
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
    } else {
        die 'invalid symbol name ', $name->stringify() unless ref $name eq '';
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

# Perl variant of the IMPORT function
sub do_import {
    my $self = shift;
    my $symbols = shift;
    my %opts = @_;

    my $status =
        $opts{_status} // ($self == P_KEYWORD ? K_EXTERNAL : K_INTERNAL);

    # In case this was called with just one symbol and not a whole array
    if (ref $symbols ne 'ARRAY') {
        $symbols = [ $symbols ];
    }

    foreach (@$symbols) {
        die "not a symbol" unless ref $_ eq 'PLisp::Types::Symbol';

        my $name = $_->name->as_str();
        my $check = $self->{symbols}->{$name};

        die "package-error" if defined $check && $check->[0] != $_;
    }

    foreach (@$symbols) {
        my $name = $_->name->as_str();

        $_->package($self) unless defined $_->package();
        $self->{symbols}->{$name} = [ $_, $status ];
    }

}

sub intern {
    my $self = shift;
    my $name = shift;
    my %opts = @_;

    if (ref $name eq 'PLisp::Types::String') {
        $name = $name->as_str();
    } else {
        die 'invalid symbol name ', $name->stringify() unless ref $name eq '';
    }

    my $check = $self->{symbols}->{$name};

    # If the name is already interned, just return it.
    return @$check if defined $check;

    my $symbol = PLisp::Types::Symbol->new($name);
    $symbol->value($symbol) if $self == P_KEYWORD;
    $self->do_import($symbol, %opts);

    return ( $symbol, NIL );
}

1;
