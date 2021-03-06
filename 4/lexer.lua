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
	if char:match("_") or char:match("[A-Z]") or char:match("[a-z]") then
		return true
	end
	return false
end
function is_idbody(char)
	if char:match("_") or char:match("[A-Z]") or char:match("[a-z]") or char:match("[0-9]") then
		return true
	end
	return false
end
function is_punc(char)
	if char=="." or char=="&" or char=="(" or char==")" or char=="@" or char=="$" or char==":" or char=="|" or char=="!" or char=="," or char=="^" or char==";" or char=="?" or char=="@" or char=="\\" or char=="`" or char=="{" or char=="}" or char=="~" then 
		return true
	end
	return false
end
function is_op(char)
	if char=="<" or char==">" or char=="="  then
		return true,true
	end
	
	if char=="+" or char=="-" or char=="*" or char=="/" or char=="%" or char=="[" or char=="]" then
		return true,false
	end
	return false,false
end
function is_num(char) 
	if char:match("[0-9]") then
		return true
	end
	return false
end
function is_string_start(char)
	if char=="'" or char=="\"" then
		return true
	end
	return false
end
function is_string_end(char)
	if char=="'" or char=="\"" then
		return true
	end
	return false
end
function is_keyword(word) 
	
	if word=="and" or word=="char" or word=="elif" or word=="else" or word=="end" then
		return true
	end
	if  word=="false" or word=="func" or word=="if" or word=="input" or word=="not" then
		return true
	end
		 
	if word=="or" or word=="print" or word=="return" or word=="true" then
		return true
	end
	if word=="while" then
		return true
	end 
	return false
end
function is_valid(char)
	if (char >= " " and char <= "~") or char=="\n" or char=="\t" or char=="\r" or char=="\f" then
		return true
	end
	return false
end
function is_invalid(char)
	return is_valid(char)==false
end
function is_comment(char)
	if char=="#" then
		return true
	end
	return false
end
function is_white_space(char)
	if char ==" " or char =="\n" or char=="\t"or char=="\r" or char=="\f" then
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
	function handle_space() 
		current_char = input:sub(index,index)
		while(index<=len) do
				current_char = input:sub(index,index)
				if is_white_space(current_char) then
					index=index+1

				elseif is_invalid(current_char) then
					return handle_invalid("")
				else
					break

				end

		end

	end
	function handle_invalid(input_str)
		local out_str = input_str..input:sub(index,index)
		index=index+1
		return out_str,lexit.MAL
	end
	function handle_comment()
				while index<=len do
					current_char = input:sub(index,index)
					if current_char=="\n" then
						index=index+1
						break;
					else
						index = index+1
					end
					

				end


	end

	function handle_number()
		local current_string = ""
		while index<=len do
			if is_num(input:sub(index,index)) then
				current_string = current_string..input:sub(index,index)
				index=index+1
			else 

				if current_string=="" then
					return
				end
				index=index+1
				return current_string,lexit.NUMLIT
			end

		end


	end
	
	return function()
		while index<=len do
			
			--check flags
			local recognized_syntax=false current_char = input:sub(index,index)
			if is_white_space(current_char) then
				recognized_syntax=true
				local data,data2 = handle_space()
				if data~=nil then
					return data,data2
				end


			end
			if is_comment(current_char) then 
				recognized_syntax=true
				handle_comment()
			end
			if is_invalid(current_char) then
				return handle_invalid("")
			end


			if current_char=="!" and input:sub(index+1,index+1)=="=" then
				recognized_syntax=true
				index=index+2
				return "!=",lexit.OP
			end
			if is_punc(current_char) then
				recognized_syntax=true
				
				index=index+1
				return current_char,lexit.PUNCT
			end
			local can_equal_follow=false
			local is_operator = false
			is_operator, can_equal_follow=is_op(current_char)
			if is_operator then
				if input:sub(index+1,index+1)=="=" and can_equal_follow==true then
					index=index+2
					return current_char.."=",lexit.OP
				else
					recognized_syntax=true
					index=index+1
					return current_char,lexit.OP
				end
			end
			if is_num(current_char) then 
				recognized_syntax=true
				local current_string = ""
				local chars_since_e=-1
				while index<=len do

					local called = false
					local next_char = input:sub(index+1,index+1)
					if chars_since_e==-1 and (input:sub(index,index)=="e" or input:sub(index,index)=="E") then
						if next_char=="+" and is_num(input:sub(index+2,index+2)) then
							current_string=current_string..input:sub(index,index)
							chars_since_e=0
							index=index+1
							called =true
							
						elseif is_num(next_char) then
							current_string=current_string..input:sub(index,index)
							chars_since_e=0
							index=index+1
							called =true
						else
							break
						end
						
					elseif chars_since_e==0 and (input:sub(index,index)=="+") then 
						chars_since_e = chars_since_e+1
						current_string=current_string..input:sub(index,index)
						index=index+1
						called = true
					elseif is_num(input:sub(index,index)) then
						current_string = current_string..input:sub(index,index)
						index=index+1
						if chars_since_e>=0 then
							chars_since_e=chars_since_e+1
						end
						called = true
					else
						if current_string=="" then
							return nil
						end
						return current_string,lexit.NUMLIT
					end
					if called~=true then
						break
					end
				end
				return current_string,lexit.NUMLIT

			elseif is_idstart(input:sub(index,index)) then
				recognized_syntax=true
				local current_string = ""
				while index<=len do
					local current_char=input:sub(index,index)
					if is_idbody(input:sub(index,index)) then
						current_string = current_string..input:sub(index,index)
						index=index+1
					else 
						if is_invalid(current_string) then
							return handle_invalid()
						elseif current_string=="" then
							return
						elseif is_keyword(current_string) then
							return current_string,lexit.KEY
						else
							return current_string,lexit.ID
						end
					end

				end
				if is_keyword(current_string) then
					return current_string,lexit.KEY
				else
					return current_string,lexit.ID
				end
			elseif is_string_start(input:sub(index,index)) then
				recognized_syntax=true
				local escape=false
				local start_char = input:sub(index,index)
				local current_string=start_char
				index=index+1
				while index<=len do
					local current_char=input:sub(index,index)
					if is_string_end(current_char) and escape==false and current_char==start_char  then
						current_string = current_string..input:sub(index,index)
						index=index+1
						return current_string,lexit.STRLIT
					elseif current_char=="\\" then
						if escape==true then
							escape=false
							current_string=current_string..current_char
							index=index+1
						else
							current_string=current_string..current_char
							index=index+1
							escape=true
						end
					else 
						current_string=current_string..current_char
						index=index+1
						escape=false
					end
				end
				return current_string,lexit.MAL

			end
			if recognized_syntax==false then
				local current_string=""
				while(index<=len) do
					current_char=input:sub(index,index)
					current_string=current_string..current_char
					index=index+1
				end

				return current_string,lexit.MAL
			end
		end
	end

end
return lexit
