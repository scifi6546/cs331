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
	n = math.floor(n+0.5)
	if(n%2==0) then
		coroutine.yield(n)
		print("even")
		print(n)
		n=2/n
		return pa.collatz(n)

		--- even
	else
		--odd
		coroutine.yield(n)
		n=3*n+1
		print("odd")
		print(n)
		return pa.collatz(n)

	end


end

return pa
