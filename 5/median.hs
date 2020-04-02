getArr array
  | str==return("\n") = array
  | otherwise = str --fmap (read) (str) : array
  where a = str >>= getLine
main :: IO()
main = do putStrLn "Please Input Numbers followed by newline\nWarning Inputting a non int may crash the program as no error handeling occurs"
          c <- getLine
          let i = read c :: Integer
          putStrLn (show i)
