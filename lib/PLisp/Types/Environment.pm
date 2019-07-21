# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::Types::Environment;
use parent qw(PLisp::Types::T);

use Carp;

use PLisp;

sub new {
    my $class = shift;
    my $parent = shift;

    return bless { parent => $parent }, $class;
}

sub vbound {
    my $self = shift;
    my $name = shift;

    return 1 if exists $self->{vbindings}->{$name};
    return $self->{parent}->vbound($name) if defined $self->{parent};
    return 0;
}

sub vbind {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    croak "Too many arguments" if $@;

    $self->{vbindings}->{$name} = $value;
}

sub valueof {
    my $self = shift;
    my $name = shift;

    croak "Too many arguments" if $@;

    return $self->{vbindings}->{$name} if $self->vbound($name);
    return $self->{parent}->valueof($name) if defined $self->{parent};
    return undef;
}

sub fbound {
    my $self = shift;
    my $name = shift;

    return 1 if exists $self->{fbindings}->{$name};
    return $self->{parent}->fbound($name) if defined $self->{parent};
    return 0;
}

sub fbind {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    croak "Too many arguments" if $@;

    $self->{fbindings}->{$name} = $value;
}

sub functionof {
    my $self = shift;
    my $name = shift;

    croak "Too many arguments" if $@;

    return $self->{fbindings}->{$name} if $self->fbound($name);
    return $self->{parent}->functionof($name) if defined $self->{parent};
    return undef;
}

1;
