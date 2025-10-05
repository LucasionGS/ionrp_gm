--[[
    IonRP Scoreboard
    Client-side scoreboard display
]] --

IonRP.Scoreboard = IonRP.Scoreboard or {}

-- Config
IonRP.Scoreboard.Config = {
  Width = 900,
  HeaderHeight = 80,
  PlayerRowHeight = 50,
  MaxPlayersVisible = 16,
  Padding = 10,

  Colors = {
    Background = Color(30, 30, 30, 240),
    Header = Color(40, 40, 40, 255),
    PlayerRow = Color(45, 45, 45, 220),
    PlayerRowAlt = Color(40, 40, 40, 220),
    PlayerRowHover = Color(55, 55, 55, 230),
    Border = Color(60, 60, 60, 255),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(200, 200, 200, 255),
    Accent = Color(52, 152, 219, 255),
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
    -- Background
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)

    -- Border
    surface.SetDrawColor(cfg.Colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
  end

  -- Header
  local header = vgui.Create("DPanel", frame)
  header:Dock(TOP)
  header:SetTall(cfg.HeaderHeight)
  header:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)

  header.Paint = function(self, w, h)
    draw.RoundedBox(6, 0, 0, w, h, cfg.Colors.Header)

    -- Server name
    draw.SimpleText("IonRP Server", "DermaLarge", w / 2, 15, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Player count
    local plyCount = #player.GetAll()
    local maxPlayers = game.MaxPlayers()
    draw.SimpleText(plyCount .. " / " .. maxPlayers .. " Players", "DermaDefault", w / 2, 45, cfg.Colors.TextDim,
      TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
  end

  -- Column headers
  local columnHeader = vgui.Create("DPanel", frame)
  columnHeader:Dock(TOP)
  columnHeader:SetTall(30)
  columnHeader:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)

  columnHeader.Paint = function(self, w, h)
    -- Column titles
    local x = 10

    -- Avatar space
    x = x + 40

    -- Name
    draw.SimpleText("Name", "DermaDefaultBold", x, h / 2, cfg.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Rank
    draw.SimpleText("Rank", "DermaDefaultBold", w - 250, h / 2, cfg.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Ping
    draw.SimpleText("Ping", "DermaDefaultBold", w - 80, h / 2, cfg.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
    
    -- Get rank info
    local rankColor = ply.GetRankColor and ply:GetRankColor() or Color(200, 200, 200)
    local rankName = ply.GetRankName and ply:GetRankName() or "User"
    
    -- Color the row background based on rank
    local bgColor
    if rankName ~= "User" then
      -- Use rank color with low opacity for background
      bgColor = Color(rankColor.r, rankColor.g, rankColor.b, 30)
    else
      -- Alternate colors for users
      bgColor = index % 2 == 0 and cfg.Colors.PlayerRow or cfg.Colors.PlayerRowAlt
    end

    if self:IsHovered() then
      if rankName ~= "User" then
        bgColor = Color(rankColor.r, rankColor.g, rankColor.b, 50)
      else
        bgColor = cfg.Colors.PlayerRowHover
      end
    end

    draw.RoundedBox(4, 0, 0, w, h, bgColor)

    local x = 10

    -- Player info
    local name = ply.GetRPName and ply:GetRPName() or ply:Nick()
    local ping = ply:Ping()

    -- Avatar
    x = x + 40

    -- Name
    draw.SimpleText(name, "DermaDefault", x, h / 2, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Rank (always show, colored)
    draw.SimpleText(rankName, "DermaDefault", w - 250, h / 2, rankColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Ping with color coding
    local pingColor = cfg.Colors.Text
    if ping > 100 then
      pingColor = Color(231, 76, 60)        -- Red for high ping
    elseif ping > 50 then
      pingColor = Color(241, 196, 15)       -- Yellow for medium ping
    else
      pingColor = Color(46, 204, 113)       -- Green for low ping
    end
    draw.SimpleText(ping .. " ms", "DermaDefault", w - 80, h / 2, pingColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  -- Avatar
  local avatar = vgui.Create("AvatarImage", row)
  avatar:SetPos(10, (cfg.PlayerRowHeight - 32) / 2)
  avatar:SetSize(32, 32)
  avatar:SetPlayer(ply, 32)

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
