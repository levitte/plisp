# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

# These keywords are defined as free symbols prior to being interned into
# the KEYWORDS package for bootstrapping reasons; they are used before they
# are interned.  They get interned when the built in packages are constructed.

use strict;
use warnings;

package PLisp::BuiltinKeywords;

use Carp;
use Exporter qw(import);

our @EXPORT =qw(K_UPCASE K_INTERNAL K_EXTERNAL K_INHERITED);

use PLisp::Types::Symbol;

my $K_UPCASE;
my $K_INTERNAL;
my $K_EXTERNAL;
my $K_INHERITED;

sub mk_keywords {
    my %init_keywords = (
        'UPCASE' => \$K_UPCASE,
        'INTERNAL' => \$K_INTERNAL,
        'EXTERNAL' => \$K_EXTERNAL,
        'INHERITED' => \$K_INHERITED,
        );
    foreach (keys %init_keywords) {
        ${$init_keywords{$_}} = PLisp::Types::Symbol->new($_);
        ${$init_keywords{$_}}->value(${$init_keywords{$_}});
    }
}

sub K_UPCASE {
    return $K_UPCASE if defined $K_UPCASE;

    mk_keywords();

    return $K_UPCASE;
}

sub K_INTERNAL {
    return $K_INTERNAL if defined $K_INTERNAL;

    mk_keywords();

    return $K_INTERNAL;
}

sub K_EXTERNAL {
    return $K_EXTERNAL if defined $K_EXTERNAL;

    mk_keywords();

    return $K_EXTERNAL;
}

sub K_INHERITED {
    return $K_INHERITED if defined $K_INHERITED;

    mk_keywords();

    return $K_INHERITED;
}

1;
