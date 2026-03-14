local Suffixes = {
	"k",
	"m",
	"b",
	"t",
	"q",
	"Q",
	"s",
	"S",
	"O",
	"N",
	"d",
	"U",
	"D",
	"T",
	"Qt",
	"Qd",
	"Sd",
	"St",
	"OD",
	"ND",
	"V",
	"UV",
	"DV",
	"TV",
	"QTV",
	"QDV",
	"SDV",
	"STV",
	"ODV",
	"NDV",
	"TGV",
	"QTGV",
	"QDGV",
	"SDGV",
	"STGV",
	"ODGV",
	"NDGV",
	"CGV",
	"UCGV",
	"DCGV",
	"TCGV",
	"QTCGV",
	"QDCGV",
	"SDCGV",
	"STCGV",
	"ODCGV",
	"NDCGV",
	"MCGV",
}

return {
	Abbreviate = function(Number: number): string
		if Number < 1000 then
			return tostring(Number)
		end

		local Exponent = math.floor(math.log10(Number) / 3)
		local AbbreviatedNumber = math.floor(Number / 1000 ^ Exponent * 100) / 100

		if Exponent > #Suffixes then
			return tostring(Number)
		end

		return string.format("%.2f%s", AbbreviatedNumber, Suffixes[Exponent])
	end,
}
