local version = "1.271"
--[[
This script is a version of All-In-One Soraka by One™ Rewriten by VictorGrego!!!

Features:
- Auto Level Abilities
- Auto Starcall (Q) [M]
- Auto Heal (W) [M]
- Auto Infuse Ally (E) [M]
- Auto Silence Enemy (E)
- Auto Ult [M]
- Factor in passive for maximum effeciency
- Farm deny cannon minions with (W)
- Farm steal cannon minions with (E)
- Avoid hitting enemy under turret
- Auto Buy items

Changelog:

V1.2 - 05/07/2014 Integrated buying and did a lot of optimizations and bugfix. Also did new auto update system.
V1.1 - 01/07/2014 Did code optmizations, started integration of 5 scripts that used compose this package
V1.0 - Original Script Versions by One™
--]]

-- Champion Check
if myHero.charName ~= "Soraka" then return end

shopList = {
	3301,-- coin
	3340,--ward trinket
	1004,1004,--Faerie Charm
	3028,
	--1028,--Ruby Crystal
	--2049,--Sighstone
	3096,--Nomad Medallion
	3114,--Forbidden Idol
	3069,--Talisman of Ascension
	1001,--Boots 
	3108,--Fiendish Codex
	3174,--Athene's Unholy Grail
	--2045,--Ruby Sighstone
	1028,--Ruby Crystal
	1057,--Negatron Cloak
	3105,--Aegis of Legion
	3158,--Ionian Boots
	1011,--Giants Belt
	3190,--Locket of Iron Solari
	3143,--Randuins
	3275,--Homeguard
	1058,--Large Rod
	3089--Rabadon
}

nextbuyIndex = 1
lastBuy = 0

buyDelay = 100 --default 100

--UPDATE SETTINGS
local AutoUpdate = true
local SELF = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local URL = "https://raw.githubusercontent.com/victorgrego/BolSorakaScripts/master/UnifiedSoraka.lua?"..math.random(100)
local UPDATE_TMP_FILE = LIB_PATH.."UNSTmp.txt"
local versionmessage = "<font color=\"#81BEF7\" >Changelog: Added autobuy option and changed build to spam skills</font>"

function Update()
	DownloadFile(URL, UPDATE_TMP_FILE, UpdateCallback)
end

function UpdateCallback()
	file = io.open(UPDATE_TMP_FILE, "rb")
	if file ~= nil then
		content = file:read("*all")
		file:close()
		os.remove(UPDATE_TMP_FILE)
		if content then
			tmp, sstart = string.find(content, "local version = \"")
			if sstart then
				send, tmp = string.find(content, "\"", sstart+1)
			end
			if send then
				Version = tonumber(string.sub(content, sstart+1, send-1))
			end
			if (Version ~= nil) and (Version > tonumber(version)) and content:find("--EOS--") then
				file = io.open(SELF, "w")
			if file then
				file:write(content)
				file:flush()
				file:close()
				PrintChat("<font color=\"#81BEF7\" >UnifiedSoraka:</font> <font color=\"#00FF00\">Successfully updated to: v"..Version..". Please reload the script with F9.</font>")
			else
				PrintChat("<font color=\"#81BEF7\" >UnifiedSoraka:</font> <font color=\"#FF0000\">Error updating to new version (v"..Version..")</font>")
			end
			elseif (Version ~= nil) and (Version == tonumber(version)) then
				PrintChat("<font color=\"#81BEF7\" >UnifiedSoraka:</font> <font color=\"#00FF00\">No updates found, latest version: v"..Version.." </font>")
			end
		end
	end
end
-- Constants (do not change)
local GLOBAL_RANGE = 0
local NO_RESOURCE = 0
local DEFAULT_STARCALL_MODE = 3
local DEFAULT_STARCALL_MIN_MANA = 300 --Starcall will not be cast if mana is below this level
local DEFAULT_NUM_HIT_MINIONS = 3 -- number of minions that need to be hit by starcall before its cast
local DEFAULT_HEAL_MODE = 2
local DEFAULT_HEAL_THRESHOLD = 75 -- for healMode 3, default 75 (75%)
local DEFAULT_INFUSE_MODE = 2 
local DEFAULT_MIN_ALLY_SILENCE = 70 -- percentage of mana nearby ally lolshould have before soraka uses silence
local DEFAULT_ULT_MODE = 2
local DEFAULT_ULT_THRESHOLD = 35 --percentage of hp soraka/ally/team must be at or missing for ult, eg 10 (10%)
local DEFAULT_DENY_THRESHOLD = 75
local DEFAULT_STEAL_THRESHOLD = 60
local MAX_PLAYER_AA_RANGE = 850
local HEAL_DISTANCE = 700
local HL_slot = nil
local CL_slot = nil
local DEFAULT_MANA_CLARITY = 50

