-- Nicholas Alexeevb
-- Program For calculating median of list
import Data.List (sort)
getArr arr = do
          item <- getLine
          if item == ""
              then return arr
              else getArr (( read item ::Integer) : arr)
	          
get_median arr
   | len `mod` 2 == 0 = ((arr_sorted !! (index-1)) + (arr_sorted !! (index))) `div` 2
   | len `mod` 2 == 1 = arr_sorted !! ((len `div` 2))
   where
     arr_sorted = sort arr
     len = length arr
     index = len `div` 2
main :: IO()
main = do putStrLn "Please Input Numbers followed by newline\nWarning Inputting a non int may crash the program as no error handeling occurs\nOutputs floored median"
	  a <- getArr []
	  let med = get_median a
	  putStrLn "Median"
          putStrLn (show med)
