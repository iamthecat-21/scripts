-- Decompiled with the Synapse X Luau decompiler.

local v1 = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"));
local v2 = {};
local v3 = v1.import(script, v1.getModule(script, "services"));
local l__BlockServerScript__4 = v1.import(script, game:GetService("ReplicatedStorage"), "TS", "block", "block-server-script").BlockServerScript;
local v5 = setmetatable({}, {
	__index = l__BlockServerScript__4, 
	__tostring = function()
		return "WorkerBlockServerScript";
	end
});
v5.__index = v5;
local l__BlockMeta__1 = v1.import(script, game:GetService("ReplicatedStorage"), "TS", "block", "block-meta").BlockMeta;
local l__WorkerBlockMeta__2 = v1.import(script, game:GetService("ReplicatedStorage"), "TS", "crafting", "worker-block-meta").WorkerBlockMeta;
function v5.constructor(p1, p2, p3, p4)
	l__BlockServerScript__4.constructor(p1, p2);
	p1.fuelTimeRemaining = 0;
	p1.fuelAddedAt = {};
	p1.block = p1.block;
	p1.blockMeta = l__BlockMeta__1[p1.block.Name];
	p1.workerMeta = l__WorkerBlockMeta__2[p1.blockMeta.worker];
	p1.maxContents = p3;
	p1.maxFuel = p4;
	p1.workerFolder = p1.block:FindFirstChild("Worker");
end;
local l__BlockWorkerUtils__3 = v1.import(script, game:GetService("ReplicatedStorage"), "TS", "util", "block-worker-utils").BlockWorkerUtils;
function v5.onEnable(p5)
	p5.fuelTimeRemaining = 0;
	p5.workingReference = p5.block.Working;
	local v6 = Instance.new("IntValue");
	v6.Name = "WorkerMaxContents";
	v6.Value = p5.maxContents;
	v6.Parent = p5.block;
	local v7 = Instance.new("IntValue");
	v7.Name = "WorkerMaxFuel";
	v7.Value = p5.maxFuel;
	v7.Parent = p5.block;
	p5.block.WorkerFuel.ChildAdded:Connect(function(p6)
		p5.fuelAddedAt[p6] = tick();
	end);
	p5.block.WorkerFuel.ChildRemoved:Connect(function(p7)
		p5.fuelAddedAt[p7] = nil;
	end);
	local v8 = p5:getFuel();
	for v9 = 1, #v8 do
		p5.fuelAddedAt[v8[v9]] = tick();
	end;
	v1.Promise.spawn(function()
		while true do
			local v10 = wait(0.5);
			if v10 == 0 then
				break;
			end;
			if v10 ~= v10 then
				break;
			end;
			if not v10 then
				break;
			end;
			if not l__BlockServerScript__4.isAlive(p5) then
				break;
			end;
			local v17
			
			if p5.maxFuel > 0 then
				p5.fuelTimeRemaining = p5.fuelTimeRemaining - 0.5;
				if p5.fuelTimeRemaining <= 0 then
					if p5.fuelTimeRemaining < 0 then
						p5.fuelTimeRemaining = 0;
					end;
					local v11 = p5:getFuel();
					for v12 = 1, #v11 do
						local v13 = v11[v12];
						local v14 = p5.fuelAddedAt[v13];
						local v15
						
						if v14 == 0 or v14 ~= v14 or not v14 or tick() < v14 + 0.2 then
							v15 = true;
						else
							local l__Amount__16 = v13.Amount;
							l__Amount__16.Value = l__Amount__16.Value - 1;
							p5.fuelTimeRemaining = p5.fuelTimeRemaining + l__BlockWorkerUtils__3.getToolFuel(p5.workerMeta, v13.Name).fuelTime;
							if v13.Amount.Value <= 0 then
								v13:Destroy();
							end;
							v15 = true;
						end;
						if not v15 then
							break;
						end;
					end;
					if p5.fuelTimeRemaining <= 0 then
						p5:stopWorking();
						v17 = true;
					elseif not p5:canWork() then
						if p5.workingReference.Value then
							p5:stopWorking();
						end;
						v17 = true;
					else
						if not p5.workingReference.Value then
							p5:startWorking();
						end;
						p5:onAction(0.5);
						v17 = true;
					end;
				elseif not p5:canWork() then
					if p5.workingReference.Value then
						p5:stopWorking();
					end;
					v17 = true;
				else
					if not p5.workingReference.Value then
						p5:startWorking();
					end;
					p5:onAction(0.5);
					v17 = true;
				end;
			elseif not p5:canWork() then
				if p5.workingReference.Value then
					p5:stopWorking();
				end;
				v17 = true;
			else
				if not p5.workingReference.Value then
					p5:startWorking();
				end;
				p5:onAction(0.5);
				v17 = true;
			end;
			if not v17 then
				break;
			end;		
		end;
	end);
	if p5.workerFolder and p5.workerFolder:FindFirstChild("Input") then
		print("enabling input listening!");
		p5:listenForInput();
	end;
	p5:onWorkerEnabled();