-- Recall Check
local isRecalling = false
local RECALL_DELAY = 0.5

-- Auto Level
local levelSequence = {_W,_E,_Q,_W,_W,_R,_W,_E,_W,_E,_R,_E,_E,_Q,_Q,_R,_Q,_Q}

-- Auto Heal (W) - Soraka heals the nearest injured ally champion
local RAW_HEAL_AMOUNT = {70, 120, 170, 220, 270}
local RAW_HEAL_RATIO = 0.35
local HEAL_RANGE = 750

--[[ healMode notes:
1 = heal if nearest ally is missing any health, [Normal]
2 = heal if nearest ally is missing as much health as the heal (ie so none of the heal will be wasted) [Smart]
3 = heal if nearest ally is below 'healThreshold'. Ie ally is below 0.75 (75%) of their full hp. [Threshold]
-]]

--Auto StarCall (Q)
local STARCALL_RANGE = 675

--[[ starcallMode notes:
1 = use only when at least one enemy will be hit by starcall [Harass only]
2 = use only when at least X minions will be hit by starcall (enemy champions may be hit if in range) {Farm/Push only]
3 = use only when at at least one enemy OR at least X minions will be hit by starcall [Both of the above, hit any]
4 = use only when at at least one enemy AND at least X minions will be hit by starcall [Both of the above, hit enemy and minions]
-]]

--Auto Infuse Ally (E) - Gives mana back to ally
local RAW_INFUSE_AMOUNT = {20, 40, 60, 80, 100}
local RAW_INFUSE_RATIO = 0.05 -- of maximum mana

local INFUSE_RANGE = 725

--[[ infuseMode notes:
1 = provide mana to the most mana deprived ally if they are missing any mana
2 = provide mana to the most mana deprived ally if they yare missing as much mana as the restore amount
-]]

--Auto Silence Enemy (E) - Silences an enemy unit
-- Note: SILENCE_RANGE = INFUSE_RANGE (same range)

-- Auto Ultimate
-- RAW_ULT_AMOUNT = {150, 250, 350}
-- RAW_ULT_RATIO = 0.55 -- of AP

--[[ ultMode notes:
1 = ult when Soraka is low/about to die, under ultThreshold% of hp [selfish ult]
2 = ult when ally is low/about to die, under ultThreshold% of hp [lane partner ult]
3 = ult when total missing health of entire team exceeds ultThreshold (ie 50% of entire team health is missing)
-]]

--[[ Main Functions ]]--

-- Soraka performs starcall to help push/farm a lane or harrass enemy champions (or both)
function doSorakaStarcall()

	-- Perform Starcall based on starcallMode
	local hitEnemy = false
	local hitMinions = false

	-- Calculations
	local enemy = GetPlayer(TEAM_ENEMY, false, false, player, STARCALL_RANGE, NO_RESOURCE)

	if enemy ~= nil then hitEnemy = true end

	if config.autoStarcall.starcallTowerDive == false and UnderTurret(player, true) == true and hitEnemy then return end
	-- Minion Calculations
	enemyMinions:update()
	local totalMinionsInRange = 0

	for _, minion in pairs(enemyMinions.objects) do
		if player:GetDistance(minion) < STARCALL_RANGE then
			totalMinionsInRange = totalMinionsInRange + 1
		end

		if totalMinionsInRange >= config.autoStarcall.numOfHitMinions then 
			hitMinions = true
			break 
		end
	end

	if config.autoStarcall.starcallMode == 1 and hitEnemy then
		CastSpell(_Q)
	elseif config.autoStarcall.starcallMode == 2 and hitMinions then 
		CastSpell(_Q)
	elseif config.autoStarcall.starcallMode == 3 and (hitEnemy or hitMinions) then
		CastSpell(_Q)
	elseif config.autoStarcall.starcallMode == 4 and (hitEnemy and hitMinions) then
		CastSpell(_Q)
	end
