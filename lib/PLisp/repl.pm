# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::repl;		# Read-Eval-Print Loop

use Carp;
use Exporter qw(import);

our @EXPORT =qw(repl);

use IO::Handle;

use PLisp;
use PLisp::reader;
use PLisp::BuiltinReadtables;
use PLisp::evaluator;
use PLisp::printer;

sub repl {
    $| = 1;

    my $istream = IO::Handle->new_from_fd(fileno(STDIN), 'r');
    my $ostream = IO::Handle->new_from_fd(fileno(STDOUT), 'w');
    my $estream = IO::Handle->new_from_fd(fileno(STDERR), 'w');

    while(1) {
        $ostream->print('>>> ');
        $ostream->flush;
        my $form = eval { PLisp::reader::r($istream, READTABLE); };
        my $object =
            (defined $form
             ? eval { PLisp::evaluator::e($form,
                                          PLisp::Types::Environment->new()); }
             : undef);

        if (defined $object) {
            $ostream->print('=> ');
            PLisp::printer::p($ostream, $object);
            $ostream->print("\n");
        } else {
            if (ref($@) ne '' && $@->typep('end-of-file')) {
                $@->print_object($estream) if $ENV{PLISP_DEBUG};
                $estream->print("\n");

                if ($ENV{PLISP_DEBUG}) {
                    print STDERR "DEBUG[", __PACKAGE__, "::repl]",
                        " condition is ", $@->stringify(), "\n";
                }

                $estream->flush;
                last;
            }

            $estream->print('### ');
            if (ref($@) eq '') {
                $estream->print('Perl error: ', $@);
            } else {
                $@->print_object($estream);
            }
            $estream->print("\n");
            $estream->flush;
        }
    }
    $ostream->flush;
}
