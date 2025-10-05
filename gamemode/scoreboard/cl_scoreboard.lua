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
    Background = Color(25, 25, 35, 250),
    Header = Color(45, 35, 60, 255),           -- Purple tint
    ColumnHeader = Color(40, 50, 65, 255),      -- Blue-purple tint
    PlayerRow = Color(40, 45, 55, 210),
    PlayerRowAlt = Color(45, 40, 60, 210),      -- Slight purple alt
    PlayerRowHover = Color(60, 55, 75, 230),
    Divider = Color(100, 80, 120, 100),         -- Purple divider
    Text = Color(255, 255, 255, 255),
    TextDim = Color(200, 200, 210, 255),
    TextMuted = Color(160, 160, 175, 255),
    Accent = Color(120, 100, 255, 255),         -- Bright purple
    AccentCyan = Color(100, 200, 255, 255),     -- Cyan
    AccentPink = Color(255, 100, 180, 255),     -- Hot pink
    AccentGreen = Color(100, 255, 150, 255),    -- Mint green
    AccentOrange = Color(255, 150, 80, 255),    -- Orange
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
    -- Shadow
    draw.RoundedBox(8, 3, 3, w, h, Color(0, 0, 0, 100))
    
    -- Main background
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)
    
    -- Colorful gradient border
    local time = CurTime()
    
    -- Top border (animated gradient)
    for i = 0, w, 4 do
      local hue = ((i / w * 360) + (time * 50)) % 360
      local col = HSVToColor(hue, 0.7, 1)
      col.a = 200
      surface.SetDrawColor(col)
      surface.DrawRect(i, 0, 4, 3)
    end
    
    -- Bottom border
    for i = 0, w, 4 do
      local hue = ((i / w * 360) + (time * 50) + 180) % 360
      local col = HSVToColor(hue, 0.7, 1)
      col.a = 200
      surface.SetDrawColor(col)
      surface.DrawRect(i, h - 3, 4, 3)
    end
  end

  -- Header
  local header = vgui.Create("DPanel", frame)
  header:Dock(TOP)
  header:SetTall(cfg.HeaderHeight)
  header:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)

  header.Paint = function(self, w, h)
    -- Gradient header background
    surface.SetDrawColor(cfg.Colors.Header)
    surface.DrawRect(0, 0, w, h)
    
    -- Animated colorful particles effect in header
    local time = CurTime()
    for i = 1, 15 do
      local x = (w / 15 * i + math.sin(time * 2 + i) * 30) % w
      local y = 5 + math.sin(time * 3 + i * 0.5) * 10
      local size = 3 + math.sin(time * 4 + i) * 2
      local hue = (i * 24 + time * 100) % 360
      local col = HSVToColor(hue, 0.8, 1)
      col.a = 150
      
      draw.NoTexture()
      surface.SetDrawColor(col)
      surface.DrawTexturedRectRotated(x, y, size, size, time * 50 + i * 10)
    end

    -- Server name
    draw.SimpleText("IONRP", "DermaLarge", w / 2, 20, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Player count
    local plyCount = #player.GetAll()
    local maxPlayers = game.MaxPlayers()
    local countText = string.format("%d / %d Players Online", plyCount, maxPlayers)
    draw.SimpleText(countText, "DermaDefault", w / 2, 48, cfg.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
  end

  -- Column headers
  local columnHeader = vgui.Create("DPanel", frame)
  columnHeader:Dock(TOP)
  columnHeader:SetTall(30)
  columnHeader:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)

  columnHeader.Paint = function(self, w, h)
    draw.RoundedBox(2, 0, 0, w, h, cfg.Colors.ColumnHeader)
    
    -- Colorful gradient underline
    local segmentWidth = w / 4
    local colors = {cfg.Colors.AccentCyan, cfg.Colors.Accent, cfg.Colors.AccentPink, cfg.Colors.AccentGreen}
    for i = 1, 4 do
      local col = colors[i]
      col = Color(col.r, col.g, col.b, 150)
      draw.RoundedBox(0, (i - 1) * segmentWidth, h - 2, segmentWidth, 2, col)
    end

    -- Column titles with better spacing
    local x = 58  -- After avatar

    -- Name
    draw.SimpleText("PLAYER", "DermaDefaultBold", x, h / 2, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Rank
    draw.SimpleText("RANK", "DermaDefaultBold", w - 280, h / 2, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Job (for RP)
    draw.SimpleText("JOB", "DermaDefaultBold", w - 180, h / 2, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Ping
    draw.SimpleText("PING", "DermaDefaultBold", w - 70, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 30, 220))
  end

  function sbar.btnGrip:Paint(w, h)
    -- Rainbow gradient scrollbar grip
    local time = CurTime()
    for i = 0, h, 4 do
      local hue = ((i / h * 180) + (time * 80)) % 360
      local col = HSVToColor(hue, 0.7, 1)
      col.a = 220
      surface.SetDrawColor(col)
      surface.DrawRect(0, i, w, 4)
    end
    
    -- Bright outline
    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
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
    
    -- Colorful left accent bar for staff members (thicker and glowing)
    if isStaff then
      -- Main accent bar
      draw.RoundedBox(0, 0, 0, 4, h, rankColor)
      
      -- Glow effect
      local glowCol = Color(rankColor.r, rankColor.g, rankColor.b, 60)
      draw.RoundedBox(0, 4, 0, 12, h, glowCol)
      
      -- Animated pulse on the accent
      local pulse = math.abs(math.sin(CurTime() * 2 + index * 0.3))
      local pulseCol = Color(rankColor.r, rankColor.g, rankColor.b, 30 + pulse * 40)
      draw.RoundedBox(0, 0, 0, 2, h, pulseCol)
    end
    
    -- Colorful gradient bottom divider
    local time = CurTime()
    for i = 0, w, 8 do
      local hue = ((i / w * 120) + (time * 30) + (index * 15)) % 360
      local col = HSVToColor(hue, 0.4, 0.8)
      col.a = 40
      surface.SetDrawColor(col)
      surface.DrawRect(i, h - 1, 8, 1)
    end

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

  -- Avatar with colorful animated border
  local avatar = vgui.Create("AvatarImage", row)
  avatar:SetPos(12, (cfg.PlayerRowHeight - 36) / 2)
  avatar:SetSize(36, 36)
  avatar:SetPlayer(ply, 64)
  
  -- Custom paint for circular avatar with colorful ring
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
    
    -- Animated colorful border ring
    local time = CurTime()
    local segments = 16
    for i = 0, segments - 1 do
      local angle = (i / segments) * 360
      local hue = ((angle + time * 100 + index * 20) % 360)
      local col = HSVToColor(hue, 0.7, 1)
      col.a = 180
      
      local rad1 = math.rad(angle)
      local rad2 = math.rad(angle + (360 / segments))
      local radius = w / 2
      
      surface.SetDrawColor(col)
      -- Simple outline approximation
      surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
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
