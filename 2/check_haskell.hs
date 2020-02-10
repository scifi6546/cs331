-- check_haskell.hs
-- Glenn G. Chappell
-- 2020-02-03
--
-- For CS F331 / CSCE A331 Spring 2020
-- A Haskell Program to Run
-- Used in Assignment 2, Exercise 1

module Main where


-- main
-- Print second secret message.
main = do
    putStrLn "Secret message #2:"
    putStrLn ""
    putStrLn secret_message


-- secret_message
-- A mysterious message.
secret_message = map xk xj where
    xa = [87,20,4,-87,34,3,-7,-38]
    xb = [66,12,-11,3,-5,-77,87,-12]
    xc = [4,-5,-84,45,37,-23,9,6]
    xd = [-13,3,-11,-59,-14,39,-43,70]
    xe = [5,-1,-13,-57]
    xf = [2,-13,17,31,-14,6]
    xg = "The treasure is buried under a palm tree on the third island."
    xh = map (+ xl) $ concat [xa, xb, xc, xd, xe]
    xi a as = a : map (+ a) as
    xj = foldr xi [] xh
    xk a = toEnum a `asTypeOf` (head xg)
    xl = head xf

