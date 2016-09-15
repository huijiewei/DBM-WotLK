local mod	= DBM:NewMod(610, "DBM-Party-WotLK", 15, 278)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision$"):sub(12, -3))
mod:SetCreatureID(36658, 36661)
mod:SetEncounterID(837, 838, 2000)
mod:DisableESCombatDetection()
mod:SetMinSyncRevision(105)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 69167",
	"SPELL_CAST_SUCCESS 69155",
	"SPELL_AURA_APPLIED 69172",
	"SPELL_PERIODIC_DAMAGE 69238",
	"SPELL_PERIODIC_MISSED 69238",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_DIED"
)

local warnForcefulSmash			= mod:NewSpellAnnounce(69155, 2, nil, "Tank")
local warnOverlordsBrand		= mod:NewTargetAnnounce(69172, 4)
local warnHoarfrost				= mod:NewTargetAnnounce(69246, 2)

local specWarnHoarfrost			= mod:NewSpecialWarningMoveAway(69246)
local yellHoarfrost				= mod:NewYell(69246)
local specWarnHoarfrostNear		= mod:NewSpecialWarningClose(69246)
local specWarnIcyBlast			= mod:NewSpecialWarningMove(69238)
local specWarnOverlordsBrand	= mod:NewSpecialWarningReflect(69172, nil, nil, nil, 3)
local specWarnUnholyPower		= mod:NewSpecialWarningSpell(69167, "Tank")--Spell for now. may change to run away if damage is too high for defensive

local timerCombatStart			= mod:NewCombatTimer(31)
local timerOverlordsBrandCD		= mod:NewCDTimer(12, 69172, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerOverlordsBrand		= mod:NewBuffFadesTimer(8, 69172)
local timerUnholyPower			= mod:NewBuffActiveTimer(10, 69167, nil, "Tank|Healer", 2, 5)
local timerHoarfrostCD			= mod:NewCDTimer(25.5, 69246, nil, nil, nil, 3)
local timerForcefulSmash		= mod:NewCDTimer(40, 69155, nil, "Tank", 2, 5, nil, DBM_CORE_TANK_ICON)--Highly Variable. 40-50

mod:AddBoolOption("SetIconOnHoarfrostTarget", true)
mod:AddRangeFrameOption(8, 69246)

function mod:OnCombatStart(delay)
	timerForcefulSmash:Start(9-delay)--Sems like a WTF
	timerOverlordsBrandCD:Start(-delay)
	timerHoarfrostCD:Start(31.5-delay)--Verify
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 69167 then					-- Unholy Power
        specWarnUnholyPower:Show()
		timerUnholyPower:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 69155 then					-- Forceful Smash
        warnForcefulSmash:Show()
        timerForcefulSmash:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 69172 then							-- Overlord's Brand
		timerOverlordsBrandCD:Start()
		if args:IsPlayer() then
			specWarnOverlordsBrand:Show(args.sourceName)
			timerOverlordsBrand:Start()
		else
			warnOverlordsBrand:Show(args.destName)
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 69238 and destGUID == UnitGUID("player") and self:AntiSpam() then		-- Icy Blast, MOVE!
		specWarnIcyBlast:Show()
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_DIED(args)
	if self:GetCIDFromGUID(args.destGUID) == 36658 then
		DBM:EndCombat(self)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if msg == L.HoarfrostTarget or msg:find(L.HoarfrostTarget) then--Probably don't need this, verify
		if not target then return end
		timerHoarfrostCD:Start()
		local target = DBM:GetUnitFullName(target)
		if target == UnitName("player") then
			specWarnHoarfrost:Show()
			yellHoarfrost:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(8, nil, nil, nil, nil, 5)
			end
		elseif self:CheckNearby(8, target) then
			specWarnHoarfrostNear:Show(target)
		else
			warnHoarfrost:Show(target)
		end
		if self.Options.SetIconOnHoarfrostTarget then
			self:SetIcon(target, 8, 5)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.CombatStart or msg == L.CombatStart) then
		timerCombatStart:Start()
	end
end
