return {
	Load = function(Folder: Folder | Model): { [string]: typeof(require(nil :: ModuleScript)) }
		local Table: { [string]: typeof(require(nil :: ModuleScript)) } = {}
		for _, Module in ipairs(Folder:GetChildren()) do
			if Module:IsA("ModuleScript") then
				Table[Module.Name] = require(Module)
			else
				break
			end
		end
		return Table
	end,
}