end

-- Soraka Heals the nearby most injured ally or herself, assumes heal is ready to be used
function doSorakaHeal()
	-- Find ally champion to heal
	local ally = GetPlayer(player.team, false, true, player, HEAL_RANGE, "health")
	--PrintChat("Ally Champion: "..ally.name)
	-- If no eligible ally, return
	if ally == nil then return end

	-- Heal ally based on healmode
	if config.autoHeal.healMode == 1 then
		if ally.health < ally.maxHealth then
			CastSpell(_W, ally)
		end
	elseif config.autoHeal.healMode == 2 then
		local totalHealAmount = RAW_HEAL_AMOUNT[player:GetSpellData(_W).level] + (RAW_HEAL_RATIO * player.ap)
		totalHealAmount = calcSalvation(totalHealAmount, ally.health, ally.maxHealth)


		if ally.health < (ally.maxHealth - totalHealAmount) then
			CastSpell(_W, ally)
		end
	elseif config.autoHeal.healMode == 3 then
		if (ally.health/ally.maxHealth) < (config.autoHeal.healThreshold / 100) then
			CastSpell(_W, ally)
		end
	end
end

-- Soraka uses ultimate based on user preference
function doSorakaUlt()
	-- Ult based on ultMode
	if config.autoUlt.ultMode == 1 then
		if (player.health/player.maxHealth) < (config.autoUlt.ultThreshold / 100) then
			CastSpell(_R)
		end
	elseif config.autoUlt.ultMode == 2 then
		-- Find nearby ally champion (your lane partner usually) that is fatally injured

		local ally = GetPlayer(player.team, false, true, nil, GLOBAL_RANGE, "health")

		-- Use ult if suitable ally found
		if ally ~= nil and (ally.health/ally.maxHealth) < (config.autoUlt.ultThreshold / 100) then
			CastSpell(_R)
		end
	elseif config.autoUlt.ultMode == 3 then
		--find total hp of team as a percentage, ie team had 40% of their max hp
		local totalMissingHP = 0
		local counter = 0

		for i=1, heroManager.iCount do
			local hero = heroManager:GetHero(i)

			if hero ~= nil and hero.type == "AIHeroClient" and hero.team == player.team and hero.dead == false then --checks for ally and that person is not dead
				totalMissingHP = totalMissingHP + (hero.health/hero.maxHealth)
				counter = counter + 1
			end
		end

		totalMissingHP = totalMissingHP / counter

		if totalMissingHP < (config.autoUlt.ultThreshold / 100) then
			CastSpell(_R)
		end
	end
end

-- Soraka Infuses the most mana deprived ally donating them mana
function doSorakaInfuse()
	-- Find ally champion to infuse
	local ally = GetPlayer(player.team, false, false, player, INFUSE_RANGE, "mana")

	-- Infuse ally based on infuseMode
	if ally ~= nil then
		if config.autoInfuse.infuseMode == 1 then
			if ally.mana < ally.maxMana then
				CastSpell(_E, ally)
			end
		elseif config.autoInfuse.infuseMode == 2 then
			local totalInfuseAmount = RAW_INFUSE_AMOUNT[player:GetSpellData(_E).level] + (RAW_INFUSE_RATIO * player.maxMana)
			totalInfuseAmount = calcSalvation(totalInfuseAmount, ally.mana, ally.maxMana)

			if ally.mana < (ally.maxMana - totalInfuseAmount) then
				CastSpell(_E, ally)
			end
		end
	end
end

-- Soraka silences an enemy if they get in range of infuse
function doSorakaSilence()
	if config.autoSilence.silenceTowerDive == false and UnderTurret(player, true) == true then return end
	-- Find enemy to silence
	local silenceTarget = GetPlayer(TEAM_ENEMY, false, false, player, INFUSE_RANGE, NO_RESOURCE)

	if silenceTarget ~= nil then
		CastSpell(_E, silenceTarget)
	end
