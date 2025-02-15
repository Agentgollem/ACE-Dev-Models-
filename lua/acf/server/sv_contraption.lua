--i'll leave almost everything ready so they can be exported to acf-3 in some near future
--print("[ACE | INFO]- Loading Contraption System. . .")
--ACE               = ACE or {}
ACE.contraptionEnts = {} --table which will have all registered ents
ACE.radarEntities   = {} --for tracking radar usage
ACE.radarIDs        = {} --ID radar purpose
ACE.ECMPods         = {} --ECM usage
ACE.Opticals        = {} --GLATGM optical computers
ACE.Explosives      = {} --Explosive entities like ammocrates & fueltanks go here
ACE.Debris          = {} --Debris count

--list of classname ents which should be added to the contraption ents.
local AllowedEnts = {
	["acf_rack"]                  = true,
	["prop_vehicle_prisoner_pod"] = true,
	["ace_crewseat_gunner"]       = true,
	["ace_crewseat_loader"]       = true,
	["ace_crewseat_driver"]       = true,
	["ace_rwr_dir"]               = true,
	["ace_rwr_sphere"]            = true,
	["acf_missileradar"]          = true,
	["acf_opticalcomputer"]       = true,
	["gmod_wire_expression2"]     = true,
	["gmod_wire_gate"]            = true,
	["prop_physics"]              = true,
	["ace_ecm"]                   = true,
	["ace_trackingradar"]         = true,
	["ace_irst"]                  = true,
	["acf_gun"]                   = true,
	["acf_ammo"]                  = true,
	["acf_engine"]                = true,
	["acf_fueltank"]              = true,
	["acf_gearbox"]               = true,
	["primitive_shape"]           = true,
	["primitive_airfoil"]         = true,
	["primitive_rail_slider"]     = true,
	["primitive_slider"]          = true,
	["primitive_ladder"]          = true
}

--used mostly by contraption. Put here any entity which contains IsExplosive boolean
ACE.ExplosiveEnts = {
	["acf_ammo"]     = true,
	["acf_fueltank"] = true
}

-- whitelist for things that can be turned into debris
ACF.Debris = {
	["acf_gun"]                   = true,
	["acf_rack"]                  = true,
	["acf_gearbox"]               = true,
	["acf_engine"]                = true,
	["prop_physics"]              = true,
	["prop_vehicle_prisoner_pod"] = true
}

