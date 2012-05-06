local primes = {}

function primes.generate (lowBound, highBound, amount)
	local primes   = {}
	local toReturn = {}
	for i = lowBound, highBound, 1 do
		primes[#primes + 1] = i
	end
	local l = #primes
	for i = 1, l do
		local prime = primes[i]
		if prime then
			for j = i + 1, l do
				local multiple = primes[j]
				if multiple and multiple % prime == 0 then
					primes[j] = nil
				end
			end
		end
	end
	local j = 0
	for i = 1, amount do
		repeat
			j = j + 1
			if j > l then
				j = 1
			end
		until primes[j]
		toReturn[i] = primes[j]
	end
	return toReturn
end

return primes
