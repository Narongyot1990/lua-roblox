--[[
เริ่มต้นโดยเรียกใช้บริการ DataStoreService และ Players จากเกม รวมถึงการสร้าง DataStore สำหรับเก็บข้อมูล EXP ของผู้เล่น และเรียกใช้อีเวนต์ที่ใช้ในการอัปเดต EXP (EXPUpdateEvent)

ฟังก์ชัน calculateLevel ใช้ในการคำนวณเลเวลของผู้เล่นจากค่า EXP ที่ได้รับ โดยมีการกำหนดระดับเลเวลและ EXP ที่ต้องการสำหรับการไปถึงเลเวลถัดไป

ฟังก์ชัน loadPlayerData ใช้ในการโหลดข้อมูล EXP และเลเวลของผู้เล่นเมื่อเข้ามาในเกม มีการพยายามโหลดข้อมูลหลายครั้ง (สูงสุด 5 ครั้ง) หากล้มเหลวจะเตะผู้เล่นออกจากเกม หากสำเร็จข้อมูล EXP และเลเวลจะถูกตั้งค่าให้กับผู้เล่นพร้อมทั้งส่งข้อมูลไปยังไคลเอนต์

ฟังก์ชัน savePlayerData ใช้ในการบันทึกข้อมูล EXP และเลเวลของผู้เล่นเมื่อออกจากเกม หากการบันทึกล้มเหลวจะมีการแสดงคำเตือน

โค้ดจะตรวจจับการเปลี่ยนแปลงของค่า EXP และทำการคำนวณเลเวลใหม่เมื่อค่า EXP เปลี่ยนแปลง จากนั้นส่งข้อมูลอัปเดตไปยังไคลเอนต์

สุดท้ายโค้ดจะบันทึกข้อมูลของผู้เล่นเมื่อผู้เล่นออกจากเกมโดยเรียกใช้ savePlayerData
]]


local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local expDataStore = DataStoreService:GetDataStore("PlayerEXP")
local expUpdateEvent = game.ReplicatedStorage:WaitForChild("EXPUpdateEvent")

-- ฟังก์ชันสำหรับการคำนวณเลเวลจาก EXP
local function calculateLevel(exp)
	local level = 1
	local nextLevelEXP = 100
	local previousLevelEXP = 0

	-- กำหนดค่าเลเวลและ EXP สำหรับเลเวลถัดไป
	if exp >= 3000 then
		level = 25
		previousLevelEXP = 3000
		nextLevelEXP = 3200
	elseif exp >= 2800 then
		level = 24
		previousLevelEXP = 2800
		nextLevelEXP = 3000
	elseif exp >= 2600 then
		level = 23
		previousLevelEXP = 2600
		nextLevelEXP = 2800
	elseif exp >= 2400 then
		level = 22
		previousLevelEXP = 2400
		nextLevelEXP = 2600
	elseif exp >= 2200 then
		level = 21
		previousLevelEXP = 2200
		nextLevelEXP = 2400
	elseif exp >= 2000 then
		level = 20
		previousLevelEXP = 2000
		nextLevelEXP = 2200
	elseif exp >= 1800 then
		level = 19
		previousLevelEXP = 1800
		nextLevelEXP = 2000
	elseif exp >= 1600 then
		level = 18
		previousLevelEXP = 1600
		nextLevelEXP = 1800
	elseif exp >= 1400 then
		level = 17
		previousLevelEXP = 1400
		nextLevelEXP = 1600
	elseif exp >= 1200 then
		level = 16
		previousLevelEXP = 1200
		nextLevelEXP = 1400
	elseif exp >= 1000 then
		level = 15
		previousLevelEXP = 1000
		nextLevelEXP = 1200
	elseif exp >= 900 then
		level = 14
		previousLevelEXP = 900
		nextLevelEXP = 1000
	elseif exp >= 800 then
		level = 13
		previousLevelEXP = 800
		nextLevelEXP = 900
	elseif exp >= 700 then
		level = 12
		previousLevelEXP = 700
		nextLevelEXP = 800
	elseif exp >= 600 then
		level = 11
		previousLevelEXP = 600
		nextLevelEXP = 700
	elseif exp >= 500 then
		level = 10
		previousLevelEXP = 500
		nextLevelEXP = 600
	elseif exp >= 400 then
		level = 9
		previousLevelEXP = 400
		nextLevelEXP = 500
	elseif exp >= 300 then
		level = 8
		previousLevelEXP = 300
		nextLevelEXP = 400
	elseif exp >= 200 then
		level = 7
		previousLevelEXP = 200
		nextLevelEXP = 300
	elseif exp >= 100 then
		level = 6
		previousLevelEXP = 100
		nextLevelEXP = 200
	elseif exp >= 75 then
		level = 5
		previousLevelEXP = 75
		nextLevelEXP = 100
	elseif exp >= 50 then
		level = 4
		previousLevelEXP = 50
		nextLevelEXP = 75
	elseif exp >= 25 then
		level = 3
		previousLevelEXP = 25
		nextLevelEXP = 50
	elseif exp >= 10 then
		level = 2
		previousLevelEXP = 10
		nextLevelEXP = 25
	else
		level = 1
		previousLevelEXP = 0
		nextLevelEXP = 10
	end

	return level, nextLevelEXP, previousLevelEXP
