# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::printer;

use Carp;
use Exporter qw(import);

our @EXPORT =qw();

use IO::File;

sub p {
    my $stream = shift;
    my $object = shift;

    if ($object->typep('cons')) {
        # Print list

        my $walker = $object;
        my $first = 1;

        $stream->print("(");
        while ($walker->typep('cons')) {
            $stream->print(" ") unless $first;
            $first = 0;
            p($stream, $walker->car);
            $walker = $walker->cdr;
        }
        unless ($walker->typep('null')) {
            die "?????" if $first;
            $stream->print(" . ");
            p($stream, $walker);
        }
        $stream->print(")");
        return;
    } else {
        # Print atom

        $object->print_object($stream);
    }
}

1;
