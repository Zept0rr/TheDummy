--!strict
-- Display only: 1.2K, 3.4M, 1.0e12. Never used as economy math.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type Decimal = Formulas.Decimal
local Decimal = Formulas.Decimal

local DEFAULT_SUFFIXES = { "", "K", "M", "B", "T" }
local DEFAULT_DECIMALS = 1
local DEFAULT_SCI_FROM = 12

local Format = {}

local function isTable(value: any): boolean
	return typeof(value) == "table"
end

local function readNumberFormat(): (number, { string }, number)
	local decimals = DEFAULT_DECIMALS
	local suffixes = DEFAULT_SUFFIXES
	local sciFrom = DEFAULT_SCI_FROM

	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local module = if shared then shared:FindFirstChild("Config") else nil
	if module == nil then
		return decimals, suffixes, sciFrom
	end

	local ok, cfg = pcall(require, module)
	if not ok or not isTable(cfg) then
		return decimals, suffixes, sciFrom
	end

	local nf = cfg.numberFormat
	if not isTable(nf) then
		return decimals, suffixes, sciFrom
	end

	if typeof(nf.decimals) == "number" and nf.decimals == nf.decimals then
		decimals = math.clamp(math.floor(nf.decimals), 0, 4)
	end
	if typeof(nf.sciFromExponent) == "number" and nf.sciFromExponent == nf.sciFromExponent then
		sciFrom = math.max(0, math.floor(nf.sciFromExponent))
	end
	if isTable(nf.suffixes) then
		local listed: { string } = {}
		for _, suffix in nf.suffixes do
			if typeof(suffix) == "string" then
				table.insert(listed, suffix)
			end
		end
		if #listed > 0 then
			suffixes = listed
		end
	end

	return decimals, suffixes, sciFrom
end

local function formatFixed(n: number, decimals: number): string
	if decimals <= 0 then
		return tostring(math.floor(n + 0.5))
	end
	return string.format("%." .. tostring(decimals) .. "f", n)
end

local function compactDecimal(d: Decimal): string
	if d.m == 0 then
		return "0"
	end

	local sign = if d.m < 0 then "-" else ""
	local m = math.abs(d.m)
	local e = d.e
	local decimals, suffixes, sciFrom = readNumberFormat()

	if e >= sciFrom then
		return sign .. formatFixed(m, decimals) .. "e" .. tostring(e)
	end

	local suffixIndex = 1
	for index = #suffixes, 1, -1 do
		local suffixExp = (index - 1) * 3
		if e >= suffixExp then
			suffixIndex = index
			break
		end
	end

	local suffixExp = (suffixIndex - 1) * 3
	if suffixExp == 0 then
		local n = m * (10 ^ e)
		if n >= 100 then
			return sign .. tostring(math.floor(n + 0.5))
		end
		if math.abs(n - math.floor(n + 0.5)) < 1e-6 then
			return sign .. tostring(math.floor(n + 0.5))
		end
		return sign .. formatFixed(n, decimals)
	end

	local scaled = m * (10 ^ (e - suffixExp))
	local shown = tonumber(formatFixed(scaled, decimals)) or scaled
	if shown >= 1000 and suffixIndex < #suffixes then
		suffixIndex += 1
		suffixExp += 3
		scaled /= 1000
		if suffixExp >= sciFrom then
			return sign .. formatFixed(m, decimals) .. "e" .. tostring(e)
		end
	end

	return sign .. formatFixed(scaled, decimals) .. suffixes[suffixIndex]
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
	local prefix = "+"
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local module = if shared then shared:FindFirstChild("Config") else nil
	if module ~= nil then
		local ok, cfg = pcall(require, module)
		if ok and isTable(cfg) and isTable(cfg.copy) and typeof(cfg.copy.hitPopupPrefix) == "string" then
			prefix = cfg.copy.hitPopupPrefix
		end
	end
	return prefix .. Format.compact(value)
end

return Format
