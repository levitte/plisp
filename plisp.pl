# Copyright (c) 2019, Richard Levitte
# All rights reserved.
#
# Licensed under the BSD 2-Clause License (the "License").
# You can obtain a copy in the file LICENSE in the source distribution.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use PLisp;
use PLisp::repl;

repl();
