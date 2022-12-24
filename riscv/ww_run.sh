rm -f test/*
cp testcase/sim/$1.c test/test.c
script/build_test.sh
make build_sim
cd test
time ./test # > test.ans