end;
function v5.onSave(p8)

end;
function v5.onDisable(p9)

end;
local l__Workspace__4 = v3.Workspace;
local l__BlockUtils__5 = v1.import(script, game:GetService("ReplicatedStorage"), "TS", "util", "block-utils").BlockUtils;
function v5.listenForInput(p10)
	v1.Promise.spawn(function()
		while true do
			local v18 = wait(1);
			if v18 == 0 then
				break;
			end;
			if v18 ~= v18 then
				break;
			end;
			if not v18 then
				break;
			end;
			if not l__BlockServerScript__4.isAlive(p10) then
				break;
			end;
			local v19 = p10:getFuel();
			local v20 = p10:getContents();
			local v21
			
			if p10.maxFuel <= #v19 and p10.maxContents <= #v20 then
				v21 = true;
			else
				local l__Input__22 = p10.workerFolder:FindFirstChild("Input");
				local v23 = l__Workspace__4:FindPartsInRegion3(Region3.new(l__Input__22.Position - l__Input__22.Size / 2, l__Input__22.Position + l__Input__22.Size / 2), nil, 200);
				for v24 = 1, #v23 do
					local v25 = v23[v24];
					local v26 = false;
					if v25.Parent and v25.Parent:IsA("Tool") then
						local l__Parent__27 = v25.Parent;
						if l__Parent__27.Parent and l__Parent__27.Parent.Name == "Drops" then
							local v28 = l__BlockWorkerUtils__3.getToolIngredient(p10.workerMeta, l__Parent__27.Name);
							if l__BlockWorkerUtils__3.getToolFuel(p10.workerMeta, l__Parent__27.Name) then
								if p10.maxFuel <= #v19 then
									v26 = true;
								else
									l__Parent__27.HandleDisabled.Anchored = true;
									l__Parent__27.Parent = p10.block.WorkerFuel;
									l__Parent__27.HandleDisabled.CFrame = l__BlockUtils__5.getBlockWorkerOpenFuelCFrame(p10.block);
								end;
							elseif v28 then
								if p10.maxContents <= #v20 then
									v26 = true;
								else
									l__Parent__27.HandleDisabled.Anchored = true;
									l__Parent__27.Parent = p10.block.WorkerContents;
									l__Parent__27.HandleDisabled.CFrame = l__BlockUtils__5.getBlockWorkerOpenContentCFrame(p10.block);
								end;
							else
								v26 = true;
							end;
						else
							v26 = true;
						end;
					else
						v26 = true;
					end;
					if not v26 then
						break;
					end;
				end;
				v21 = true;
			end;
			if not v21 then
				break;
			end;		
		end;
	end);
end;
function v5.onWorkerEnabled(p11)

end;
function v5.startWorking(p12)
	p12.workingReference.Value = true;
	p12:onStartWorking();
	p12:onStartWorkingEffects();
end;
function v5.stopWorking(p13)
	p13.workingReference.Value = false;
	p13:onStopWorking();
	p13:onStopWorkingEffects();