end

-- ฟังก์ชันสำหรับการโหลดข้อมูล EXP และเลเวลเมื่อผู้เล่นเข้ามาในเกม
local function loadPlayerData(player)
	local maxRetries = 5  -- จำนวนครั้งสูงสุดที่พยายามโหลดข้อมูล
	local retryDelay = 2  -- หน่วงเวลา (วินาที) ระหว่างการพยายามแต่ละครั้ง

	for attempt = 1, maxRetries do
		local success, data = pcall(function()
			return expDataStore:GetAsync(player.UserId)
		end)

		if success then
			if data then
				local exp = data.exp or 0
				local level, nextLevelEXP, previousLevelEXP = calculateLevel(exp)
				player:SetAttribute("EXP", exp)
				player:SetAttribute("Level", level)
				player:SetAttribute("NextLevelEXP", nextLevelEXP)
				player:SetAttribute("PreviousLevelEXP", previousLevelEXP)
				-- ส่งข้อมูลไปยังไคลเอนต์
				expUpdateEvent:FireClient(player, exp, level, nextLevelEXP, previousLevelEXP)
				-- ออกจากฟังก์ชันทันทีเมื่อโหลดสำเร็จ
				return 
			else
				player:SetAttribute("EXP", 0)
				player:SetAttribute("Level", 1)
				player:SetAttribute("NextLevelEXP", 100)
				player:SetAttribute("PreviousLevelEXP", 0)
				expUpdateEvent:FireClient(player, 0, 1, 100, 0)
				return -- ออกจากฟังก์ชันเมื่อพบว่าเป็นผู้เล่นใหม่
			end
		else
			warn("Attempt " .. attempt .. " failed to load player data: " .. data)
			wait(retryDelay)  -- รอเวลาระหว่างการพยายามแต่ละครั้ง
		end
	end

	-- หากพยายามครบทุกครั้งแล้วยังไม่สำเร็จ ให้เตะผู้เล่นออกจากเกม
	player:Kick("Failed to load your data. Please try again later.")
end

-- ฟังก์ชันสำหรับการบันทึกข้อมูล EXP และเลเวลเมื่อผู้เล่นออกจากเกม
local function savePlayerData(player)
	local exp = player:GetAttribute("EXP") or 0
	local level = player:GetAttribute("Level") or 1
	local data = {
		exp = exp,
		level = level
	}

	local success, err = pcall(function()
		expDataStore:SetAsync(player.UserId, data)
	end)

	if not success then
		warn("Could not save player data: " .. err)
	else
		--print(string.format("Player %s saved: EXP = %d, Level = %d", player.Name, exp, level))
	end
end

-- ตรวจจับการเปลี่ยนแปลงของ Attribute EXP และประมวลผลเมื่อมีการเปลี่ยนแปลง
Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)

	player:GetAttributeChangedSignal("EXP"):Connect(function()
		local currentEXP = player:GetAttribute("EXP")
		local level, nextLevelEXP, previousLevelEXP = calculateLevel(currentEXP)

		player:SetAttribute("Level", level)
		player:SetAttribute("NextLevelEXP", nextLevelEXP)
		player:SetAttribute("PreviousLevelEXP", previousLevelEXP)

		expUpdateEvent:FireClient(player, currentEXP, level, nextLevelEXP, previousLevelEXP)
		--print("EXP changed, recalculated level and fired client update:", currentEXP, level, nextLevelEXP, previousLevelEXP)
	end)
end)

-- เมื่อผู้เล่นออกจากเกม
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)
