local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local UIS = game:GetService("UserInputService");
local player = Players.LocalPlayer;
local camera = workspace.CurrentCamera;
local mouse = player:GetMouse();
local enabled = false;
local teamCheck = true;
local FOV = 150;
local MaxDistance = 200;
local healthGuis = {};
local Boxes = {};
local Lines = {};
local FOVCircle = Drawing.new("Circle");
FOVCircle.Color = Color3.fromRGB(255, 0, 0);
FOVCircle.Thickness = 1.2;
FOVCircle.Filled = false;
FOVCircle.Radius = FOV;
FOVCircle.NumSides = 100;
FOVCircle.Transparency = 0.8;
FOVCircle.Visible = false;
local function removeESP(plr)
	if plr.Character then
		local box = plr.Character:FindFirstChild("ESPBox");
		if box then
			box:Destroy();
		end
	end
end
Players.PlayerRemoving:Connect(function(plr)
	removeESP(plr);
	if healthGuis[plr] then
		healthGuis[plr]:Destroy();
		healthGuis[plr] = nil;
	end
end);
local function createHealthGui(plr, char)
	if healthGuis[plr] then
		healthGuis[plr]:Destroy();
	end
	local head = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart");
	if not head then
		return;
	end
	local gui = Instance.new("BillboardGui");
	gui.Size = UDim2.new(0, 120, 0, 30);
	gui.StudsOffset = Vector3.new(0, 2.5, 0);
	gui.AlwaysOnTop = true;
	gui.MaxDistance = 200;
	gui.Enabled = false;
	local text = Instance.new("TextLabel");
	text.Size = UDim2.new(1, 0, 1, 0);
	text.BackgroundTransparency = 1;
	text.TextColor3 = Color3.fromRGB(255, 0, 0);
	text.TextStrokeTransparency = 0;
	text.TextScaled = false;
	text.TextSize = 14;
	text.Font = Enum.Font.SourceSansBold;
	text.Parent = gui;
	gui.Parent = head;
	healthGuis[plr] = gui;
	local humanoid = char:FindFirstChild("Humanoid");
	if humanoid then
		RunService.RenderStepped:Connect(function()
			if (gui and humanoid) then
				text.Text = math.floor(humanoid.Health) .. " HP";
			end
		end);
	end
end
local function setupPlayer(plr)
	if (plr == player) then
		return;
	end
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 5);
		char:WaitForChild("Head", 5);
		createHealthGui(plr, char);
	end);
end
for _, plr in pairs(Players:GetPlayers()) do
	setupPlayer(plr);
	if plr.Character then
		createHealthGui(plr, plr.Character);
	end
end
Players.PlayerAdded:Connect(setupPlayer);
UIS.InputBegan:Connect(function(input, typing)
	if typing then
		return;
	end
	if (input.KeyCode == Enum.KeyCode.U) then
		enabled = not enabled;
	end
	if (input.KeyCode == Enum.KeyCode.T) then
		teamCheck = not teamCheck;
	end
end);
RunService.RenderStepped:Connect(function()
	FOVCircle.Position = Vector2.new(mouse.X, mouse.Y + 50);
	FOVCircle.Radius = FOV;
	FOVCircle.Visible = enabled;
	local myChar = player.Character;
	local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso"));
	if not myRoot then
		return;
	end
	local mousePos = Vector2.new(mouse.X, mouse.Y);
	local closestHead = nil;
	local closestDistance = math.huge;
	for _, plr in pairs(Players:GetPlayers()) do
		if (plr == player) then
			continue;
		end
		local char = plr.Character;
		local humanoid = char and char:FindFirstChild("Humanoid");
		local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"));
		local head = char and (char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart"));
		if (char and humanoid and (humanoid.Health > 0) and root and head) then
			if (teamCheck and (plr.Team == player.Team)) then
				removeESP(plr);
				if healthGuis[plr] then
					healthGuis[plr].Enabled = false;
				end
				continue;
			end
			if enabled then
				if not char:FindFirstChild("ESPBox") then
					local box = Instance.new("BoxHandleAdornment");
					box.Name = "ESPBox";
					box.Adornee = char;
					box.AlwaysOnTop = true;
					box.ZIndex = 10;
					box.Size = Vector3.new(4, 6, 2);
					box.Color3 = Color3.fromRGB(255, 0, 0);
					box.Transparency = 0.4;
					box.Parent = char;
				end
				if healthGuis[plr] then
					healthGuis[plr].Enabled = true;
				end
			else
				removeESP(plr);
				if healthGuis[plr] then
					healthGuis[plr].Enabled = false;
				end
			end
			local distance = (myRoot.Position - root.Position).Magnitude;
			if (distance <= MaxDistance) then
				local headPos2, onScreen = camera:WorldToViewportPoint(head.Position);
				if onScreen then
					local distFromMouse = (Vector2.new(headPos2.X, headPos2.Y) - mousePos).Magnitude;
					if (distFromMouse <= FOV) then
						if (distFromMouse < closestDistance) then
							closestDistance = distFromMouse;
							closestHead = head;
						end
					end
				end
			end
		else
			removeESP(plr);
			if healthGuis[plr] then
				healthGuis[plr].Enabled = false;
			end
		end
	end
	if (enabled and closestHead) then
		local camPos = camera.CFrame.Position;
		local targetPos = closestHead.Position + Vector3.new(0, 1.2, 0);
		camera.CFrame = CFrame.lookAt(camPos, targetPos);
	end
end);
