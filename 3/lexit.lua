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
function is_keyword(word) 
	print("TODO NOT DONE")
	return false
end

function lexit.lex(input)
	local index = 0;
	local len = string.len(input)
	local in_word = false
	local in_str=false
	local in_opr = false
	local in_punc=false
	
	return function()
		print(input)
		if index<len then
			--check flags
			if in_word==false and in_str==false and in_opr==false and in_punc==false then
				current_char = input:sub(index,index+1)
				if is_idstart(current_char) then
					print("MATCHED "..current_char)
					in_word = true
				end
			end
			if in_word then
				local current_string = ""
				while true do
					if is_idstart(input:sub(index,index+1)) and index<len then
						current_string = current_string..input:sub(index,index+1)
						print("added")
						index=index+1
					else 
						index=index+1
						if is_keyword(current_string) then
							return current_string,lexit.KEY
						end
						return current_string,lexit.ID
					end

				end
				

			end
			--[[
			if in_word then
				--do word stuff
			else if in_str then
				--do in_str stuff
			else if in_opr then 
				--do in_opr stuff
			else if in_punc then
				--do punc stiff
			end
			--]]
		else
			print("length wrong?")
		end
	end

end
return lexit
