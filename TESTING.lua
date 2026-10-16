-- [[ Accurate Roblox Gravity Coil (Fully Fixed & Organized) ]] --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình thông số
local TOOL_NAME = "Gravity Coil"
local GEAR_ID = 16688968              -- ID mô hình gốc của Gravity Coil
local BOING_SOUND_ID = "rbxassetid://16619553" -- ID âm thanh Boing chính xác
local JUMP_POWER = 101
local DEFAULT_JUMP_POWER = 50
local FALL_FORCE = 0.5

-- Biến lưu trạng thái kết nối
local characterConnection
local fallConnection
local fallForce
local fallAttachment
local jumpConnection

-- Lấy Humanoid của nhân vật hiện tại
local function getHumanoid()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

-- Thiết lập độ cao khi nhảy
local function setJumpPower(value)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = value
    end
end

-- Xóa bỏ hiệu ứng giảm tốc độ rơi
local function disableLightFall()
    if fallConnection then
        fallConnection:Disconnect()
        fallConnection = nil
    end
    if fallForce then
        fallForce:Destroy()
        fallForce = nil
    end
    if fallAttachment then
        fallAttachment:Destroy()
        fallAttachment = nil
    end
end

-- Kích hoạt hiệu ứng giảm tốc độ rơi khi ngã
local function enableLightFall()
    local character = LocalPlayer.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    disableLightFall()

    fallAttachment = Instance.new("Attachment")
    fallAttachment.Name = "GravityCoilFallAttachment"
    fallAttachment.Parent = rootPart

    fallForce = Instance.new("VectorForce")
    fallForce.Name = "GravityCoilFallForce"
    fallForce.Attachment0 = fallAttachment
    fallForce.RelativeTo = Enum.ActuatorRelativeTo.World
    fallForce.ApplyAtCenterOfMass = true
    fallForce.Parent = rootPart

    fallConnection = RunService.Heartbeat:Connect(function()
        if not rootPart or not rootPart.Parent or not fallForce then
            disableLightFall()
            return
        end

        local velocity = rootPart.AssemblyLinearVelocity
        if velocity.Y < 0 then
            fallForce.Force = Vector3.new(
                0,
                rootPart.AssemblyMass * workspace.Gravity * FALL_FORCE,
                0
            )
        else
            fallForce.Force = Vector3.zero
        end
    end)
end

-- Hàm khởi tạo và cấp phát Gravity Coil cho người chơi
local function createGravityCoil()
    local backpack = LocalPlayer:WaitForChild("Backpack")

    -- Dọn dẹp bản cũ nếu có trong Backpack hoặc đang cầm trên tay
    local oldTool = backpack:FindFirstChild(TOOL_NAME)
    if oldTool then oldTool:Destroy() end

    local character = LocalPlayer.Character
    if character then
        local equippedTool = character:FindFirstChild(TOOL_NAME)
        if equippedTool then equippedTool:Destroy() end
    end

    disableLightFall()

    -- Tải mô hình 3D gốc từ Marketplace của Roblox
    local tool
    local success, loadedAsset = pcall(function()
        return InsertService:LoadAsset(GEAR_ID)
    end)

    if success and loadedAsset then
        local foundTool = loadedAsset:FindFirstChildOfClass("Tool")
        if foundTool then
            tool = foundTool
            tool.Name = TOOL_NAME
            loadedAsset:Destroy()
        end
    end

    -- Tạo Tool dự phòng nếu không tải được qua mạng
    if not tool then
        tool = Instance.new("Tool")
        tool.Name = TOOL_NAME
        tool.RequiresHandle = true
        
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1, 1.5, 1)
        handle.Parent = tool
    end

    -- Tinh chỉnh thuộc tính của Tool
    tool.CanBeDropped = false
    tool.ToolTip = "Gravity Coil"
    tool.Grip = CFrame.new(0, -0.2, 0) * CFrame.Angles(0, math.rad(90), 0)

    -- Cấu hình âm thanh Boing cho Handle
    local handle = tool:FindFirstChild("Handle")
    local boingSound
    if handle then
        boingSound = handle:FindFirstChild("BoingSound") or handle:FindFirstChildOfClass("Sound")
        if not boingSound then
            boingSound = Instance.new("Sound")
            boingSound.Name = "BoingSound"
            boingSound.Parent = handle
        end
        boingSound.SoundId = BOING_SOUND_ID
        boingSound.Volume = 0.5
    end

    -- Xử lý sự kiện khi nhân vật nhảy
    local function onJumping(isJumping)
        if isJumping and boingSound then
            boingSound:Play()
        end
    end

    -- Sự kiện khi người chơi cầm vật phẩm lên tay
    tool.Equipped:Connect(function()
        setJumpPower(JUMP_POWER)
        enableLightFall()

        local humanoid = getHumanoid()
        if humanoid then
            if jumpConnection then jumpConnection:Disconnect() end
            jumpConnection = humanoid.Jumping:Connect(onJumping)
        end
    end)

    -- Sự kiện khi người chơi cất vật phẩm
    tool.Unequipped:Connect(function()
        disableLightFall()
        setJumpPower(DEFAULT_JUMP_POWER)
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end
    end)

    -- Dọn dẹp khi Tool bị hủy
    tool.Destroying:Connect(function()
        disableLightFall()
        setJumpPower(DEFAULT_JUMP_POWER)
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end
    end)

    -- Đưa Tool vào balo người chơi
    tool.Parent = backpack
end

-- Tự động cấp lại lò xo khi nhân vật hồi sinh hoặc reset
local function onCharacterAdded()
    disableLightFall()
    task.wait(0.5)
    if LocalPlayer.Character then
        createGravityCoil()
    end
end

if characterConnection then
    characterConnection:Disconnect()
end

characterConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Thực thi lần đầu tiên khi script khởi chạy
createGravityCoil()