end

-- Deny cannon minion farm by healing it 
function doDenyFarm()
	-- Get Cannon Minion
	cannonMinionDeny:update()

	local targetCannonMinion = nil

	for _, minion in pairs(cannonMinionDeny.objects) do
		if minion.dead == false and (minion.charName == "Blue_Minion_MechCannon" or minion.charName == "Red_Minion_MechCannon") then
			targetCannonMinion = minion
		end
	end

	-- If minion found
	if targetCannonMinion ~= nil then

		-- Find Nearby Enemy with highest AD (assumption: adc total AD > support total AD)
		local enemy = GetPlayer(TEAM_ENEMY, false, false, targetCannonMinion, MAX_PLAYER_AA_RANGE, "AD") 

		if enemy ~= nil then
			local enemyDamage = getDmg("AD", targetCannonMinion, enemy)

			-- Heal cannon if in range and may prevent a last hit
			if targetCannonMinion.health < enemyDamage and player:GetDistance(targetCannonMinion) < HEAL_RANGE then
				CastSpell(_W, targetCannonMinion)
			end	
		end
	end

end

-- Steal cannon minion farm by infusing it
-- If no minion is in range or minion dies, will call decideE with true skipSteal so that E can be used for something else
function doStealFarm()
	-- Get Cannon Minion
	cannonMinionSteal:update()

	local targetCannonMinion = nil

	for _, minion in pairs(cannonMinionSteal.objects) do
		if minion.dead == false and (minion.charName == "Blue_Minion_MechCannon" or minion.charName == "Red_Minion_MechCannon") then
			targetCannonMinion = minion
		end
	end

	-- If minion found
	if targetCannonMinion ~= nil then

		-- Check if infuse will do enough damage to steal it
		local infuseDamage = getDmg("E", targetCannonMinion, player)

		-- If target is stealable and in range, infuse it
		if targetCannonMinion.health < infuseDamage and player:GetDistance(targetCannonMinion) < INFUSE_RANGE then
			CastSpell(_E, targetCannonMinion)
		end
	-- If minion is dead or not in range, then use E for something else
	elseif targetCannonMinion == nil or player:GetDistance(targetCannonMinion) > INFUSE_RANGE then
		decideE(true)
	end
end

--[[ Helper Functions ]]--

-- Decides whether to use W to heal or to deny farm
function decideW()
	-- See if there are any allies nearby
	local ally = GetPlayer(player.team, false, true, player, HEAL_RANGE, "health")

	-- If ally or Soraka needs health, then heal them
	if ally ~= nil and (ally.health/ally.maxHealth) < (config.denyStealFarm.denyThreshold / 100) then
		doSorakaHeal()
	else -- Otherwise, deny minion farm
		doDenyFarm()
	end
end

-- Decides whether to use E defensively or use E offensively
function decideE(skipSteal)
	-- See if there are any allies nearby
	local ally = GetPlayer(player.team, false, false, player, INFUSE_RANGE, "mana")

	-- If ally needs mana, then infuse defensively, otherwise steal or silence
	if (ally == nil or (ally.mana/ally.maxMana) > (config.denyStealFarm.stealThreshold / 100)) and config.denyStealFarm.stealEnabled and (skipSteal == nil or skipSteal == false) then
		doStealFarm()
	elseif (ally == nil or (ally.mana/ally.maxMana) > (config.autoSilence.minAllyManaForSilence / 100)) and config.autoSilence.enabled then
		doSorakaSilence()
	elseif ally ~= nil and config.autoInfuse.enabled then
		doSorakaInfuse()
	end

end

-- Returns correct restore amoune due to Soraka's passive
function calcSalvation(totalRestoreAmount, targetCurResource, targetMaxResource)
	local salvationFactor = ((1 - (targetCurResource/targetMaxResource)) / 2) + 1

	return totalRestoreAmount * salvationFactor
end

