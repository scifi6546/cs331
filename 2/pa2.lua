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

return pa
