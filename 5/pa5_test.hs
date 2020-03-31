-- pa5_test.hs
-- Glenn G. Chappell
-- 2020-03-26
--
-- For CS F331 / CSCE A331 Spring 2020
-- Test Program for Assignment 5 Functions & Variables
-- Used in Assignment 5, Exercise B

module Main where

import qualified PA5  -- For Assignment 5 Functions & Variables


------------------------------------------------------------------------
-- Testing Package
------------------------------------------------------------------------


-- TestState a
-- Data type for holding results of tests
-- First item in pair is a Maybe giving pass/fail results so far:
--     Just _   means all passed so far
--     Nothing  means at least one failure so far
-- Second item in pair is IO for output of tests
data TestState a = TS (Maybe a, IO a)

-- Accessor functions for parts of a TestState value
tsMaybe (TS (x, y)) = x
tsIO (TS (x, y)) = y

-- Make TestState a Functor in the obvious way
instance Functor TestState where
    fmap f (TS (a, b)) = TS (fmap f a, fmap f b)

-- Make TestState an Applicative in the obvious way
instance Applicative TestState where
    pure a = TS (pure a, pure a)
    TS (f, g) <*> TS (x, y) = TS (f <*> x, g <*> y)

-- Make TestState a Monad in the obvious way
instance Monad TestState where
    return = pure
    TS (x, y) >>= f = TS (x >>= f1, y >>= f2) where
        f1 = tsMaybe . f
        f2 = tsIO . f

-- testMsg
-- Print a message (e.g., "Test Suite: ...") in TestState monad
testMsg :: String -> TestState ()
testMsg str = TS (Just (), putStrLn str)

-- test
-- Do test in TestState monad
-- Given result of test (Bool: True if passed) & description of test
-- Adds result of test & description + pass/fail output to monadic value
test :: Bool -> String -> TestState ()
test success descrip = TS (theMaybe, putStrLn fullDescrip) where
    theMaybe  | success    = Just ()
              | otherwise  = Nothing
    fullDescrip = "    Test: " ++ descrip ++ " - " ++ passFailStr
    passFailStr  | success    = "passed"
                 | otherwise  = "********** FAILED **********"

-- testEq
-- Like test, but given 2 values, checks whether they are equal
testEq :: Eq a => a -> a -> String -> TestState ()
testEq a b str = test (a == b) str

-- printResults
-- Converts TestState monadic value to IO monadic value
--  with summary of all test results
printResults :: TestState () -> IO ()
printResults z = do
    -- Do IO from tests
    tsIO z
    putStrLn ""
    -- Output summary: all passed or not
    putStrLn $ summaryString z
    where
        summaryString (TS (Just _, _)) = "All tests successful"
        summaryString _ = "Tests ********** UNSUCCESSFUL **********"

-- allPassed
-- Given TestState, returns Bool indicating whether all tests passed.
allPassed :: TestState () -> Bool
allPassed (TS (Just _, _)) = True
allPassed _ = False


------------------------------------------------------------------------
-- Test Suites
------------------------------------------------------------------------


-- test_collatzCounts
-- Test Suite for variable collatzCounts
test_collatzCounts = do
    testMsg "Test Suite: Variable collatzCounts"
    testEq (take 10 PA5.collatzCounts) [0,1,7,2,5,8,16,3,19,6]
        "collatzCounts, example from Assn 5 description"
    test (corrCounts numck PA5.collatzCounts)
        ("collatzCounts, first " ++ show numck ++ " items")
    testEq (PA5.collatzCounts !! ii1) vv1
        ("collatzCounts, item #" ++ show ii1 ++ " = " ++ show vv1)
    testEq (PA5.collatzCounts !! ii2) vv2
        ("collatzCounts, item #" ++ show ii2 ++ " = " ++ show vv2)
    where
        numck = 300
        ii1 = 100001
        vv1 = 53
        ii2 = 200001
        vv2 = 90
        corrCounts len list = corrCounts' len list 1
        corrCounts' 0 _ _ = True
        corrCounts' len [] _ = False
        corrCounts' len (t:ts) n = corrCount n t &&
            corrCounts' (len-1) ts (n+1)
        corrCount n t = t >= 0 && iterCol t n == 1 &&
            (t < 3 || iterCol (t-3) n /= 1)
        iterCol 0 n = n
        iterCol t n = coll $ iterCol (t-1) n
        coll n = if mod n 2 == 1 then 3*n+1 else div n 2


-- test_findList
-- Test Suite for function findList
test_findList = do
    testMsg "Test Suite: Function findList"
    testEq (PA5.findList "cde" "abcdefg") (Just 2)
        "findList, example #1 from Assn 5"
    testEq (PA5.findList "cdX" "abcdefg") Nothing
        "findList, example #2 from Assn 5"
    testEq (PA5.findList [1] [2,1,2,1,2]) (Just 1)
        "findList, example #3 from Assn 5"
    testEq (PA5.findList [] [1,2,3,4,5]) (Just 0)
        "findList, example #4 from Assn 5"
    testEq (PA5.findList [20..25] [3..100]) (Just 17)
        "findList, longer list #1: found"
    testEq (PA5.findList ([20..25]++[1]) [3..100]) Nothing
        "findList, longer list #2: not found"
    testEq (PA5.findList ([20..25]++[1]) [3..24]) Nothing
        "findList, longer list #3: not found at end"
    testEq (PA5.findList ([20..25]++[1]) ([3..30]++[20..25]++[1]))
        (Just 28)
        "findList, longer list #4: found 2nd time"
    testEq (PA5.findList ([50..100]++[1..50])
            (h++[1..49]++[49..100]++[10..101]++h++h++h++h))
        (Just 342)
        "findList, longer list #5"
    where
        h = [1..100]


