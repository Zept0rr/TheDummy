--!strict
-- Server bootstrap. Wave 1 economy only.

local Remotes = require(script.Remotes)
local Economy = require(script.Economy)

Remotes.bind()
Economy.start()
