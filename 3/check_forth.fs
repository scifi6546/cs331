\ check_forth.fs
\ Glenn G. Chappell
\ 2020-02-10
\
\ For CS F331 / CSCE A331 Spring 2020
\ A Forth Program to Run
\ Used in Assignment 3, Exercise 1


999 constant end-mark  \ End marker for pushed data


\ push-data
\ Push our data, end-mark first.
: push-data ( -- end-mark <lots of numbers> )
  end-mark
  12 59 swap -73 dup -1 * 3 + 16 -7 18 -83 87
  -6 -69 76 16 2 1 -37 -34 73 dup 10 / -16 dup
  3 * 18 62 16 dup 8 / dup 2 / -37 -34 73 7
  dup 2 * 2 + dup -5 * 76 dup 60 - -7 18 -83
  73 13 5 dup -15 * 81 dup -11 / -61 45 -59
;


\ do-stuff
\ Given a number, do ... whatever operations we are supposed to do.
\ (Pretty mysterious, eh?)
: do-stuff ( end-mark <lots of numbers> -- )
  10 { n }
  begin
    dup end-mark <> while
    n swap - 1
    dup + dup + swap + dup emit to n
  repeat
  drop
;


\ Now do it all: print the secret message
cr
." Secret message #3:" cr cr
push-data do-stuff cr
cr

