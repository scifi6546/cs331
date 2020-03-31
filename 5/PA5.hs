-- PA5.hs  INCOMPLETE
-- Glenn G. Chappell
-- 2020-03-24
--
-- For CS F331 / CSCE A331 Spring 2020
-- Solutions to Assignment 5 Exercise B

module PA5 where


-- collatzCounts
collatzCounts :: [Integer]
collatzCounts = [42..]  -- DUMMY; REWRITE THIS!!!


-- findList
findList :: Eq a => [a] -> [a] -> Maybe Int
findList _ _ = Just 42  -- DUMMY; REWRITE THIS!!!
is_eq:: Eq a =>(a,a) ->Bool
is_eq tuple
    | fst tuple == snd tuple = True 
    | otherwise = False
-- operator ##
(##) :: Eq a => [a] -> [a] -> Int
list_a ## list_b = foldr1 (+) (map (\_ -> 1) (filter (is_eq) (zip list_a list_b)))  -- DUMMY; REWRITE THIS!!!

-- filterAB
filterAB :: (a -> Bool) -> [a] -> [b] -> [b]
filterAB stmt a_list b_list = map (\tuple -> snd tuple) (filter (\tuple ->stmt (fst tuple)) (zip a_list b_list))  -- DUMMY; REWRITE THIS!!!


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

