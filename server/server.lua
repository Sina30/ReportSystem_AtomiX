

Config.Webhook = "YOUR_DISCORD_WEBHOOK_HERE"--Your webhook if you want to recieve the reports in discord too

local ReportList = {}
local staffs = {}
local onesync = false
ESX = nil
Citizen.CreateThread(function()
	if GetConvar("onesync") ~= "off" then
		onesync = true
	end
	if Config.ESX then
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj; end)
	end
end)

RegisterNetEvent("ReportSystemGEj:NewReport")
AddEventHandler("ReportSystemGEj:NewReport", function(data)
	local _source = source
	local newreport = {
		id = #ReportList+1,
		playername = GetPlayerName(_source),
		title = data.title,
		description = data.description,
		solved = false,
		screenshotLink = data.url,
		playerid = _source
	}
	ReportList[#ReportList+1] = newreport
	TriggerClientEvent("ReportSystemGEj:AddToList",-1,newreport)
	if Config.Webhook then
		if Config.Webhook ~= "" and Config.Webhook ~= "YOUR_WEB_HOOK_HERE" then
			SendWebhook(newreport)
		end
	end
end)

RegisterNetEvent("ReportSystemGEj:GetReports")
AddEventHandler("ReportSystemGEj:GetReports", function()
	local _source = source
	local admin = IsAdmin(_source)
	if admin then
		staffs[_source] = true
		TriggerClientEvent("ReportSystemGEj:GetReports",_source,ReportList,onesync,admin)
	end
end)

RegisterNetEvent("ReportSystemGEj:TeleportReport")
AddEventHandler("ReportSystemGEj:TeleportReport", function(kindaid,doit)
	local _source = source
	if staffs[_source] then
		if doit then
			local id = ReportList[kindaid].playerid
			if GetPlayerPing(id) > 0 then
				local player = id
				local pedl = GetPlayerPed(player)
				local pcoords = GetEntityCoords(pedl)
				local ped = GetPlayerPed(_source)
				SetEntityCoords(ped,pcoords.x,pcoords.y,pcoords.z)
			else
				if Config.ESX then
					TriggerClientEvent('esx:showNotification', _source, "~r~ That player is no longer in the server!")
				else
					--your notification system
				end
			end
			if not ReportList[kindaid].solved then
				ReportList[kindaid].solved = "kinda"
			end
			TriggerClientEvent("ReportSystemGEj:ReportSolved",-1,kindaid,ReportList[kindaid].solved)
		end
	else
		print("cheater cheater, pumpkin eater... id: ".._source)
	end
end)

RegisterNetEvent("ReportSystemGEj:ReportSolved")
AddEventHandler("ReportSystemGEj:ReportSolved", function(id,can)
	local _source = source
	if staffs[_source] then
		local report = ReportList[id]
		if report then
			if report.solved ~= true or can then
				if can then
					if ReportList[id].solved == true then
						ReportList[id].solved = false
					else
						ReportList[id].solved = true
					end
				else
					ReportList[id].solved = true
				end
				TriggerClientEvent("ReportSystemGEj:ReportSolved",-1,id,ReportList[id].solved)
			end
		end
	else
		print("cheater cheater, pumpkin eater... id: ".._source)
	end
end)

function IsAdmin(id)
	local autorizado = false
	if Config.ESX then
		local xPlayer = ESX.GetPlayerFromId(id)
		local grupo = xPlayer.getGroup()
		if grupo ~= "user" and grupo ~= "vip" and grupo ~= "donator" then
			autorizado = true
		end
	else
		for k,v in pairs(GetPlayerIdentifiers(id))do	
			for i=1, #Config.Admins do
				if v == Config.Admins[i] then
					autorizado = true
				end
			end
		end
	end
	return autorizado
end

function SendWebhook(data)
	local embeds = {
        {
            ["title"]="New Report",
            ["type"]="rich",
            ["color"] = 1770588,
            ["image"] = {url = data.screenshotLink},
            ["footer"]=  {
                ["text"]= data.playername.." ("..data.playerid..")",
            },
			["fields"] = {
				{
					name = "Title:",
					value = data.title,
				},
				{
					name = "Description:",
					value = data.description,
				},
            }
        }
    }

    -- if message == nil or message == '' then return FALSE end
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end