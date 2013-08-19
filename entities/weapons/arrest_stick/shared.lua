if SERVER then
	AddCSLuaFile("shared.lua")
	util.AddNetworkString("ArrestBatonColour")
end

if CLIENT then
	SWEP.PrintName = "Arrest Baton"
	SWEP.Slot = 1
	SWEP.SlotPos = 3
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Base = "weapon_cs_base2"

SWEP.Author = "DarkRP Developers"
SWEP.Instructions = "Left or right click to arrest"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.IconLetter = ""

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "stunstick"

SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.Category = "DarkRP (Utility)"

SWEP.NextStrike = 0

SWEP.ViewModel = Model("models/weapons/v_stunbaton.mdl")
SWEP.WorldModel = Model("models/weapons/w_stunbaton.mdl")

SWEP.Sound = Sound("weapons/stunstick/stunstick_swing1.wav")

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:Initialize()
	self:NewSetWeaponHoldType("normal")
end

function SWEP:Deploy()
	if CLIENT or not IsValid(self:GetOwner()) then return end
	self:SetColor(Color(255,0,0,255))
	self:SetMaterial("models/shiny")
	net.Start("ArrestBatonColour")
		net.WriteUInt(255,8)
		net.WriteUInt(0,8)
		net.WriteUInt(0,8)
		net.WriteString("models/shiny")
	net.Send(self:GetOwner())
	return true
end

function SWEP:Holster()
	if CLIENT or not IsValid(self:GetOwner()) then return end
	net.Start("ArrestBatonColour")
		net.WriteUInt(255,8)
		net.WriteUInt(255,8)
		net.WriteUInt(255,8)
		net.WriteString("")
	net.Send(self:GetOwner())
	return true
end

function SWEP:OnRemove()
	if SERVER and IsValid(self:GetOwner()) then
		net.Start("ArrestBatonColour")
			net.WriteUInt(255,8)
			net.WriteUInt(255,8)
			net.WriteUInt(255,8)
			net.WriteString("")
		net.Send(self:GetOwner())
	end
end

net.Receive("ArrestBatonColour", function()
	local viewmodel = LocalPlayer():GetViewModel()
	local r,g,b,a = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), 255
	viewmodel:SetColor(Color(r,g,b,a))
	viewmodel:SetMaterial(net.ReadString())
end)

function SWEP:PrimaryAttack()
	if CurTime() < self.NextStrike then return end

	self:NewSetWeaponHoldType("melee")
	timer.Simple(0.3, function() if self:IsValid() then self:NewSetWeaponHoldType("normal") end end)

	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Weapon:EmitSound(self.Sound)
	self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)

	self.NextStrike = CurTime() + .4

	if CLIENT then return end

	local ent = self.Owner:getEyeSightHitEntity()
	if not ent then return end

	if IsValid(ent) and ent:IsPlayer() and ent:isCP() and not GAMEMODE.Config.cpcanarrestcp then
		DarkRP.notify(self.Owner, 1, 5, DarkRP.getPhrase("cant_arrest_other_cp"))
		return
	end

	if ent:GetClass() == "prop_ragdoll" then
		for k,v in pairs(player.GetAll()) do
			if ent.OwnerINT and ent.OwnerINT == v:EntIndex() and GAMEMODE.KnockoutToggle then
				DarkRP.toggleSleep(v, true)
				return
			end
		end
	end

	if not IsValid(ent) or (self.Owner:EyePos():Distance(ent:GetPos()) > 115) or (not ent:IsPlayer() and not ent:IsNPC()) then
		return
	end

	if not GAMEMODE.Config.npcarrest and ent:IsNPC() then
		return
	end

	if GAMEMODE.Config.needwantedforarrest and not ent:IsNPC() and not ent:getDarkRPVar("wanted") then
		DarkRP.notify(self.Owner, 1, 5, DarkRP.getPhrase("must_be_wanted_for_arrest"))
		return
	end

	if FAdmin and ent:IsPlayer() and ent:FAdmin_GetGlobal("fadmin_jailed") then
		DarkRP.notify(self.Owner, 1, 5, DarkRP.getPhrase("cant_arrest_fadmin_jailed"))
		return
	end

	local jpc = DarkRP.jailPosCount()

	if not jpc or jpc == 0 then
		DarkRP.notify(self.Owner, 1, 4, DarkRP.getPhrase("cant_arrest_no_jail_pos"))
	else
		-- Send NPCs to Jail
		if ent:IsNPC() then
			ent:SetPos(DarkRP.retrieveJailPos())
		else
			if not ent.Babygod then
				ent:arrest(nil, self.Owner)
				DarkRP.notify(ent, 0, 20, DarkRP.getPhrase("youre_arrested_by", self.Owner:Nick()))

				if self.Owner.SteamName then
					DarkRP.log(self.Owner:Nick().." ("..self.Owner:SteamID()..") arrested "..ent:Nick(), Color(0, 255, 255))
				end
			else
				DarkRP.notify(self.Owner, 1, 4, DarkRP.getPhrase("cant_arrest_spawning_players"))
			end
		end
	end
end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	if self.Owner:HasWeapon("unarrest_stick") then
		self.Owner:SelectWeapon("unarrest_stick")
	end
end
