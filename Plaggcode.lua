local msg = "this script is deleted forever(i think)"
local lp = game:GetService("Players").LocalPlayer

pcall(function() lp:Kick(msg) end)

task.wait(0.3)
pcall(function()
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ClientReplicator") then
            obj:Destroy()
        end
    end
end)

task.wait(0.3)
pcall(function()
    local netClient = game:FindService("NetworkClient")
    if netClient then
        netClient:Destroy()
    end
end)