--[[ Helper Functions ]]--
-- Return player based on their resource or stat
function GetPlayer(team, includeDead, includeSelf, distanceTo, distanceAmount, resource)
	local target = nil

	for i=1, heroManager.iCount do
		local member = heroManager:GetHero(i)

		if member ~= nil and member.type == "AIHeroClient" and member.team == team and (member.dead ~= true or includeDead) then
			if member.charName ~= player.charName or includeSelf then
				if distanceAmount == GLOBAL_RANGE or member:GetDistance(distanceTo) <= distanceAmount then
					if target == nil then target = member end

					if resource == "health" then --least health
						if member.health < target.health then target = member end
					elseif resource == "mana" then --least mana
						if member.mana < target.mana then target = member end
					elseif resource == "AD" then --highest AD
						if member.totalDamage > target.totalDamage then target = member end
					elseif resource == NO_RESOURCE then
						return member -- as any member is eligible
					end
				end
			end
		end
	end

	return target
end

function buy()
	if InFountain() or player.dead then
			-- Item purchases
		if GetTickCount() > lastBuy + buyDelay then
			if GetInventorySlotItem(shopList[nextbuyIndex]) ~= nil then
				--Last Buy successful
				nextbuyIndex = nextbuyIndex + 1
			else
				--Last Buy unsuccessful (buy again)
				--[[local p = CLoLPacket(0x82)
				p.dwArg1 = 1
				p.dwArg2 = 0
				p:EncodeF(myHero.networkID)
				p:Encode4(shopList[nextbuyIndex])
				SendPacket(p)						
				lastBuy = GetTickCount()]]
				lastBuy = GetTickCount()
				BuyItem(shopList[nextbuyIndex])
			end
		end
	end
end

