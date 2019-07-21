# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::evaluator;

use Carp;
use Exporter qw(import);

our @EXPORT =qw();

use PLisp::BuiltinValues;
use PLisp::Types::Environment;

BEGIN {
    my $dynamicenv = PLisp::Types::Environment->new();
}

my %subevaluators = (
    # Common Lisp special forms
    BLOCK                       => undef,
    CATCH                       => undef,
    'EVAL-WHEN'                 => undef,
    FLET                        => undef,
    FUNCTION                    => undef,
    GO                          => undef,
    IF                          => undef,
    LABELS                      => undef,
    LET                         => undef,
    'LET*'                      => undef,
    'LOAD-TIME-VALUE'           => undef,
    LOCALLY                     => undef,
    MACROLET                    => undef,
    'MULTIPLE-VALUE-CALL'       => undef,
    'MULTIPLE-VALUE-PROG1'      => undef,
    PROGN                       => undef,
    PROGV                       => undef,
    QUOTE                       => sub { return _one($_[0]); },
    'RETURN-FROM'               => undef,
    SETQ                        => sub {
        my $form = shift;
        my $lexenv = shift;
        my $lastval = NIL;

        while ($form->typep('cons') && $form->cdr->typep('cons')) {
            my $symbol = $form->car;
            my $value = $form->cdr->car;
            $form = $form->cdr->cdr;

            die "not-a-symbol" unless $symbol->typep('symbol');

            $lastval = e($value, $lexenv);
            my $symbolname = ${$symbol->name};
            if ($lexenv->vbound($symbolname)) {
                $lexenv->vbind($symbolname, $lastval);
            } else {
                $symbol->value($lastval);
            }
        }

        return $lastval if $form->typep('null');
        die "dotted-list" unless $form->typep('cons');
        die "extra-arguments";
    },
    'SYMBOL-MACROLET'           => undef,
    TAGBODY                     => undef,
    THE                         => undef,
    THROW                       => undef,
    'UNWIND-PROTECT'            => undef,

    # Accessors
    CAR         => sub { return e(_one($_[0]), $_[1])->car },
    CDR         => sub { return e(_one($_[0]), $_[1])->cdr },
    CAAR        => sub { return e(_one($_[0]), $_[1])->car->car },
    CADR        => sub { return e(_one($_[0]), $_[1])->cdr->car },
    CDAR        => sub { return e(_one($_[0]), $_[1])->car->cdr },
    CDDR        => sub { return e(_one($_[0]), $_[1])->cdr->cdr },
    CAAAR       => sub { return e(_one($_[0]), $_[1])->car->car->car },
    CAADR       => sub { return e(_one($_[0]), $_[1])->cdr->car->car },
    CADAR       => sub { return e(_one($_[0]), $_[1])->car->cdr->car },
    CADDR       => sub { return e(_one($_[0]), $_[1])->cdr->cdr->car },
    CDAAR       => sub { return e(_one($_[0]), $_[1])->car->car->cdr },
    CDADR       => sub { return e(_one($_[0]), $_[1])->cdr->car->cdr },
    CDDAR       => sub { return e(_one($_[0]), $_[1])->car->cdr->cdr },
    CDDDR       => sub { return e(_one($_[0]), $_[1])->cdr->cdr->cdr },
    CAAAAR      => sub { return e(_one($_[0]), $_[1])->car->car->car->car },
    CAAADR      => sub { return e(_one($_[0]), $_[1])->cdr->car->car->car },
    CAADAR      => sub { return e(_one($_[0]), $_[1])->car->cdr->car->car },
    CAADDR      => sub { return e(_one($_[0]), $_[1])->cdr->cdr->car->car },
    CADAAR      => sub { return e(_one($_[0]), $_[1])->car->car->cdr->car },
    CADADR      => sub { return e(_one($_[0]), $_[1])->cdr->car->cdr->car },
    CADDAR      => sub { return e(_one($_[0]), $_[1])->car->cdr->cdr->car },
    CADDDR      => sub { return e(_one($_[0]), $_[1])->cdr->cdr->cdr->car },
    CDAAAR      => sub { return e(_one($_[0]), $_[1])->car->car->car->cdr },
    CDAADR      => sub { return e(_one($_[0]), $_[1])->cdr->car->car->cdr },
    CDADAR      => sub { return e(_one($_[0]), $_[1])->car->cdr->car->cdr },
    CDADDR      => sub { return e(_one($_[0]), $_[1])->cdr->cdr->car->cdr },
    CDDAAR      => sub { return e(_one($_[0]), $_[1])->car->car->cdr->cdr },
    CDDADR      => sub { return e(_one($_[0]), $_[1])->cdr->car->cdr->cdr },
    CDDDAR      => sub { return e(_one($_[0]), $_[1])->car->cdr->cdr->cdr },
    CDDDDR      => sub { return e(_one($_[0]), $_[1])->cdr->cdr->cdr->cdr },
    );

sub _one {
    my $form = shift;

    croak "Too many arguments" if @_;

    die "invalid-form" unless $form->typep('cons');
    die "too-many-arguments" unless $form->cdr->typep('null');
    return $form->car;
}

sub e {
    my $form = shift;
    my $lexenv = shift;

    # Evaluate a list
    if ($form->typep('cons')) {
        my $first = $form->car;

        if ($first->typep('symbol')) {
            my $firstname = ${$first->name};
            my $uc_firstname = uc $firstname;

            if (exists $subevaluators{$uc_firstname}) {
                croak "$firstname not yet implemented"
                    unless defined $subevaluators{$uc_firstname};
                return $subevaluators{$uc_firstname}->($form->cdr, $lexenv);
            } else {
                croak "Function evaluation not yet implemented";
            }
        }
        croak "List?????"
    }

    # Evaluate a symbol
    if ($form->typep('symbol')) {
        my $value =  $lexenv->valueof(${$form->name}) // $form->value;

        die "unbound-variable" unless defined $value;

        return $value;
    }

    # Self-evaluated objects
    return $form;
}

1;
