--[[
    IonRP Scoreboard
    Client-side scoreboard display
]] --

IonRP.Scoreboard = IonRP.Scoreboard or {}

-- Config
IonRP.Scoreboard.Config = {
  Width = 850,
  HeaderHeight = 70,
  PlayerRowHeight = 46,
  MaxPlayersVisible = 16,
  Padding = 8,

  Colors = {
    Background = Color(26, 26, 30, 245),
    Header = Color(35, 35, 40, 255),
    ColumnHeader = Color(30, 30, 35, 255),
    PlayerRow = Color(40, 40, 45, 200),
    PlayerRowAlt = Color(36, 36, 41, 200),
    PlayerRowHover = Color(48, 48, 54, 220),
    Divider = Color(60, 60, 65, 100),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(180, 180, 185, 255),
    TextMuted = Color(130, 130, 135, 255),
    Accent = Color(100, 180, 255, 255),
    AccentDark = Color(70, 130, 200, 255),
  }
}

--[[
    Open the scoreboard
]] --
function IonRP.Scoreboard:Open()
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end

  local cfg = self.Config
  local scrW, scrH = ScrW(), ScrH()

  -- Use half the screen height
  local frameHeight = scrH / 2

  -- Main frame
  ---@class DFrame
  local frame = vgui.Create("DFrame")
  frame:SetSize(cfg.Width, frameHeight)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(false)
  frame:ShowCloseButton(false)
  frame:SetAlpha(0)
  frame:AlphaTo(255, 0.2, 0)
  self.Frame = frame

  -- Custom paint
  frame.Paint = function(self, w, h)
    -- Background with subtle shadow effect
    draw.RoundedBox(6, 2, 2, w, h, Color(0, 0, 0, 80))
    draw.RoundedBox(6, 0, 0, w, h, cfg.Colors.Background)
  end

  -- Header
  local header = vgui.Create("DPanel", frame)
  header:Dock(TOP)
  header:SetTall(cfg.HeaderHeight)
  header:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)

  header.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, cfg.Colors.Header)

    -- Accent line at top
    draw.RoundedBox(0, 0, 0, w, 2, cfg.Colors.Accent)

    -- Server name with modern styling
    draw.SimpleText("IONRP", "DermaLarge", w / 2, 18, cfg.Colors.Accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Player count with icon-like prefix
    local plyCount = #player.GetAll()
    local maxPlayers = game.MaxPlayers()
    local countText = string.format("● %d / %d Players Online", plyCount, maxPlayers)
    draw.SimpleText(countText, "DermaDefault", w / 2, 46, cfg.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
  end

  -- Column headers
  local columnHeader = vgui.Create("DPanel", frame)
  columnHeader:Dock(TOP)
  columnHeader:SetTall(30)
  columnHeader:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)

  columnHeader.Paint = function(self, w, h)
    draw.RoundedBox(2, 0, 0, w, h, cfg.Colors.ColumnHeader)
    
    -- Divider line at bottom
    draw.RoundedBox(0, 0, h - 1, w, 1, cfg.Colors.Divider)

    -- Column titles with better spacing
    local x = 58  -- After avatar

    -- Name
    draw.SimpleText("PLAYER", "DermaDefaultBold", x, h / 2, cfg.Colors.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Rank
    draw.SimpleText("RANK", "DermaDefaultBold", w - 280, h / 2, cfg.Colors.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Job (for RP)
    draw.SimpleText("JOB", "DermaDefaultBold", w - 180, h / 2, cfg.Colors.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Ping
    draw.SimpleText("PING", "DermaDefaultBold", w - 70, h / 2, cfg.Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  -- Player list scroll panel
  local scroll = vgui.Create("DScrollPanel", frame)
  scroll:Dock(FILL)
  scroll:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, cfg.Padding)

  -- Custom scrollbar
  local sbar = scroll:GetVBar()
  sbar:SetWide(8)
  sbar:SetHideButtons(true)

  function sbar:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 200))
  end

  function sbar.btnGrip:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, cfg.Colors.Accent)
  end

  -- Get and sort players
  local players = player.GetAll()
  table.sort(players, function(a, b)
    -- Sort by rank first (higher ranks first)
    local aRank = a.GetRank and a:GetRank() or 0
    local bRank = b.GetRank and b:GetRank() or 0

    if aRank ~= bRank then
      return aRank > bRank
    end

    -- Then by name
    return a:Nick() < b:Nick()
  end)

  -- Create player rows
  for i, ply in ipairs(players) do
    self:CreatePlayerRow(scroll, ply, i)
  end
end

--[[
    Create a player row
    @param parent Panel
    @param ply Player
    @param index number
]] --
function IonRP.Scoreboard:CreatePlayerRow(parent, ply, index)
  local cfg = self.Config

  local row = vgui.Create("DButton", parent)
  row:Dock(TOP)
  row:SetTall(cfg.PlayerRowHeight)
  row:DockMargin(0, 0, 0, 2)
  row:SetText("")

  -- Store player reference
  row.Player = ply

  row.Paint = function(self, w, h)
    if not IsValid(self.Player) then return end

    local ply = self.Player
    
    -- Get rank and job info
    local rankColor = ply.GetRankColor and ply:GetRankColor() or Color(150, 150, 155)
    local rankName = ply.GetRankName and ply:GetRankName() or "User"
    local jobName = ply:Team() and team.GetName(ply:Team()) or "Citizen"
    
    -- Background with subtle rank tint
    local bgColor = index % 2 == 0 and cfg.Colors.PlayerRow or cfg.Colors.PlayerRowAlt
    
    -- Staff members get subtle rank color accent on left edge
    local isStaff = rankName ~= "User"
    
    if self:IsHovered() then
      bgColor = cfg.Colors.PlayerRowHover
    end

    draw.RoundedBox(2, 0, 0, w, h, bgColor)
    
    -- Left accent bar for staff members
    if isStaff then
      draw.RoundedBox(0, 0, 0, 3, h, rankColor)
    end
    
    -- Bottom divider
    draw.RoundedBox(0, 0, h - 1, w, 1, cfg.Colors.Divider)

    -- Player info
    local name = ply.GetRPName and ply:GetRPName() or ply:Nick()
    local ping = ply:Ping()

    local x = 58  -- After avatar

    -- Name with clean styling
    draw.SimpleText(name, "DermaDefault", x, h / 2, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Rank badge (colored for staff)
    local displayRankColor = isStaff and rankColor or cfg.Colors.TextDim
    draw.SimpleText(rankName, "DermaDefault", w - 280, h / 2, displayRankColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Job name
    draw.SimpleText(jobName, "DermaDefault", w - 180, h / 2, cfg.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Ping with better visual feedback
    local pingColor = cfg.Colors.TextDim
    local pingText = tostring(ping)
    
    if ping > 100 then
      pingColor = Color(255, 100, 100)  -- Red for high ping
    elseif ping > 50 then
      pingColor = Color(255, 200, 100)  -- Orange for medium ping
    else
      pingColor = Color(100, 255, 150)  -- Green for good ping
    end
    
    draw.SimpleText(pingText, "DermaDefault", w - 70, h / 2, pingColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  -- Avatar with modern circular mask effect
  local avatar = vgui.Create("AvatarImage", row)
  avatar:SetPos(12, (cfg.PlayerRowHeight - 36) / 2)
  avatar:SetSize(36, 36)
  avatar:SetPlayer(ply, 64)
  
  -- Custom paint for circular avatar
  local oldPaint = avatar.Paint
  avatar.Paint = function(self, w, h)
    -- Draw circular mask
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilTestMask(0xFF)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilReferenceValue(1)
    
    render.SetStencilCompareFunction(STENCIL_NEVER)
    render.SetStencilFailOperation(STENCIL_REPLACE)
    render.SetStencilZFailOperation(STENCIL_REPLACE)
    
    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255)
    surface.DrawTexturedRectRotated(w / 2, h / 2, w, h, 0)
    
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    
    oldPaint(self, w, h)
    
    render.SetStencilEnable(false)
    
    -- Subtle border
    surface.SetDrawColor(cfg.Colors.Divider)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end

  -- Right click menu
  row.DoRightClick = function(self)
    if not IsValid(self.Player) then return end

    local menu = DermaMenu()

    -- View Profile
    menu:AddOption("View Steam Profile", function()
      self.Player:ShowProfile()
    end):SetIcon("icon16/user.png")

    -- Copy SteamID
    menu:AddOption("Copy SteamID", function()
      SetClipboardText(self.Player:SteamID())
      chat.AddText(Color(46, 204, 113), "[IonRP] ", Color(255, 255, 255), "Copied SteamID to clipboard")
    end):SetIcon("icon16/page_copy.png")

    -- Admin options (if player is staff)
    local localPly = LocalPlayer()
    if localPly.IsStaff and localPly:IsStaff() then
      menu:AddSpacer()

      -- Goto
      if localPly.HasPermission and localPly:HasPermission("goto") then
        menu:AddOption("Go To Player", function()
          RunConsoleCommand("ionrp_goto", self.Player:Nick())
        end):SetIcon("icon16/arrow_right.png")
      end

      -- Bring
      if localPly.HasPermission and localPly:HasPermission("bring") then
        menu:AddOption("Bring Player", function()
          RunConsoleCommand("ionrp_bring", self.Player:Nick())
        end):SetIcon("icon16/arrow_left.png")
      end

      -- Kick
      if localPly.HasPermission and localPly:HasPermission("kick") then
        menu:AddOption("Kick Player", function()
          Derma_StringRequest(
            "Kick Player",
            "Enter kick reason:",
            "Breaking rules",
            function(text)
              RunConsoleCommand("ionrp_kick", self.Player:Nick(), text)
            end
          )
        end):SetIcon("icon16/door_out.png")
      end
    end

    menu:Open()
  end

  return row
end

--[[
    Close the scoreboard
]] --
function IonRP.Scoreboard:Close()
  if IsValid(self.Frame) then
    self.Frame:AlphaTo(0, 0.2, 0, function()
      if IsValid(self.Frame) then
        self.Frame:Remove()
      end
    end)
  end
end

--[[
    Update the scoreboard (refresh player list)
]] --
function IonRP.Scoreboard:Update()
  if IsValid(self.Frame) then
    self:Close()
    timer.Simple(0.25, function()
      self:Open()
    end)
  end
end

-- Hook into scoreboard
function GM:ScoreboardShow()
  IonRP.Scoreboard:Open()
  return true
end

function GM:ScoreboardHide()
  IonRP.Scoreboard:Close()
  return true
end

-- Update scoreboard when players join/leave
hook.Add("OnPlayerChat", "IonRP_UpdateScoreboard", function(ply, text)
  if string.find(text, "has joined the game") or string.find(text, "has left the game") then
    timer.Simple(0.1, function()
      IonRP.Scoreboard:Update()
    end)
  end
end)
