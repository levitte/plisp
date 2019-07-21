# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::StandardReadtable;

use Carp;
use Exporter qw(import);

our @EXPORT = qw(STANDARD_READTABLE);

use PLisp::Types::Readtable;
use PLisp::BuiltinPackages;
use PLisp::BuiltinValues;

# Forward declaration
sub STANDARD_READTABLE;

sub process_string {
    my $stream = shift;
    my $x = shift;

    my $string = "";
    while (1) {
        my $char = $stream->getc;
        die "end-of-file" unless defined $char;
        my $type = STANDARD_READTABLE->type($char);
        if ($type == PLisp::Types::Readtable->c_single_escape) {
            $char = $stream->getc;
            die "end-of-file" unless defined $char;
        } elsif ($char eq $x) {
            last;
        }
        $string .= $char;
    }
    return ( PLisp::Types::String->new($string) );
}

(my $QUOTE, $_) = P_COMMON_LISP()->intern('QUOTE');
sub process_quote {
    my $stream = shift;
    my $x = shift;
    my $object = PLisp::reader::r($stream, STANDARD_READTABLE);
    return ( PLisp::Types::Cons->new($QUOTE,
                                     PLisp::Types::Cons->new($object)) );
}

sub process_left_paren {
    my $stream = shift;
    my $x = shift;

    my @object =
        ( PLisp::reader::read_delimited_list(")", $stream,
                                             STANDARD_READTABLE, 1) );
}

sub process_right_paren {
    die "Misplaced )";
}

sub process_comma {
    die "Unsupported comma macro";
}

sub process_semi {
    my $stream = shift;
    my $x = shift;

    PLisp::reader::read_delimited_list("\n", $stream, STANDARD_READTABLE, 1);
    return ();
}

sub process_backquote {
    die "Unsupported backquote macro";
}

my $STANDARD_READTABLE;
sub STANDARD_READTABLE {
    unless (defined $STANDARD_READTABLE) {
        use Data::Dumper;

        $STANDARD_READTABLE = PLisp::Types::Readtable->new();
        my $c_constituent = PLisp::Types::Readtable->c_constituent;
        my $c_invalid = PLisp::Types::Readtable->c_invalid;
        my $c_t_macro_character = PLisp::Types::Readtable->c_t_macro_character;
        my $c_nt_macro_character = PLisp::Types::Readtable->c_nt_macro_character;
        my $c_multiple_escape = PLisp::Types::Readtable->c_multiple_escape;
        my $c_single_escape = PLisp::Types::Readtable->c_single_escape;
        my $c_whitespace = PLisp::Types::Readtable->c_whitespace;

        # From the HyperSpec:
        #
        # character  syntax type                 character  syntax type             
        # Backspace  constituent                 0--9       constituent             
        # Tab        whitespace[2]               :          constituent             
        # Newline    whitespace[2]               ;          terminating macro char  
        # Linefeed   whitespace[2]               <          constituent             
        # Page       whitespace[2]               =          constituent             
        # Return     whitespace[2]               >          constituent             
        # Space      whitespace[2]               ?          constituent*            
        # !          constituent*                @          constituent             
        # "          terminating macro char      A--Z       constituent             
        # #          non-terminating macro char  [          constituent*            
        # $          constituent                 \          single escape           
        # %          constituent                 ]          constituent*            
        # &          constituent                 ^          constituent             
        # '          terminating macro char      _          constituent             
        # (          terminating macro char      `          terminating macro char  
        # )          terminating macro char      a--z       constituent             
        # *          constituent                 {          constituent*            
        # +          constituent                 |          multiple escape         
        # ,          terminating macro char      }          constituent*            
        # -          constituent                 ~          constituent             
        # .          constituent                 Rubout     constituent             
        # /          constituent                 

        $STANDARD_READTABLE->set_type("\b", $c_constituent);
        foreach (split '', "\t\r\n\f ") {
            $STANDARD_READTABLE->set_type($_, $c_whitespace);
        }
        $STANDARD_READTABLE->set_type("!", $c_constituent);
        $STANDARD_READTABLE->set_macro("\"", \&process_string, 1);
        $STANDARD_READTABLE->set_macro("#", undef, 0); # Ignored for now
        $STANDARD_READTABLE->set_type("\$", $c_constituent);
        $STANDARD_READTABLE->set_type("%", $c_constituent);
        $STANDARD_READTABLE->set_macro("'", \&process_quote, 1);
        $STANDARD_READTABLE->set_macro("(", \&process_left_paren, 1);
        $STANDARD_READTABLE->set_macro(")", \&process_right_paren, 1);
        $STANDARD_READTABLE->set_type("*", $c_constituent);
        $STANDARD_READTABLE->set_type("+", $c_constituent);
        $STANDARD_READTABLE->set_macro(",", \&process_comma, 1);
        $STANDARD_READTABLE->set_type("-", $c_constituent);
        $STANDARD_READTABLE->set_type(".", $c_constituent);
        $STANDARD_READTABLE->set_type("/", $c_constituent);
        foreach (0..9) {
            $STANDARD_READTABLE->set_type("$_", $c_constituent);
        }
        $STANDARD_READTABLE->set_type(":", $c_constituent);
        $STANDARD_READTABLE->set_macro(";", \&process_semi, 1);
        $STANDARD_READTABLE->set_type("<", $c_constituent);
        $STANDARD_READTABLE->set_type("=", $c_constituent);
        $STANDARD_READTABLE->set_type(">", $c_constituent);
        $STANDARD_READTABLE->set_type("?", $c_constituent);
        $STANDARD_READTABLE->set_type("@", $c_constituent);
        foreach ('A'..'Z') {
            $STANDARD_READTABLE->set_type("$_", $c_constituent);
        }
        $STANDARD_READTABLE->set_type("[", $c_constituent);
        $STANDARD_READTABLE->set_type("\\", $c_single_escape);
        $STANDARD_READTABLE->set_type("]", $c_constituent);
        $STANDARD_READTABLE->set_type("^", $c_constituent);
        $STANDARD_READTABLE->set_type("_", $c_constituent);
        $STANDARD_READTABLE->set_macro("\`", \&process_backquote, 1);
        foreach ('a'..'z') {
            $STANDARD_READTABLE->set_type("$_", $c_constituent);
        }
        $STANDARD_READTABLE->set_type("{", $c_constituent);
        $STANDARD_READTABLE->set_type("|", $c_multiple_escape);
        $STANDARD_READTABLE->set_type("}", $c_constituent);
        $STANDARD_READTABLE->set_type("~", $c_constituent);

        print Dumper(\$STANDARD_READTABLE) if $ENV{PLISP_DEBUG};
    }
    $STANDARD_READTABLE;
}

1;