--draws Menu
function drawMenu()
	-- Config Menu
	config = scriptConfig("UnifiedSoraka", "UnifiedSoraka")	

	config:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONOFF, true)
	config:addParam("autoBuy", "Auto Buy Items", SCRIPT_PARAM_ONOFF, true)
	config:addParam("autoLevel", "Auto Level", SCRIPT_PARAM_ONOFF, true)

	config:addSubMenu("Auto Heal", "autoHeal")
	config:addSubMenu("Auto Starcall", "autoStarcall")
	config:addSubMenu("Auto Infuse", "autoInfuse")
	config:addSubMenu("Auto Silence", "autoSilence")
	config:addSubMenu("Auto Ult", "autoUlt")
	config:addSubMenu("Deny/Steal Farm", "denyStealFarm")
	

	config.denyStealFarm:addParam("denyEnabled", "Deny Cannon Minions (W)", SCRIPT_PARAM_ONOFF, false)
	config.denyStealFarm:addParam("stealEnabled", "Steal Cannon Minions (E)", SCRIPT_PARAM_ONOFF, false)
	config.denyStealFarm:addParam("denyThreshold", "Deny Health Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_DENY_THRESHOLD, 0, 100, 0)
	config.denyStealFarm:addParam("stealThreshold", "Steal Mana Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_STEAL_THRESHOLD, 0, 100, 0)
	config.denyStealFarm:addParam("doFarm", "Allow minion attack", SCRIPT_PARAM_ONOFF, false)

	config.autoHeal:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	config.autoHeal:addParam("healMode", "Heal Mode", SCRIPT_PARAM_LIST, DEFAULT_HEAL_MODE, { "Normal", "Smart", "Threshold" })
	config.autoHeal:addParam("healThreshold", "Heal Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_THRESHOLD, 0, 100, 0)

	config.autoStarcall:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	config.autoStarcall:addParam("starcallTowerDive", "Starcall Under Towers", SCRIPT_PARAM_ONOFF, false)
	config.autoStarcall:addParam("starcallMode", "Starcall Mode", SCRIPT_PARAM_LIST, DEFAULT_STARCALL_MODE, { "Harass Only", "Farm/Push", "Both (hit any)", "Both (hit enemy and minions)" })
	config.autoStarcall:addParam("starcallMinMana", "Starcall Minimum Mana", SCRIPT_PARAM_SLICE, DEFAULT_STARCALL_MIN_MANA, 50, 500, 0)
	config.autoStarcall:addParam("numOfHitMinions", "Minimum Hit Minions", SCRIPT_PARAM_SLICE, DEFAULT_NUM_HIT_MINIONS, 1, 10, 0)

	config.autoInfuse:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	config.autoInfuse:addParam("infuseMode", "Infuse Mode", SCRIPT_PARAM_LIST, DEFAULT_INFUSE_MODE, { "Normal", "Smart"})

	config.autoSilence:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	config.autoSilence:addParam("silenceTowerDive", "Silence Under Towers", SCRIPT_PARAM_ONOFF, false)
	config.autoSilence:addParam("minAllyManaForSilence", "Min Ally Mana for Silence (%)", SCRIPT_PARAM_SLICE, DEFAULT_MIN_ALLY_SILENCE, 0, 100, 0)

	config.autoUlt:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	config.autoUlt:addParam("ultMode", "Ultimate Mode", SCRIPT_PARAM_LIST, DEFAULT_ULT_MODE, { "Selfish", "Lane Partner", "Entire Team" })
	config.autoUlt:addParam("ultThreshold", "Ult Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_ULT_THRESHOLD, 0, 100, 0)

	-- Setup minion manager
	enemyMinions = minionManager(MINION_ENEMY, STARCALL_RANGE, player, MINION_SORT_HEALTH_ASC) -- for starcall

	cannonMinionDeny = minionManager(MINION_ALLY, HEAL_RANGE, player, MINION_SORT_MAXHEALTH_DEC) -- for deny farm
	cannonMinionSteal = minionManager(MINION_ENEMY, INFUSE_RANGE, player, MINION_SORT_MAXHEALTH_DEC) -- for steal farm
end

function OnProcessSpell(unit,spell)
	if config.denyStealFarm.doFarm	 == true and unit.name == player.name and spell.name:lower():find("attack") ~= nil then
		if(spell.target.name:lower():find("minion")~=nil) then	player:HoldPosition() end
	end
end

-- obCreatObj
function OnCreateObj(obj)
	-- Check if player is recalling and set isrecalling
	if obj.name:find("TeleportHome") then
		if GetDistance(player, obj) <= 70 then
			isRecalling = true
		end
	end
end

-- OnDeleteObj
function OnDeleteObj(obj)
	if obj.name:find("TeleportHome") then
		-- Set isRecalling off after short delay to prevent using abilities once at base
		DelayAction(function() isRecalling = false end, RECALL_DELAY)
	end
end

--[[ OnTick ]]--
function OnTick()
	-- Check if script should be run
	if not config.enableScript then return end

	-- Auto Level
	if config.autoLevel and player.level > GetHeroLeveled() then
		--PrintChat("Trying to upgrade spell")
		--Packet('0x39', {networkId = myHero.networkID, spellId = SPELL_1, level = 1, remainingLevelPoints = 1}):send()
		LevelSpell(levelSequence[GetHeroLeveled() + 1])
		--LevelSpell(SPELL_1)
	end

	-- Recall Check
	if (isRecalling) then
		return -- Don't perform recall canceling actions
	end

	-- Auto Ult (R)
	if config.autoUlt.enabled and player:CanUseSpell(_R) == READY then
		doSorakaUlt()
	end

	if config.autoBuy then buy() end 

	-- Only perform following tasks if not in fountain 
	if not InFountain() then
		-- Auto Heal and Deny Farm (W)
		if player:CanUseSpell(_W) == READY then
			if config.autoHeal.enabled and not config.denyStealFarm.denyEnabled then
				doSorakaHeal()
			elseif not config.autoHeal.enabled and config.denyStealFarm.denyEnabled then
				doDenyFarm()
			elseif config.autoHeal.enabled and config.denyStealFarm.denyEnabled then
				decideW()
			end
		end

		-- Auto Infuse Ally and Auto Silence Enemy (E)
		if player:CanUseSpell(_E) == READY then
			-- If at least one E option is enabled, decide E
			if not (not config.autoInfuse.enabled and not config.autoSilence.enabled and not config.denyStealFarm.stealEnabled) then
				decideE()
			end
		end

		-- Auto StarCall (Q)
		if config.autoStarcall.enabled and player:CanUseSpell(_Q) == READY and player.mana > config.autoStarcall.starcallMinMana then
			doSorakaStarcall()
		end
	end
end

function OnLoad()
	player = GetMyHero()
	drawMenu()
	startingTime = GetTickCount()

	if AutoUpdate then
		Update()
	end
end
