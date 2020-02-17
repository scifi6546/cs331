local lexit = {}
lexit.KEY = 1
lexit.ID = 2
lexit.NUMLIT=3
lexit.STRLIT = 4
lexit.OP=5
lexit.PUNCT=6
lexit.MAL=7
lexit.catnames={}

lexit.catnames[1]="Keyword"
lexit.catnames[2]="Identifier"
lexit.catnames[3]="NumericLiteral"
lexit.catnames[4]="StringLiteral"
lexit.catnames[5]="Operator"
lexit.catnames[6]="Punctuation"
lexit.catnames[7]="Malformed"

function is_idstart(char)
	print("char: "..char)
	if char:match("_") or char:match("[A-Z]") or char:match("[a-z]") then
		return true
	end
	return false
end
function is_idbody(char)
	print("char: "..char)
	if char:match("_") or char:match("[A-Z]") or char:match("[a-z]") or char:match("[0-9]") then
		return true
	end
	return false
end
function is_keyword(word) 
	print("TODO NOT DONE")
	return false
end
function is_comment(char)
	if char=="#" then
		return true
	end
	return false
end
function is_white_space(char)
	print("checking if whitespace")
	if char ==" " or char =="\n" then
		return true
	end
	return false
end

function lexit.lex(input)
	local index = 1;
	local len = string.len(input)
	local in_word = false
	local in_str=false
	local in_opr = false
	local in_punc=false
	local in_comment=false
	
	return function()
		print(input)
		if index<=len then
			--check flags
			current_char = input:sub(index,index)
			if is_white_space(current_char) then
				while(true) do
					if index<=len then
						current_char = input:sub(index,index)
						print("c char: \'"..current_char.."\'")
						if is_white_space(current_char) then
							print("incrementing index")
							index=index+1

						else
							break;

						end

					else
						print("index: "..index.." to big")
						return
					end
					
				end

			end
			if is_idstart(current_char) then
				print("MATCHED "..current_char)
				in_word = true
			end
			if is_comment(current_char) then
				print("IN COMMENT")
				in_comment=true
			end

			if in_comment then 
				while true do
					if index>len then
						return
					end
					break
					current_char = input:sub(index,index)
					if current_char~="\n" then
						index=index+1
					else
						break;
					end

				end

			end
			
			if in_word then
				local current_string = ""
				while true do
					print("index: "..index)
					if is_idbody(input:sub(index,index)) and index<=len then
						current_string = current_string..input:sub(index,index)
						print("current_string: "..current_string)
						index=index+1
					else 

						if current_string=="" then
							return
						end
						index=index+1
						if is_keyword(current_string) then
							return current_string,lexit.KEY
						end
						return current_string,lexit.ID
					end

				end
				

			end
		else
			print("length wrong?")
		end
	end

end
return lexit