-- insert any new entity to the Contraption List
-- Maybe in a future: Change if-else chains by tables
hook.Add("OnEntityCreated", "ACE_EntRegister", function(Ent)
	if not IsValid(Ent) then return end

	-- check if ent class is in whitelist
	if AllowedEnts[Ent:GetClass()] then
		-- include any ECM to this table
		if Ent:GetClass() == "ace_ecm" then
			table.insert(ACE.ECMPods, Ent) --print('[ACE | INFO]- ECM registered count: ' .. table.Count( ACE.ECMPods ))
			-- include any Tracking Radar to this table
		elseif Ent:GetClass() == "ace_trackingradar" then
			table.insert(ACE.radarEntities, Ent) --print('[ACE | INFO]- Tracking radar registered count: ' .. table.Count( ACE.radarEntities ))

			for id, ent in pairs(ACE.radarEntities) do
				ACE.radarIDs[ent] = id
			end
		elseif Ent:GetClass() == "acf_opticalcomputer" then
			--Optical Computers go here
			table.insert(ACE.Opticals, Ent) --print('[ACE | INFO]- GLATGM optical computer registered count: ' .. table.Count( ACE.Opticals ))
		elseif ACE.ExplosiveEnts[Ent:GetClass()] then
			--Insert Ammocrates and other explosive stuff here
			table.insert(ACE.Explosives, Ent) --print('[ACE | INFO]- Explosive registered count: ' .. table.Count( ACE.Explosives ))
		end

		-- Finally, include the whitelisted entity to the main table ( contraptionEnts )
		if not Ent:GetParent():IsValid() then
			table.insert(ACE.contraptionEnts, Ent)
			--print("[ACE | INFO]- an entity ' .. Ent:GetClass() .. ' has been registered!")
			--print('Total Ents registered count: ' .. table.Count( ACE.contraptionEnts ))
		end
	elseif Ent:GetClass() == "ace_debris" then
		table.insert(ACE.Debris, Ent) --print('Adding - Count: ' .. #ACE.Debris)
	end
end)

-- Remove any entity of the Contraption List that has been removed from map
hook.Add("EntityRemoved", "ACE_EntRemoval", function(Ent)
	--Assuming that our table has whitelisted ents
	if AllowedEnts[Ent:GetClass()] then
		for i = 1, #ACE.contraptionEnts do
			--check if it's valid
			if not IsValid(ACE.contraptionEnts[i]) or not IsValid(Ent) then continue end
			local MEnt = ACE.contraptionEnts[i]

			-- Remove this ECM from list if deleted
			if Ent:GetClass() == "ace_ecm" then
				for i = 1, table.Count(ACE.ECMPods) do
					if ACE.ECMPods[i]:IsValid() and Ent:IsValid() then
						local ECM = ACE.ECMPods[i]

						if ECM:EntIndex() == Ent:EntIndex() then
							table.remove(ACE.ECMPods, i)
							--print("[ACE | INFO]- the ECM ' .. Ent:GetClass() .. ' (" .. Ent:GetModel() .. ") has been removed!")
							--print('ECM registered count: ' .. table.Count( ACE.ECMPods ))
							break
						end
					end
				end
				-- Remove this Tracking Radar from list if deleted
			elseif Ent:GetClass() == "ace_trackingradar" then
				for i = 1, table.Count(ACE.radarEntities) do
					if ACE.radarEntities[i]:IsValid() and Ent:IsValid() then
						local TrRadar = ACE.radarEntities[i]

						if TrRadar:EntIndex() == Ent:EntIndex() then
							table.remove(ACE.radarEntities, i)
							--print("[ACE | INFO]- the TrRadar ' .. Ent:GetClass() .. ' (" .. Ent:GetModel() .. ") has been removed!")
							--print('Tracking radar registered count: ' .. table.Count( ACE.radarEntities ))
							break
						end
					end
				end
			elseif Ent:GetClass() == "acf_opticalcomputer" then
				-- Remove this GLATGM optical Computer from list if deleted
				for i = 1, table.Count(ACE.Opticals) do
					if ACE.Opticals[i]:IsValid() and Ent:IsValid() then
						local Optical = ACE.Opticals[i]

						if Optical:EntIndex() == Ent:EntIndex() then
							table.remove(ACE.Opticals, i)
							--print("[ACE | INFO]- the Optical ' .. Ent:GetClass() .. ' (" .. Ent:GetModel() .. ") has been removed!")
							--print('GLATGM optical computer registered count: ' .. table.Count( ACE.Opticals ))
							break
						end
					end
				end
			elseif ACE.ExplosiveEnts[Ent:GetClass()] then
				for i = 1, table.Count(ACE.Explosives) do
					if ACE.Explosives[i]:IsValid() and Ent:IsValid() then
						local Explosive = ACE.Explosives[i]

						if Explosive:EntIndex() == Ent:EntIndex() then
							table.remove(ACE.Explosives, i)
							--print("[ACE | INFO]- the Explosive ' .. Ent:GetClass() .. ' (" .. Ent:GetModel() .. ") has been removed!")
							--print('[ACE | INFO]- Explosive registered count: ' .. table.Count( ACE.Explosives ))
							break
						end
					end
				end
			end

			-- Finally, remove this Entity from the main list
			--check if we are taking same ent
			if MEnt:EntIndex() == Ent:EntIndex() then
				table.remove(ACE.contraptionEnts, i) --if same, remove it
				--print("[ACE | INFO]- the entity ' .. Ent:GetClass() .. ' (" .. Ent:GetModel() .. ") has been removed!")
				--print('Total Ents registered count: ' .. #ACE.contraptionEnts)
				--code has ended its work, return

				return
			end
		end
	elseif Ent:GetClass() == "ace_debris" then
		for i = 1, #ACE.Debris do
			if not IsValid(ACE.Debris[i]) then continue end

			if ACE.Debris[i]:EntIndex() == Ent:EntIndex() then
				table.remove(ACE.Debris, i) --print('Removing - Count: ' .. #ACE.Debris)

				return
			end
		end
	end
end)

-- Optimization resource, this will try to clean the main table just to reduce Ent count
function ACE_refreshdata(Data)
	--Not really perfect, but better than nothing. Cframepls
	if istable(Data) and not table.IsEmpty(Data) then
		local Entities = Data[1].CreatedEntities --wtf wire
		local ContrId = math.random(1, 10000)

		for _, ent in pairs(Entities) do
			if not IsValid(ent) then continue end
			ent.ACF = ent.ACF or {}
			ent.ACF.ContraptionId = ContrId --Id is always changing.
		end
	end

	--print("[ACE | INFO]- Starting Refreshing. . .")
	for index, Ent in ipairs(ACE.contraptionEnts) do
		-- check if the entity is valid
		if not IsValid(Ent) then continue end

		-- check if it has parent
		-- if parented, check if it's not a Heat emitter
		if Ent:GetParent():IsValid() and not Ent.Heat then
			-- if not, remove it. Removing most of parented props will decrease cost of guidances
			--print("[ACE | INFO]- Parented prop! removing. . .")
			table.remove(ACE.contraptionEnts, index)
			continue
		end
	end
	--print("[ACE | INFO]- Finished refreshing!")
	--print('Total Ents registered count: ' .. table.Count( ACE.contraptionEnts ))
end

hook.Add("AdvDupe_FinishPasting", "ACE_refresh", ACE_refreshdata)