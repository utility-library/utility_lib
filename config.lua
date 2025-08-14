Config = {}

Config.UpdateCooldown = 500 -- (default: 500ms) This is the time when every loop will update (dialogues, markers, utilityNet rendering)

-- Used for utility net dynamic update based on workload/number of entities, this is the timeout of a single loop in performance-saving mode
Config.UtilityNetDynamicUpdate = 3000