local ReportList = {}
local onesync = false
local admin = false
ESX = nil
Citizen.CreateThread(function()
	Wait(1000)
	TriggerServerEvent("ReportSystemGEj:GetReports")
	if Config.ESX then
		while ESX == nil do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
			Citizen.Wait(10)
		end
	end
end)

if Config.ReportCommand then
	if Config.ReportCommand ~= "" then
		RegisterCommand(Config.ReportCommand, function(source, args, rawCommand)
			ReportNUI(false)
		end, false)
	end
end

if Config.ReportListCommand then
	if Config.ReportListCommand ~= "" then
		RegisterCommand(Config.ReportListCommand, function(source, args, rawCommand)
			if admin then
				ReportNUI(true)
			end
		end, false)
	end
end

function OpenReport()
	ReportNUI(false)
end

function OpenReportList()
	ReportNUI(true)
end

exports('ReportList', OpenReportList)

exports('Report', OpenReport)

function ReportNUI(bool)
	SetNuiFocus(true, true)
	if bool then
		SendNUIMessage({
			action = "updateReportList",
			reportList = ReportList
		})
		SendNUIMessage({
			action = "openReportList",
		})
	else
		SendNUIMessage({
			action = "startReportForm",
		})
	end
end

RegisterNUICallback("action", function(data)
	local action = data.action
	if action ~= "solvedreport" then
		SetNuiFocus(false, false)
	end
	if action == "createNewReport" then
		local url = true
		if Config.TakeScreenshot then
			if Config.TakeScreenshot ~= "" and Config.TakeScreenshot ~= "YOUR_DISCORD_WEBHOOK_HERE" then
				url = false
				exports['screenshot-basic']:requestScreenshotUpload(Config.TakeScreenshot, "files[]", function(data)
					local image = json.decode(data)
					url = image.attachments[1].url
				end)
			end
		end
		while not url do
			Wait(10)
		end
		if type(url) ~= "string" then
			url = ""
		end
		local list = {title=data.title,description=data.description,url=url}
		TriggerServerEvent("ReportSystemGEj:NewReport",list)
	elseif action == "gotoplayer" then
		if ReportList[data.id] then
			if onesync then
				TriggerServerEvent("ReportSystemGEj:TeleportReport",data.id,true)
			else
				local id = ReportList[data.id].playerid
				local playerIdx = GetPlayerFromServerId(id)
				local active = NetworkIsPlayerActive(playerIdx)
				if active then
					SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(id))))
					TriggerServerEvent("ReportSystemGEj:TeleportReport",id)
				else
					if Config.ESX then
						ESX.ShowNotification("~r~ That player is no longer in the server!")
					else
						--your notification system
					end
				end
			end
		end
	elseif action == "solvedreport" then
		local id = data.id
		local can = data.can
		local reportinfo = ReportList[id]
		if reportinfo then
			if reportinfo.solved ~= true or can then
				TriggerServerEvent("ReportSystemGEj:ReportSolved",id,can)
			end
		end
	end
end)

RegisterNetEvent('ReportSystemGEj:ReportSolved')
AddEventHandler('ReportSystemGEj:ReportSolved', function(id,more)
	local report = ReportList[id]
	--if report and report.solved ~= true then
		ReportList[id].solved = more
		SendNUIMessage({
			action = "updateReportList",
			reportList = ReportList
		})
	--end
end)

RegisterNetEvent('ReportSystemGEj:GetReports')
AddEventHandler('ReportSystemGEj:GetReports', function(reports,osync,staff)
	admin = staff
	ReportList = reports
	onesync = osync
end)

RegisterNetEvent('ReportSystemGEj:AddToList')
AddEventHandler('ReportSystemGEj:AddToList', function(newreport)
	if admin then
		SendNUIMessage({
			action = "notification",
		})
		ReportList[#ReportList+1] = newreport
		SendNUIMessage({
			action = "updateReportList",
			reportList = ReportList
		})
	end
end)