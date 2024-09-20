#!/usr/bin/env bash

[ $# -eq 1 ] || die "usage: test_number"

test_num=$1; shift
test_dir=$(dirname "$(readlink -f $0)")
test_file="$test_dir/test$test_num.d"
ldc="$test_dir"/../../build-ldc/bin/ldc2

outbin=$(mktemp)

cat -n ""$test_file
echo "===================="
echo ""

$ldc -g -O0 $test_file --disable-gc2stack --disable-d-passes --of $outbin
$outbin "--DRT-gcopt=cleanup:collect fork:0 parallel:0 verbose:2"

