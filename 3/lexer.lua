
local lexer = {}
lexit = require "lexit"
function is_idstart(char)
	if char:match("_") or char:match("[A-Z]") or char:match("[a-z]") then
		return true
	end
	return false
end
function is_keyword(word) 
	print("TODO NOT DONE")
	return false
end

function lexer.lex(input)
	local index = 0;
	local len = string.len(input)
	local in_word = false
	local in_str=false
	local in_opr = false
	local in_punc=false
	
	return function()
		index = index+1
		if index<len then
			--check flags
			if in_word==false and in_str==false and in_opr==false and in_punc==false then
				current_char = input:sub(index,index)
				if is_idstart(current_char) then
					print("MATCHED "..current_char)
					in_word = true
				end
			end
			if in_word then
				local current_string = ""
				while true do
					if is_idstart(input:sub(index+1,index+1)) then
						current_string=string.format("&s%s",current_string,input:sub(index+1,index+1))
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
			return input,lexer.KEY
		end
	end

end
return lexer
