local pa={}

function pa.filterTable(fn,tbl)
	local tbl_out={}
	for k,v in pairs(tbl)
	do
		
		if( fn(v) )
		then
			tbl_out[k]=v
		end 

	end
	print(tbl_out)
	return tbl_out
end
function pa.concatMax(str,end_len)
	local num_concat = math.floor(end_len/str:len(str))
	return str:rep(num_concat)
	
end
function pa.collatz(n)
	while(n	~=1) do
		if(n%2==0) then

			coroutine.yield(n);
			n=n/2
		else
			coroutine.yield(n);
			n = 3*n+1
		end


	end
	coroutine.yield(n);

end
function pa.allSubs(str)
	local current_len =0 
	local index =0 
	local function iter(foo,bar)
		print(str)
		if index==string.len(str) then
		        index=index+1
			return "" 
		end
		if index>=string.len(str) then
			return nil
		end
		if index+current_len>=string.len(str) then
			current_len = 1 
			index = index+1
			if index==string.len(str)-1 then
				return nil
			end
		local temp_str = string.sub(str,index,index+current_len)
		current_len = current_len+1
		return  temp_str
		end
		
		local temp_str = string.sub(str,index,index+current_len)
		current_len = current_len+1
		return  temp_str
	end
	return iter,nil,nil


end

return pa
