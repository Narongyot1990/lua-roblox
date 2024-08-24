--[[
เริ่มต้นโดยเรียกใช้ ReplicatedStorage , Players รวมถึงการกำหนดตัวแปร player สำหรับผู้เล่น LocalPlayer

มีการอ้างอิงถึงส่วนประกอบต่างๆ ของ GUI (ExpGui, ExpBarFrame, expLabel, levelLabel) ที่ใช้ในการแสดงผล EXP และเลเวลของผู้เล่น

มีการรับค่า RemoteEvent (EXPUpdateEvent) จาก ReplicatedStorage เพื่ออัปเดตข้อมูลของผู้เล่น

ฟังก์ชัน addGradientToProgressBar ใช้ในการเพิ่มเอฟเฟกต์สีไล่เฉด (UIGradient) ให้กับ Progress Bar โดยไล่สีจากฟ้าเป็นเขียว และสุดท้ายเป็นเหลือง

ฟังก์ชัน updateProgressBarGui ใช้ในการอัปเดตขนาดของ Progress Bar ตามค่าเปอร์เซ็นต์ที่คำนวณจาก EXP ของผู้เล่น พร้อมทั้งอัปเดตข้อความที่แสดง EXP และเลเวลของผู้เล่นบน GUI

ฟังก์ชัน updateProgressFromEXP ใช้ในการอัปเดต Progress Bar โดยดึงค่า EXP ปัจจุบัน เลเวลปัจจุบัน EXP ที่ต้องการสำหรับเลเวลถัดไป และ EXP ที่ต้องการสำหรับเลเวลก่อนหน้า จาก Attribute ของผู้เล่น

ฟังก์ชันที่เชื่อมต่อกับ OnClientEvent จะทำการอัปเดตค่า EXP และเลเวลของผู้เล่นใน Attributes จากนั้นจะเรียกฟังก์ชัน updateProgressFromEXP เพื่ออัปเดต Progress Bar

ฟังก์ชัน addGradientToProgressBar ถูกเรียกใช้ทันทีหลังจากการกำหนด ExpBarFrame เพื่อเพิ่มสีไล่เฉดให้กับ Progress Bar

หากมีข้อมูลเริ่มต้นที่ต้องการแสดงเมื่อสคริปต์เริ่มทำงาน (เช่นค่า EXP และ NextLevelEXP ของผู้เล่น) ฟังก์ชัน updateProgressFromEXP จะถูกเรียกใช้เพื่ออัปเดต GUI ทันที
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ExpGui = script.Parent
local ExpBarFrame = ExpGui.Frame:WaitForChild("ExpBarFrame")
local expLabel = ExpGui:WaitForChild("expLabel")
local levelLabel = ExpGui:WaitForChild("levelLabel")

-- รับ RemoteEvent
local expUpdateEvent = ReplicatedStorage:WaitForChild("EXPUpdateEvent")

-- เพิ่ม UIGradient ให้กับ Progress Bar
local function addGradientToProgressBar(frame)
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 127)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 223, 0))
	})
	uiGradient.Parent = frame
end

-- ฟังก์ชันสำหรับการอัปเดต Progress Bar และเลเวล
local function updateProgressBarGui(percentage, level, currentEXP, nextLevelEXP)
	if not ExpBarFrame or not expLabel or not levelLabel then
		warn("GUI elements are missing.")
		return 
	end

	-- จำกัดค่า percentage ระหว่าง 0 ถึง 100
	percentage = math.clamp(percentage, 0, 100)
	ExpBarFrame.Size = UDim2.new(percentage / 100, 0, 1, 0) -- ขนาดของ Frame จะเปลี่ยนแปลงตาม percentage
	local expText = string.format("%d/%d", currentEXP, nextLevelEXP)  -- แสดง EXP ที่ได้รับและ EXP ที่ต้องการ
	expLabel.Text = expText
	levelLabel.Text = string.format("Lv. %d", level)
end

-- ฟังก์ชันสำหรับการอัปเดต Progress Bar จาก EXP ของผู้เล่น
local function updateProgressFromEXP()
	local currentEXP = player:GetAttribute("EXP")
	local currentLevel = player:GetAttribute("Level")
	local nextLevelEXP = player:GetAttribute("NextLevelEXP")
	local previousLevelEXP = player:GetAttribute("PreviousLevelEXP")

	if currentEXP and nextLevelEXP and previousLevelEXP then
		--print(currentEXP, currentLevel, nextLevelEXP, previousLevelEXP)
		local progressPercentage = ((currentEXP - previousLevelEXP) / (nextLevelEXP - previousLevelEXP)) * 100
		updateProgressBarGui(progressPercentage, currentLevel, currentEXP, nextLevelEXP)
	else
		warn("nextLevelEXP, currentEXP, or previousLevelEXP is nil. Cannot update progress.")
	end
end

-- รับข้อมูลจาก RemoteEvent และอัปเดต Progress Bar
expUpdateEvent.OnClientEvent:Connect(function(currentEXP, currentLevel, nextLevelEXP, previousLevelEXP)
	-- ตรวจสอบให้แน่ใจว่าค่าไม่เป็น nil ก่อนบันทึกลงใน Attributes
	if currentEXP and currentLevel and nextLevelEXP and previousLevelEXP then
		-- อัปเดตค่า Attributes ในผู้เล่นก่อน
		player:SetAttribute("EXP", currentEXP)
		player:SetAttribute("Level", currentLevel)
		player:SetAttribute("NextLevelEXP", nextLevelEXP)
		player:SetAttribute("PreviousLevelEXP", previousLevelEXP)

		-- จากนั้นอัปเดต Progress Bar
		updateProgressFromEXP()
	else
		warn("Received nil data from server.")
	end
end)

-- เพิ่มสีไล่เฉดให้กับ Progress Bar
addGradientToProgressBar(ExpBarFrame)

-- อัปเดต GUI ครั้งแรกเมื่อสคริปต์เริ่มต้น (หากมีข้อมูลเริ่มต้นที่ต้องการแสดง)
if player:GetAttribute("EXP") and player:GetAttribute("NextLevelEXP") then
	updateProgressFromEXP()
end