end;
function v5.getContents(p14)
	local v29 = {};
	local l__WorkerContents__30 = p14.block:FindFirstChild("WorkerContents");
	if not l__WorkerContents__30 then
		return v29;
	end;
	local v31 = l__WorkerContents__30:GetChildren();
	for v32 = 1, #v31 do
		local v33 = v31[v32];
		if v33:IsA("Tool") then
			v29[#v29 + 1] = v33;
		end;
	end;
	return v29;
end;
function v5.getFuel(p15)
	local v34 = {};
	local v35 = p15.block.WorkerFuel:GetChildren();
	for v36 = 1, #v35 do
		local v37 = v35[v36];
		if v37:IsA("Tool") then
			v34[#v34 + 1] = v37;
		end;
	end;
	return v34;
end;
function v5.getContentPositions(p16)
	local v38 = {};
	local l__WorkerContents__39 = p16.block.WorkerContents;
	if l__WorkerContents__39 then
		local v40 = 1;
		while l__WorkerContents__39:FindFirstChild(v40 .. "") ~= nil do
			v38[#v38 + 1] = l__WorkerContents__39:FindFirstChild(v40 .. "").CFrame;
			v40 = v40 + 1;		
		end;
	end;
	return v38;
end;
function v5.getFuelPositions(p17)
	local v41 = {};
	local l__WorkerFuel__42 = p17.block.WorkerFuel;
	if l__WorkerFuel__42 then
		local v43 = 1;
		while l__WorkerFuel__42:FindFirstChild(v43 .. "") ~= nil do
			v41[#v41 + 1] = l__WorkerFuel__42:FindFirstChild(v43 .. "").CFrame;
			v43 = v43 + 1;		
		end;
	end;
	return v41;
end;
local l__ReplicatedStorage__6 = v3.ReplicatedStorage;
function v5.produceContentTool(p18, p19, p20)
	local v44 = l__ReplicatedStorage__6:WaitForChild("Tools"):FindFirstChild(p19);
	local v45 = l__BlockUtils__5.getBlockWorkerOpenContentCFrame(p18.block);
	if v44 then
		local v46 = v44:Clone();
		if p20 ~= nil then
			v46.Amount.Value = p20;
		else
			v46.Amount.Value = v44.Amount.Value;
		end;
		v46.Handle.Anchored = true;
		v46.Handle.CFrame = v45;
		v46.Handle.Name = "HandleDisabled";
		local v47 = Instance.new("ObjectValue");
		v47.Name = "WorkerPlayerDeposited";
		v47.Value = nil;
		v47.Parent = v46;
		v46.Parent = p18.block.WorkerContents;
	end;
end;
function v5.canWork(p21)
	return true;
end;
function v5.onAction(p22, p23)

end;
function v5.onStartWorkingEffects(p24)
	local l__Effects__48 = p24.block:FindFirstChild("Effects");
	if l__Effects__48 then
		local v49 = l__Effects__48:GetChildren();
		for v50 = 1, #v49 do
			local v51 = v49[v50];
			if v51:IsA("BasePart") then
				local v52 = v51:GetChildren();
				for v53 = 1, #v52 do
					local v54 = v52[v53];
					if v54:IsA("ParticleEmitter") then
						v54.Enabled = true;
					elseif v54:IsA("Light") then
						v54.Enabled = true;
					elseif v54:IsA("Fire") then
						v54.Enabled = true;
					end;
				end;
			end;
		end;
	end;
end;
function v5.onStopWorkingEffects(p25)
	local l__Effects__55 = p25.block:FindFirstChild("Effects");
	if l__Effects__55 then
		local v56 = l__Effects__55:GetChildren();
		for v57 = 1, #v56 do
			local v58 = v56[v57];
			if v58:IsA("BasePart") then
				local v59 = v58:GetChildren();
				for v60 = 1, #v59 do
					local v61 = v59[v60];
					if v61:IsA("ParticleEmitter") then
						v61.Enabled = false;
					elseif v61:IsA("Light") then
						v61.Enabled = false;
					elseif v61:IsA("Fire") then
						v61.Enabled = false;
					end;
				end;
			end;
		end;
	end;
end;
v2.WorkerBlockServerScript = v5;
return v2;
