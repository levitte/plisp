# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::BuiltinPackages;

use Carp;
use Exporter qw(import);

BEGIN {
    our @EXPORT =qw(P_KEYWORD P_COMMON_LISP P_COMMON_LISP_USER PACKAGE
                    make_package find_package);
}

use PLisp::Types::Symbol;
use PLisp::Types::Bignum;
use PLisp::Types::Package;
use PLisp::BuiltinValues;
use PLisp::BuiltinKeywords;

use List::Util qw( pairs );

my %packages = ();

# Perl only
sub populate_package {
    my $package = shift;
    my @pairs = @{ shift() };
    my %opts = @_;

    foreach my $pair (pairs @pairs) {
        my ($key, $value) = @$pair;

        croak "Initial value not defined for $key" unless defined $value;

        my @sym = $package->intern($key, %opts);
        $sym[0]->value($value) if defined $value;
    }
}

# Lisp MAKE-PACKAGE with perly options
sub make_package {
    my $name = shift;
    my %opts = @_;

    if (defined $packages{$name}) {
        die "Package $name already exists" unless $opts{_return_defined};
    } else {
        my $package = PLisp::Types::Package->new($name, %opts);

        $packages{$name} = $package;
        if (defined $opts{_init}) {
            populate_package($package, [ $opts{_init}->() ], %opts);
        }
    }
    return $packages{$name};
}

# Lisp FIND-PACKAGE
sub find_package {
    my $name = shift;

    return $packages{$name};
}

sub P_KEYWORD {
    my $init = sub {
        # The map allows us to have the K_ names directly in an array without
        # them becoming barewords.
        return map { $_ => undef } (
            # The following keywords are used all other the place, so they
            # are the few pre-defined ones.  They already have themselves as
            # value, so no value need to be added.
            K_UPCASE,
            K_INTERNAL,
            K_EXTERNAL,
            K_INHERITED,
            );
    };
    return make_package('KEYWORD', _return_defined => 1, _init => $init,
                        _status => K_EXTERNAL);
}

sub P_COMMON_LISP {
    my $init = sub {
        return (
            'T'                     => T,
            'NIL'                   => NIL,
            '*PRINT-READABLY*'      => NIL,
            '*PRINT-ESCAPE*'        => T,
            '*PRINT-PRETTY*'        => NIL,
            '*PRINT-LENGTH*'        => NIL,
            '*PRINT-LEVEL*'         => NIL,
            '*PRINT-CIRCLE*'        => NIL,
            '*PRINT-BASE*'          => PLisp::Types::Bignum->new(10),
            '*PRINT-RADIX*'         => NIL,
            '*PRINT-CASE*'          => K_UPCASE,
            '*PRINT-GENSYM*'        => T,
            '*PRINT-ARRAY*'         => NIL,
            '*PACKAGE*'             => P_COMMON_LISP_USER,
            );
    };
    return make_package('COMMON-LISP', nicknames => [ 'CL' ],
                        _return_defined => 1, _init => $init,
                        _status => K_EXTERNAL);
}

sub P_COMMON_LISP_USER {
    return make_package('COMMON-LISP-USER', _return_defined => 1,
                        nicknames => [ 'CL-USER' ], use => [ P_COMMON_LISP ]);
}

my $PACKAGE;
sub PACKAGE {
    my ($object, $status) = P_COMMON_LISP->find_symbol('*PACKAGE*');
    confess "\$object is NIL?????" if $object == NIL;
    return $object->value();
}

1;
