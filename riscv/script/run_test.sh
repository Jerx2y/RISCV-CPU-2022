#!/bin/sh
# build testcase
./build_test.sh $@
# copy test input
if [ -f ../testcase/$@.in ]; then cp ../testcase/$@.in ./test/test.in; fi
# copy test output
if [ -f ../testcase/$@.ans ]; then cp ../testcase/$@.ans ./test/test.ans; fi
# add your own test script here
# Example:
# - iverilog/gtkwave/vivado

iverilog -o $(testspace)/test $(sim)/testbench.v $(src)/common/block_ram/*.v $(src)/common/fifo/*.v $(src)/common/uart/*.v $(src)/*.v

diff ./test/test.ans ./test/test.out
