# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

package PLisp::reader;

use Carp;
use Exporter qw(import);

our @EXPORT =qw(reader);

use IO::File;
use PLisp::Types::Bignum;
use PLisp::Types::Ratio;
use PLisp::Types::Cons;
use PLisp::BuiltinKeywords;
use PLisp::BuiltinReadtables;
use PLisp::BuiltinPackages;
use PLisp::BuiltinValues;

BEGIN {
}

my $DOT = PLisp::Types::Symbol->new("<.>");

sub r {
    my $stream = shift;
    my $readtable = shift;
    my $eof_error_p = shift // 1;
    my $eof_value = shift // NIL;
    my $recursive_p = shift // 0;
    my $preserve_ws_p = shift // 0;

    my $x, my $y, my $z, my $type; # Predeclare some variables used below

 again:
    # The algorithm performed by the Lisp reader is as follows:
    #
    # 1. If at end of file, end-of-file processing is performed as
    #    specified in read.  Otherwise, one character, x, is read
    #    from the input stream, and dispatched according to the
    #    syntax type of x to one of steps 2 to 7.
    $x = $stream->getc;
    unless (defined $x) {
	die "end-of-file" if $eof_error_p || $recursive_p;
	return $eof_value;
    }

    $type = $readtable->type($x);

    # 2. If x is an invalid character, an error of type
    #    reader-error is signaled.
    die "reader-error" if $type == PLisp::Types::Readtable->c_invalid;

    # 3. If x is a whitespace[2] character, then it is discarded
    #    and step 1 is re-entered.
    goto again if $type == PLisp::Types::Readtable->c_whitespace;

    # 4. If x is a terminating or non-terminating macro character
    #    then its associated reader macro function is called with
    #    two arguments, the input stream and x.
    #
    #        The reader macro function may read characters from
    #        the input stream; if it does, it will see those
    #        characters following the macro character.  The Lisp
    #        reader may be invoked recursively from the reader
    #        macro function.
    #
    #        The reader macro function must not have any side effects
    #        other than on the input stream; because of backtracking
    #        and restarting of the read operation, front ends to the
    #        Lisp reader (e.g., ``editors'' and ``rubout handlers'')
    #        may cause the reader macro function to be called
    #        repeatedly during the reading of a single expression in
    #        which x only appears once.
    #
    #        The reader macro function may return zero values or one
    #        value.  If one value is returned, then that value is
    #        returned as the result of the read operation; the
    #        algorithm is done.  If zero values are returned, then
    #        step 1 is re-entered.
    if ($type == PLisp::Types::Readtable->c_t_macro_character
	    || $type == PLisp::Types::Readtable->c_nt_macro_character) {
	my @value = ();
	my $data = $readtable->data($x);
	die "Macro character with undefined processor" unless defined $data;
	if (ref $data eq 'CODE') {
	    # Perl function
	    @value = $data->($stream, $x);
	} else {
	    die "Lisp macro character function unsupported";
	}
	goto again if scalar @value == 0;
	return $value[0] if scalar @value == 1;
	die "More than one value from macro character function???";
    }

    my $token = "";
    my $escaped = 0;
    # 5. If x is a single escape character then the next character, y,
    #    is read, or an error of type end-of-file is signaled if at
    #    the end of file.  y is treated as if it is a constituent
    #    whose only constituent trait is alphabetic[2].  y is used to
    #    begin a token, and step 8 is entered.
    if ($type == PLisp::Types::Readtable->c_single_escape) {
	$y = $stream->getc;
	die "end-of-file" unless defined $y;

	$token .= $y;
        $escaped = 1;
	goto accumulate_token;
    }

    # 6. If x is a multiple escape character then a token (initially
    #    containing no characters) is begun and step 9 is entered.
    goto multi_escape if ($type == PLisp::Types::Readtable->c_multiple_escape);

    # 7. If x is a constituent character, then it begins a token.
    #    After the token is read in, it will be interpreted either as
    #    a Lisp object or as being of invalid syntax.  If the token
    #    represents an object, that object is returned as the result
    #    of the read operation.  If the token is of invalid syntax, an
    #    error is signaled.  If x is a character with case, it might
    #    be replaced with the corresponding character of the opposite
    #    case, depending on the readtable case of the current
    #    readtable, as outlined in Section 23.1.2 (Effect of Readtable
    #    Case on the Lisp Reader).  X is used to begin a token, and
    #    step 8 is entered.
    if ($type == PLisp::Types::Readtable->c_constituent) {
	$token .= $readtable->normalize($x);
	goto accumulate_token;
    }
    die "Unexpected character type $type";

 accumulate_token:
    # 8. At this point a token is being accumulated, and an even
    #    number of multiple escape characters have been encountered.
    #    If at end of file, step 10 is entered. Otherwise, a
    #    character, y, is read, and one of the following actions is
    #    performed according to its syntax type:
    $y = $stream->getc;
    goto end unless defined $y;
    $type = $readtable->type($y);

    #     * If y is a constituent or non-terminating macro character:
    #
    #         -- If y is a character with case, it might be replaced
    #            with the corresponding character of the opposite
    #            case, depending on the readtable case of the current
    #            readtable, as outlined in Section 23.1.2 (Effect of
    #            Readtable Case on the Lisp Reader).
    #         -- Y is appended to the token being built.
    #         -- Step 8 is repeated.
    if ($type == PLisp::Types::Readtable->c_constituent
	    || $type == PLisp::Types::Readtable->c_nt_macro_character) {
	$token .= $readtable->normalize($y);
	goto accumulate_token;
    }

    #     * If y is a single escape character, then the next
    #       character, z, is read, or an error of type end-of-file is
    #       signaled if at end of file.  Z is treated as if it is a
    #       constituent whose only constituent trait is alphabetic[2].
    #       Z is appended to the token being built, and step 8 is
    #       repeated.
    if ($type == PLisp::Types::Readtable->c_single_escape) {
	$z = $stream->getc;
	die "end-of-file" unless defined $z;
	$token .= $z;
        $escaped = 1;
	goto accumulate_token;
    }

    #     * If y is a multiple escape character, then step 9 is
    #       entered.
    goto multi_escape if ($type == PLisp::Types::Readtable->c_multiple_escape);

    #     * If y is an invalid character, an error of type
    #       reader-error is signaled.
    die "reader-error" if ($type == PLisp::Types::Readtable->c_invalid);

    #     * If y is a terminating macro character, then it terminates
    #       the token.  First the character y is unread (see
    #       unread-char), and then step 10 is entered.
    if ($type == PLisp::Types::Readtable->c_t_macro_character) {
	$stream->ungetc(ord($y));
	goto end;
    }

    #     * If y is a whitespace[2] character, then it terminates the
    #     token.  First the character y is unread if appropriate (see
    #     read-preserving-whitespace), and then step 10 is entered.
    if ($type == PLisp::Types::Readtable->c_whitespace) {
	$stream->ungetc(ord($y)) if $preserve_ws_p;
	goto end;
    }

 multi_escape:
    # 9. At this point a token is being accumulated, and an odd number
    #    of multiple escape characters have been encountered.  If at
    #    end of file, an error of type end-of-file is signaled.
    #    Otherwise, a character, y, is read, and one of the following
    #    actions is performed according to its syntax type:
    $y = $stream->getc;
    die "end-of-gile" unless defined $y;
    $type = $readtable->type($y);
    $escaped = 1;

    #     * If y is a constituent, macro, or whitespace[2] character,
    #       y is treated as a constituent whose only constituent trait
    #       is alphabetic[2].  Y is appended to the token being built,
    #       and step 9 is repeated.
    if ($type == PLisp::Types::Readtable->c_constituent
	    || $type == PLisp::Types::Readtable->c_t_macro_character
	    || $type == PLisp::Types::Readtable->c_nt_macro_character
	    || $type == PLisp::Types::Readtable->c_whitespace) {
	$token .= $y;
	goto multi_escape;
    }

    #     * If y is a single escape character, then the next
    #       character, z, is read, or an error of type end-of-file is
    #       signaled if at end of file.  Z is treated as a constituent
    #       whose only constituent trait is alphabetic[2].  Z is
    #       appended to the token being built, and step 9 is repeated.
    if ($type == PLisp::Types::Readtable->c_single_escape) {
	$z = $stream->getc;
	die "end-of-file" unless defined $z;
	$token .= $z;
	goto accumulate_token;
    }

    #     * If y is a multiple escape character, then step 8 is
    #       entered.
    goto accumulate_token
	if ($type == PLisp::Types::Readtable->c_multiple_escape);

    #     * If y is an invalid character, an error of type
    #       reader-error is signaled.
    die "reader-error";		# Can only be invalid at this point

 end:
    # 10. An entire token has been accumulated.  The object
    #     represented by the token is returned as the result of the
    #     read operation, or an error of type reader-error is signaled
    #     if the token is not of valid syntax.

    unless ($escaped) {
	# numeric-token  ::=  integer |
	#                     ratio   |
	#                     float
	#
	# integer        ::=  [sign] decimal-digit+ decimal-point |
	#                     [sign] digit+
	#
	# ratio          ::=  [sign] {digit}+ slash {digit}+
	#
	# float          ::=  [sign]
	#   (  {decimal-digit}* decimal-point {decimal-digit}+ [exponent]
	#    | {decimal-digit}+ [decimal-point {decimal-digit}*] exponent )
	#
	# exponent       ::=  exponent-marker [sign] {digit}+
	if ($token =~ m/^([-+]?[0-9]+)\.?$/) {
	    my $object = PLisp::Types::Bignum->new($1);
	    return $object;
	} elsif ($token =~ m/^[-+]?[0-9]+\/[0-9]+$/) {
	    my $object = PLisp::Types::Ratio->new($token);
	    return $object;
	} elsif ($token =~
		     m/^([-+])?
		       ((?:[0-9]*)\.(?:[0-9]+)(?:[DdEeFfLlSs][-+]?[0-9]+)?
		       |(?:[0-9]+)(?:\.[0-9]+)?[DdEeFfLlSs][-+]?[0-9]+)
		       $/x) {
	    die "Reals currently unsupported";
	} elsif ($token eq '.') {
            return $DOT;
        }
    }

    my $package = PACKAGE;
    my $object;
    my $wanted_status = K_EXTERNAL;

    # Detect symbols that are internal in packages
    if ($token =~ m|::|) {
        die "Invalid token \"$token\"\n" if $` eq '#';
        $token = $';
        # We allow a prefixing '::' to mean the current package
        $package = find_package($`) if $` ne '';
        $wanted_status = K_INTERNAL;
    } elsif ($token =~ m|:|) {
        $token = $';
        if ($` eq '#') {
            $package = undef;
        } elsif ($` eq '') {
            $package = P_KEYWORD;
        } else {
            $package = find_package($`);
        }
    }

    if (defined $package) {
        ($object, my $status) = $package->find_symbol($token);
        if ($object == NIL) {
            ($object, $status) =
                $package->intern($token, _status => $wanted_status);
            $object->value($object) if $package == P_KEYWORD;
        }
    } else {
        $object = PLisp::Types::Symbol->new($token);
    }
    return $object;
}

sub read_delimited_list {
    my $char = shift;
    my $stream = shift;
    my $readtable = shift;
    my $recursive_p = shift // 0;

    my $list = NIL;
    my $tail;
    my $dotted = 0;

    while (1) {
	my $x = $stream->getc;
	die "end-of-file" unless defined $x && $recursive_p;
	return $list unless defined $x;
	my $type = $readtable->type($x);
	next if $type == PLisp::Types::Readtable->c_whitespace;
	return $list if $x eq $char;
	$stream->ungetc(ord($x));
	my $object = r($stream, $readtable, undef, undef, $recursive_p);
        if ($object == $DOT) {
            die "invalid-dotted-list" unless defined $tail;
            $dotted = 1;
        } else {
            die "invalid-dotted-list" if $dotted > 1;
            $dotted++ if $dotted > 0;
            $object = PLisp::Types::Cons->new($object, NIL) if $dotted == 0;

            if (defined $tail) {
                $tail->cdr($object);
                $tail = $object;
            } else {
                $list = $tail = $object;
            }
	}
    }
}

1;
