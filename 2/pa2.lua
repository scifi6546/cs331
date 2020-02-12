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
	local flag = 0
	local ended = 0
	local function iter(foo,bar)
		if(ended==1)then
			return nil
		end
		--special case for empty string
		if string.len(str)==0 then
			if flag==0 then
				flag=1
				return ""
			else 
				return nil
			end

		end
		local out_str = string.sub(str,index-current_len,index)
		if index==0 and current_len==0 then
			out_str=""
		end
		index= index+1
		if index>string.len(str) then
			index = current_len+2
			current_len=current_len+1
			if index>string.len(str) then
				ended=1
				return str
			end
		end
		return out_str
	end
	return iter,nil,nil
end

return pa
