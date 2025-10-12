--[[
    Receptionist NPC
    Handles city hall services: name changes, organizations, and government jobs
]]--

local NPC_RECEPTIONIST = NPC:New("npc_receptionist", "City Hall Receptionist")
NPC_RECEPTIONIST.description = "Handles administrative services at City Hall"
NPC_RECEPTIONIST.model = "models/humans/group10/female_06.mdl"
NPC_RECEPTIONIST.category = "Government"
NPC_RECEPTIONIST.health = 100
NPC_RECEPTIONIST.canBeKilled = false
NPC_RECEPTIONIST.friendly = true

if SERVER then
  -- Configuration
  local NAME_CHANGE_COST = 5000
  local DRIVERS_LICENSE_COST = 2500
  -- local ORGANIZATION_COST = 50000 -- TODO: When organizations are implemented
  
  --- Called when a player uses the receptionist NPC
  --- @param ply Player The player who used the NPC
  function NPC_RECEPTIONIST:OnUse(ply, npcInstance)
    local options = {
      {
        text = "City Hall - " .. npcInstance:GetName(),
        isLabel = true
      }
    }
    
    -- Driver's License application
    if not ply:HasLicense("license_driver") then
      table.insert(options, {
        text = "I would like to apply for a driver's license ($" .. string.Comma(DRIVERS_LICENSE_COST) .. ")",
        callback = function()
          -- Check if player can afford it
          if ply:GetBank() < DRIVERS_LICENSE_COST then
            ply:Notify("You need $" .. string.Comma(DRIVERS_LICENSE_COST) .. " in your bank account for a driver's license.", 3, NOTIFY_ERROR)
            return
          end
          
          -- Confirm purchase
          local confirmOptions = {
            {
              text = "Apply for Driver's License?",
              isLabel = true
            },
            {
              text = "Cost: $" .. string.Comma(DRIVERS_LICENSE_COST),
              isLabel = true
            },
            {
              text = "Yes, apply now",
              callback = function()
                -- Double-check affordability
                if ply:GetBank() < DRIVERS_LICENSE_COST then
                  ply:Notify("You no longer have enough money.", 3, NOTIFY_ERROR)
                  return
                end
                
                -- Charge the player
                ply:AddBank(-DRIVERS_LICENSE_COST)
                
                -- Grant the license
                IonRP.Licenses:Grant(ply, "license_driver", nil, function(success)
                  if success then
                    ply:Notify("Congratulations! You have been granted a driver's license.", 5, NOTIFY_GENERIC)
                  else
                    -- Refund on error
                    ply:AddBank(DRIVERS_LICENSE_COST)
                    ply:Notify("An error occurred. Money refunded.", 5, NOTIFY_ERROR)
                  end
                end)
              end
            },
            {
              text = "No, not right now",
              callback = function()
                ply:Notify("Application cancelled.", 2, NOTIFY_GENERIC)
              end
            }
          }
          IonRP.Dialog:ShowOptions(ply, "Driver's License", confirmOptions)
        end
      })
    elseif ply:GetLicenseState("license_driver") == "suspended" then
      -- License is suspended
      table.insert(options, {
        text = "My driver's license is suspended - can I get it reinstated?",
        callback = function()
          ply:Notify("You must speak with the police to have your license reinstated.", 3, NOTIFY_ERROR)
        end
      })
    end
    
    -- Name change service
    table.insert(options, {
      text = "I would like to change my name ($" .. string.Comma(NAME_CHANGE_COST) .. ")",
      callback = function()
        -- Check if player can afford it
        if ply:GetBank() < NAME_CHANGE_COST then
          ply:Notify("You need $" .. string.Comma(NAME_CHANGE_COST) .. " in your bank account for a name change.", 3, NOTIFY_ERROR)
          return
        end
        
        -- Request first name
        IonRP.Dialog:RequestString(ply, "Name Change", "Enter your new first name:", "", function(firstName)
          if not firstName or firstName == "" then
            ply:Notify("Name change cancelled.", 3, NOTIFY_GENERIC)
            return
          end
          
          -- Sanitize first name
          firstName = string.Trim(firstName)
          firstName = string.gsub(firstName, "[^%a%s]", "")
          
          if #firstName < 2 or #firstName > 32 then
            ply:Notify("First name must be between 2 and 32 characters.", 3, NOTIFY_ERROR)
            return
          end
          
          -- Request last name
          IonRP.Dialog:RequestString(ply, "Name Change", "Enter your new last name:", "", function(lastName)
            if not lastName or lastName == "" then
              ply:Notify("Name change cancelled.", 3, NOTIFY_GENERIC)
              return
            end
            
            -- Sanitize last name
            lastName = string.Trim(lastName)
            lastName = string.gsub(lastName, "[^%a%s]", "")
            
            if #lastName < 2 or #lastName > 32 then
              ply:Notify("Last name must be between 2 and 32 characters.", 3, NOTIFY_ERROR)
              return
            end
            
            -- Double-check they can still afford it (prevent exploits)
            if ply:GetBank() < NAME_CHANGE_COST then
              ply:Notify("You no longer have enough money for a name change.", 3, NOTIFY_ERROR)
              return
            end
            
            -- Charge the player
            ply:AddBank(-NAME_CHANGE_COST)
            
            -- Update their name in the database
            local steamID = ply:SteamID64()
            IonRP.Database:PreparedQuery(
              "UPDATE ionrp_characters SET first_name = ?, last_name = ? WHERE steam_id = ?",
              { firstName, lastName, steamID },
              function()
                -- Update networked strings
                ply:SetNWString("IonRP_FirstName", firstName)
                ply:SetNWString("IonRP_LastName", lastName)
                
                ply:Notify("Your name has been changed to " .. firstName .. " " .. lastName .. "!", 5, NOTIFY_GENERIC)
                print("[IonRP] " .. ply:Nick() .. " changed their RP name to " .. firstName .. " " .. lastName)
              end,
              function(err)
                -- Refund on error
                ply:AddBank(NAME_CHANGE_COST)
                ply:Notify("An error occurred during the name change. Money refunded.", 5, NOTIFY_ERROR)
                print("[IonRP] Error changing name for " .. ply:Nick() .. ": " .. err)
              end
            )
          end)
        end)
      end
    })
    
    --[[
    TODO: Organization system
    
    local org, rank = ply:GetOrganization() -- Needs to be implemented
    
    if not org or org == "" then
      -- Register organization
      table.insert(options, {
        text = "I want to register an organization ($" .. string.Comma(ORGANIZATION_COST) .. ")",
        callback = function()
          if ply:GetBank() < ORGANIZATION_COST then
            ply:Notify("You need $" .. string.Comma(ORGANIZATION_COST) .. " in your bank account.", 3, NOTIFY_ERROR)
            return
          end
          
          IonRP.Dialog:RequestString(ply, "Register Organization", "What do you want the organization to be called?", "", function(orgName)
            if not orgName or orgName == "" then
              ply:Notify("Organization registration cancelled.", 3, NOTIFY_GENERIC)
              return
            end
            
            orgName = string.Trim(orgName)
            
            if #orgName < 3 or #orgName > 64 then
              ply:Notify("Organization name must be between 3 and 64 characters.", 3, NOTIFY_ERROR)
              return
            end
            
            -- Double-check affordability
            if ply:GetBank() < ORGANIZATION_COST then
              ply:Notify("You no longer have enough money.", 3, NOTIFY_ERROR)
              return
            end
            
            -- Charge and register
            ply:AddBank(-ORGANIZATION_COST)
            -- IonRP.Organizations:Register(ply, orgName) -- TODO: Implement
            ply:Notify("Organization '" .. orgName .. "' has been registered!", 5, NOTIFY_GENERIC)
          end)
        end
      })
    elseif rank == "CEO" then
      -- Delete organization (CEO only)
      table.insert(options, {
        text = "I want to delete my organization",
        callback = function()
          IonRP.Dialog:RequestString(ply, "Delete Organization", "Type your organization name '" .. org .. "' to confirm:", "", function(confirm)
            if confirm == org then
              -- IonRP.Organizations:Delete(ply, org) -- TODO: Implement
              ply:Notify("Your organization has been deleted.", 5, NOTIFY_GENERIC)
            else
              ply:Notify("Organization name did not match. Deletion cancelled.", 3, NOTIFY_ERROR)
            end
          end)
        end
      })
    else
      -- Leave organization
      table.insert(options, {
        text = "I want to leave my organization",
        callback = function()
          -- Confirmation using dialog options
          local confirmOptions = {
            {
              text = "Leave '" .. org .. "'?",
              isLabel = true
            },
            {
              text = "Yes, I want to leave",
              callback = function()
                -- IonRP.Organizations:Leave(ply) -- TODO: Implement
                ply:Notify("You have left your organization.", 5, NOTIFY_GENERIC)
              end
            },
            {
              text = "No, cancel",
              callback = function()
                ply:Notify("Cancelled.", 2, NOTIFY_GENERIC)
              end
            }
          }
          IonRP.Dialog:ShowOptions(ply, "Leave Organization", confirmOptions)
        end
      })
    end
    ]]--
    
    --[[
    TODO: Mayor election system
    
    local mayorCount = 0 -- Count players with JOB_MAYOR
    for _, p in ipairs(player.GetAll()) do
      if p:GetJob() == JOB_MAYOR then -- Needs job system implementation
        mayorCount = mayorCount + 1
      end
    end
    
    if mayorCount == 0 then
      -- No mayor, allow candidacy
      local isMayorCandidate = ply:GetNWBool("MayorCandidate", false)
      
      if isMayorCandidate then
        table.insert(options, {
          text = "I want to remove myself from mayor candidacy",
          callback = function()
            ply:SetNWBool("MayorCandidate", false)
            ply:Notify("You are no longer a candidate for mayor.", 3, NOTIFY_GENERIC)
          end
        })
      else
        table.insert(options, {
          text = "I want to become the mayor",
          callback = function()
            -- Check requirements (license, money, etc.)
            if not ply:HasValidLicense("license_driver") then
              ply:Notify("You need a valid driver's license to run for mayor.", 3, NOTIFY_ERROR)
              return
            end
            
            ply:SetNWBool("MayorCandidate", true)
            ply:Notify("You are now a candidate for mayor!", 3, NOTIFY_GENERIC)
          end
        })
      end
    end
    
    -- Mayor/Secret Service resignation
    local currentJob = ply:GetJob()
    if currentJob == JOB_MAYOR or currentJob == JOB_SECRETSERVICE then
      local jobName = currentJob == JOB_MAYOR and "Mayor" or "Secret Service"
      
      table.insert(options, {
        text = "I want to resign as " .. jobName,
        callback = function()
          local confirmOptions = {
            {
              text = "Resign as " .. jobName .. "?",
              isLabel = true
            },
            {
              text = "Yes, resign",
              callback = function()
                ply:SetJob(JOB_CITIZEN) -- Reset to citizen
                ply:Notify("You have resigned from your position.", 5, NOTIFY_GENERIC)
              end
            },
            {
              text = "No, keep my job",
              callback = function()
                ply:Notify("Resignation cancelled.", 2, NOTIFY_GENERIC)
              end
            }
          }
          IonRP.Dialog:ShowOptions(ply, "Resign", confirmOptions)
        end
      })
      
      -- TODO: Spawn government vehicle
      if currentJob == JOB_MAYOR then
        table.insert(options, {
          text = "I want to take out my official vehicle",
          callback = function()
            ply:Notify("Government vehicle spawning is not yet implemented.", 3, NOTIFY_ERROR)
            -- TODO: Spawn mayor's limo at nearest spawn point
          end
        })
      end
    elseif currentJob == JOB_CITIZEN then
      -- Apply for Secret Service
      table.insert(options, {
        text = "I want to become a Secret Service agent",
        callback = function()
          -- Check if mayor exists
          if mayorCount > 0 then
            -- Check requirements
            if not ply:HasValidLicense("license_weapons") then
              ply:Notify("You need a valid weapons license to join the Secret Service.", 3, NOTIFY_ERROR)
              return
            end
            
            ply:SetJob(JOB_SECRETSERVICE)
            ply:Notify("You are now a Secret Service agent!", 5, NOTIFY_GENERIC)
          else
            ply:Notify("There is no mayor to protect. Wait for an election.", 3, NOTIFY_ERROR)
          end
        end
      })
    end
    ]]--
    
    -- Closing option
    table.insert(options, {
      text = "Thank you for your help!",
      callback = function()
        ply:Notify("Have a great day!", 2, NOTIFY_GENERIC)
      end
    })
    
    IonRP.Dialog:ShowOptions(ply, "City Hall", options)
  end
  
  --- Called when the receptionist NPC spawns
  function NPC_RECEPTIONIST:OnSpawn(npcInstance)
    print("[IonRP NPCs] Receptionist spawned: " .. npcInstance:GetName())
  end
end

return NPC_RECEPTIONIST