-- test_op_doubleSharp
-- Test Suite for operator ##
test_op_doubleSharp = do
    testMsg "Test Suite: Infix Operator ##"
    testEq ([1,2,3,4,5] PA5.## [1,1,3,3,9,9,9,9,9]) 2
        "op ##, example #1 from Assn 5"
    testEq ([] PA5.## [1,1,3,3,9,9,9,9,9]) 0
        "op ##, example #2 from Assn 5"
    testEq ("abcde" PA5.## "aXcXeX") 3
        "op ##, example #3 from Assn 5"
    testEq ("abcde" PA5.## "XaXcXeX") 0
        "op ##, example #4 from Assn 5"
    testEq (biglist1a PA5.## biglist1b) 333
        "op ##, long lists #1"
    testEq (biglist2a PA5.## biglist2b) 1003
        "op ##, long lists #2"
    where
        biglist1a = filter (\n -> mod n 3 /= 0) [1..1000]
        biglist1b = 0:filter (\n -> mod n 3 /= 1) [1..1000]
        biglist2a = [1..1000]++[1002,1004..3000]++[2502,2504..3500]
        biglist2b = [1..500]++[2,4..2000]++[2501..3500]


-- test_filterAB
-- Test Suite for function filterAB
test_filterAB = do
    testMsg "Test Suite: Function filterAB"
    testEq (PA5.filterAB (>0) [-1,1,-2,2] [1,2,3,4,5,6]) [2,4]
        "filterAB, example #1 from Assn 5 description"
    testEq (PA5.filterAB (==1) [2,2,1,1,1,1,1] "abcde") "cde"
        "filterAB, example #2 from Assn 5 description"
    testEq (PA5.filterAB (=='z') "azazazazazaz" [1..11]) [2,4..10]
        "filterAB, 1st list is string"
    testEq (PA5.filterAB (\n -> mod n 4==2) [1..100] "spaghetti")
        "pe"
        "filterAB, 2nd list is string"
    testEq (PA5.filterAB (\n -> mod n 3==1) [2..100000] [6,8..4000])
        [10,16..4000]
        "filterAB, longer lists #1"
    testEq (PA5.filterAB (\n -> mod n 3==1) [2..4000] [6,8..100000])
        [10,16..8002]
        "filterAB, longer lists #2"
    testEq (PA5.filterAB (\n -> n>1000 && n<2000) [3,7..3000]
            [4,9..5000])
        [1254,1259..2499]
        "filterAB, longer lists #3"
    testEq (PA5.filterAB (>0) [] [1..100000]) []
        "filterAB, first list empty"
    testEq (PA5.filterAB (\n -> mod n 2==0) [1..100000] noints) []
        "filterAB, second list empty"
    testEq (PA5.filterAB (>0) [] noints) []
        "filterAB, both lists empty"
    where
        noints = []::[Integer]
            -- Empty list that will not confuse the type inference


-- test_sumEvenOdd
-- Test Suite for function sumEvenOdd
test_sumEvenOdd = do
    testMsg "Test Suite: Function sumEvenOdd"
    testEq (PA5.sumEvenOdd [1,2,3,4]) (4,6)
        "sumEvenOdd, example #1 from Assn 5 description"
    testEq (PA5.sumEvenOdd [20]) (20,0)
        "sumEvenOdd, example #2 from Assn 5 description"
    testEq (PA5.sumEvenOdd noints) (0,0)
        "sumEvenOdd, example #3 from Assn 5 description"
    testEq (PA5.sumEvenOdd [1,1,1,1,1,1,1]) (4,3)
        "sumEvenOdd, example #4 from Assn 5 description"
    testEq (PA5.sumEvenOdd [1.2, 3.4]) (1.2+0,3.4+0)
        "sumEvenOdd, floating point"
    testEq (PA5.sumEvenOdd [5,8..10000]) (8330000,8334998)
        "sumEvenOdd, larger list"
    testEq (PA5.sumEvenOdd (take 140 gg))
        (312397703936222181812396565990,505470102976234303264687875545)
        "sumEvenOdd, larger values"
    where
        noints = []::[Integer]
            -- Empty list that will not confuse the type inference
        gg = 2:5:zipWith (+) gg (tail gg)


-- allTests
-- Run all test suites for Assignment 5 functions & variables
allTests = do
    testMsg "TEST SUITES FOR ASSIGNMENT 5 FUNCTIONS & VARIABLES"
    test_collatzCounts
    test_findList
    test_op_doubleSharp
    test_filterAB
    test_sumEvenOdd

-- main
-- Do all test suites & print results.
main = do
    printResults allTests

    -- If all tests pass, print reminder on implementation
    if allPassed allTests then do
        putStrLn ""
        putStrLn "  :::::::::::::::::::::::::::::::::::::::::::::::::::"
        putStrLn "  : Note. sumEvenOdd must be implemented as a fold. :"
        putStrLn "  : The test program cannot check this requirement. :"
        putStrLn "  : (This is just a REMINDER, not a failing test.)  :"
        putStrLn "  :::::::::::::::::::::::::::::::::::::::::::::::::::"
    else
        return ()
    putStrLn ""

