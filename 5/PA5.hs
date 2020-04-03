-- PA5.hs  INCOMPLETE
-- Glenn G. Chappell
-- 2020-03-24
--
-- For CS F331 / CSCE A331 Spring 2020
-- Solutions to Assignment 5 Exercise B

module PA5 where
import Data.List (isPrefixOf)
collatz a 
    | a == 0 = 0
    | a == 1 = 0
    | a `mod` 2 == 0 = 1 + collatz (a `div` 2)
    | a `mod` 2 == 1 = 1 + collatz (3*a+1)
    | otherwise = 2
-- collatzCounts
collatzCounts :: [Integer]
collatzCounts = map collatz [1..] 

findListT :: Eq a => [a] -> [a] -> Int -> Maybe Int
findListT prefix list index
    | length list == 0 = Nothing
    | is_pre == True =Just index
    | is_pre == False = findListT prefix (drop 1 list) (index+1)
    where
      is_pre = isPrefixOf prefix list
-- findList
findList :: Eq a => [a] -> [a] -> Maybe Int
findList prefix list = findListT prefix list 0
is_eq:: Eq a =>(a,a) ->Bool
is_eq tuple
    | fst tuple == snd tuple = True 
    | otherwise = False
-- operator ##
(##) :: Eq a => [a] -> [a] -> Int
list_a ## list_b = foldr (+) 0 (map (\_ -> 1) (filter (is_eq) (zip list_a list_b)))

-- filterAB
filterAB :: (a -> Bool) -> [a] -> [b] -> [b]
filterAB stmt a_list b_list = map (\tuple -> snd tuple) (filter (\tuple ->stmt (fst tuple)) (zip a_list b_list))


-- sumEvenOdd
sumEvenOdd :: Num a => [a] -> (a, a)
{-
  The assignment requires sumEvenOdd to be written using a fold.
  Something like this:

    sumEvenOdd xs = fold* ... xs where
        ...

  Above, "..." should be replaced by other code. The "fold*" must be
  one of the following: foldl, foldr, foldl1, foldr1.
-}
sumEvenOdd _ = (0, 0)  -- DUMMY; REWRITE THIS!!!

