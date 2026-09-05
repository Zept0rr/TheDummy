--!strict
-- Display only: 1.2K, 3.4M, 1.0e12. Never used as economy math.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type Decimal = Formulas.Decimal
local Decimal = Formulas.Decimal

local Format = {}

local function compactDecimal(d: Decimal): string
	if d.m == 0 then
		return "0"
	end

	local sign = if d.m < 0 then "-" else ""
	local m = math.abs(d.m)
	local e = d.e

	if e >= 12 then
		return sign .. string.format("%.1fe%d", m, e)
	end

	local suffix = ""
	local suffixExp = 0
	if e >= 9 then
		suffix = "B"
		suffixExp = 9
	elseif e >= 6 then
		suffix = "M"
		suffixExp = 6
	elseif e >= 3 then
		suffix = "K"
		suffixExp = 3
	end

	if suffixExp == 0 then
		local n = m * (10 ^ e)
		if n >= 100 then
			return sign .. tostring(math.floor(n + 0.5))
		end
		if math.abs(n - math.floor(n + 0.5)) < 1e-6 then
			return sign .. tostring(math.floor(n + 0.5))
		end
		return sign .. string.format("%.1f", n)
	end

	local scaled = m * (10 ^ (e - suffixExp))
	return sign .. string.format("%.1f%s", scaled, suffix)
end

function Format.compact(value: any): string
	return compactDecimal(Decimal.from(value))
end

function Format.bonk(value: any): string
	return Format.compact(value)
end

function Format.rate(value: any): string
	return Format.compact(value) .. "/sec"
end

function Format.plus(value: any): string
	return "+" .. Format.compact(value)
end

return Format
