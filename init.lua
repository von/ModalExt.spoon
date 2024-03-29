--- === ModalExt ===
--- Extended hotkey modal support.
--- Kudos for cheatsheet: https://github.com/ashfinal/awesome-hammerspoon

local ModalExt = {}


-- Metadata
ModalExt.name="ModalExt"
ModalExt.version="0.6"
ModalExt.author="Von Welch"
-- https://opensource.org/licenses/Apache-2.0
ModalExt.license="Apache-2.0"
ModalExt.homepage="https://github.com/von/ModalExt.spoon"


--- ModalExt.modifiers
--- Variable
--- Dictionary with keys that serve as aliases for all the various modifer key
--- combinations. "opt" is an alias for "alt".
--- Keys: none, ctrl, cmd, alt, opt, shift, altShift, optShift, cmdAlt,
--- cmdOpt, cmdShift, cmdCtrl, ctrlAlt, ctrlOpt, cmdCtrlShift, cmdAltShift,
--- cmdOptShift, cmdAltCtrl, cmdOptCtrl, cmdCtrlOptShift, all
ModalExt.modifiers = {
  none =            {},
  ctrl =            {'ctrl'},
  cmd =             {'cmd'},
  alt =             {'alt'},
  opt =             {'alt'},
  shift =           {'shift'},
  altShift =        {'alt', 'shift'},
  optShift =        {'alt', 'shift'},
  cmdAlt =          {'cmd', 'alt'},
  cmdOpt =          {'cmd', 'alt'},
  cmdShift =        {'cmd', 'shift'},
  ctrlShift =       {'ctrl', 'shift'},
  cmdCtrl =         {'cmd', 'ctrl'},
  ctrlAlt =         {'ctrl', 'alt'},
  ctrlOpt =         {'ctrl', 'alt'},
  cmdCtrlShift =    {'cmd', 'ctrl', 'shift'},
  cmdAltShift =     {'cmd', 'alt', 'shift'},
  cmdOptShift =     {'cmd', 'alt', 'shift'},
  cmdAltCtrl =      {'cmd', 'alt', 'ctrl'},
  cmdOptCtrl =      {'cmd', 'alt', 'ctrl'},
  cmdCtrlOptShift = {'cmd', 'alt', 'ctrl', 'shift' },
  all =             {'cmd', 'alt', 'ctrl', 'shift' },
  unicode = {
    ctrl =          "⌃",
    shift =         "⇧",
    cmd =           "⌘",
    alt =           "⌥",
    opt =           "⌥",
    all =           "⌃⇧⌘⌥"
  }
}


--- ModalExt:debug(enable)
--- Function
--- Enable or disable debugging
---
--- Parameters:
---  * enable - Boolean indicating whether debugging should be on
---
--- Returns:
---  * Nothing
function ModalExt:debug(enable)
  if enable then
    self.log.setLogLevel('debug')
    self.log.d("Debugging enabled")
  else
    self.log.d("Disabling debugging")
    self.log.setLogLevel('info')
  end
end

--- ModalExt:init()
--- Function
--- Initializes a ModalExt
---
--- Parameters:
---  * None
---
--- Returns:
---  * ModalExt object

function ModalExt:init()
  -- Set up logger for spoon
  self.log = hs.logger.new("ModalExt")

  -- Path to this file itself
  -- See also http://www.hammerspoon.org/docs/hs.spoons.html#resourcePath
  self.path = hs.spoons.scriptPath()

  -- Currently active modal
  self.activeModal = nil

  -- Timer for delayed cheatsheet
  self.cheatsheetTimer = nil

  -- Currently displayed cheetsheet
  self.cheatsheetBG = nil
  self.cheatsheetText = nil

  return self
end

--- ModalExt.defaults
--- Variable
--- Dictionary of defaults:
---   * showCheatsheet: Boolean, default is true
---   * cheatsheetDelay: Number of seconds, default is 0
---   * cheatsheetFadeTime: Number of seconds to fade in, default is .5
---   * cheatsheetFont: Table describing font as descrined in hs.styledtext
---   * cheatsheetBGColor: Table describing background color per
---     hs.drawing.color
---   * cheatsheetFGColor: Table describing foreground color per
---     hs.drawing.color
---   * cheatsheetParagraphStyle: Table describing the paragraph style
---     per hs.styledtext
---   * cheatsheetHMargin: horizontal margin between text and edge of
---     background in pixels
---   * cheatsheetVMargin: virtucal margin between text and edge of
---     background in pixels
ModalExt.defaults = {
  showCheatsheet = true,
  cheatsheetDelay = 0,
  cheatsheetFadeTime = .5,

  -- Cheatsheet Appearance
  cheatsheetFont = { name="Courier-Bold", size=16 },
  cheatsheetBGColor = { red=0, blue=0, green=0, alpha=0.5},
  cheatsheetFGColor = { list="ansiTerminalColors", name="fgWhite" },
  cheatsheetParagraphStyle = { lineSpacing=12.0, lineBreak='truncateMiddle' },
  -- Horizontal and vertical margins in pixels
  cheatsheetHMargin = 40,
  cheatsheetVMargin = 40,
}

--- ModalExt:start()
--- Function
--- Start background activity. Currently does nothing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ModalExt object
function ModalExt:start()
  -- No-op
  return self
end

--- ModalExt:stop()
--- Function
--- Stop background activity.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ModalExt object
function ModalExt:stop()
  self:hideCheatsheet()
  return self
end

--- ModalExt:new()
--- Constructor
--- Create a new modal hotkey using bindings from the given table.
--- Elements of modalConfig are:
---   * keys are strings descripbing keys to be active in modal
---     The key can be prefixed by modifiers as recognized by
---     hs.hotkey:bind()
---   * values are dictionary:
---     * mod: Optional table of modifers for key.
---     * func: Function to call when key pressed
---     * desc: Description of action
---
--- Example modalConfig:
--- ```lua
--- {
---  A = {
---    func = function() hs.alsert("A") end,
---    desc = "A key"
---  },
---  B = {
---    func = function() hs.alert("B") end,
---    desc = "B key"
---  },
---  ["shift-B"] = {
---    func = function() hs.alert("shift-B") end,
---    desc = "Shift-B key"
---  }
---}```
---
--- An empty modalConfig will result in a modal that shows the cheetsheet
--- for the base set of hotkeys. This can be useful in providing a help
--- function of sorts.
---
--- Parameters:
--- * mod: table with hotkey modifiers
--- * key: string with hotkey
--- * title: string with modal title
--- * modalConfig: Table with configuration
--- * extConfg: Optional dictionary with extended configuration, all optional.
---   See ModalExt.defaults for values.
---
--- Returns:
--- * hs.hotkey.modal instance
function ModalExt:new(mod, key, title, modalConfig, extConfig)
  self.log.df("Creating modal for %s (%s)", key, title)

  -- Defaults, overridden by extConfig
  local defaults = hs.fnutils.copy(ModalExt.defaults)
  if extConfig then
    for k,v in pairs(extConfig) do
      defaults[k] = v
    end
  end

  local modalKey = hs.hotkey.modal.new(mod, key, title)
  if not modalKey then
    self.log.e("Failed to create modalKey")
    return nil
  end

  -- Wrap function to exit modal before calling function
  local function wrapFunc(func)
    return function()
      modalKey:exit()
      local result, errormsg = xpcall(func, debug.traceback)
      if not result then
        self.log.e("Error executing hotkey: " .. errormsg)
        hs.alert.show("Error executing hotkey")
      end
    end
  end

  for mkey, conf in pairs(modalConfig) do
    local func = conf["func"]
    if func == nil then
      self.log.ef("Function for modal %s key %s is nil", key, mkey)
    else
      local mod = ""
      -- mkey could be any of the following formats:
      --   A single character
      --   A key name: ESCAPE, SPACE, TAB, etc. (upper or lower case)
      --   One or more symbolic modifiers (⌃⇧⌘⌥) followed by a character or
      --     key name.
      --   One or more modifier names, separared with dashes, followed by
      --     a character or key name ("shift-A", "shift-space").
      if mkey:match("-") and #mkey > 1 then
        -- Looks like we modifiers names
        -- Split on last occurence of "-"
        -- "#mkey > 1" avoids matching lone "-" charcter
        _,_,mod,mkey = mkey:find("^(.*)-([^-]*)$")
      elseif mkey:match("([⌃⇧⌘⌥]*)") then
        -- Looks like we have modifiers symbols. Split them off.
        _,_,mod,mkey = mkey:find("^([⌃⇧⌘⌥]*)(.*)$")
      else
        -- Assume key or key name. No parsing needed.
      end
      modalKey:bind(mod, mkey, conf["desc"], wrapFunc(func))
    end
  end

  -- Escape exits the modal
  modalKey:bind(self.modifiers.none, "escape", "Cancel",
    function() modalKey:exit() end)


  -- Callback for modal being entered. Exits other modal that may
  -- be active and show cheatsheet.
  modalKey.entered = function()
    if self.activeModal then
      self.activeModal:exit()
    end
    self.activeModal = modalKey
    if defaults.showCheatsheet then
        self.cheatsheetTimer = hs.timer.doAfter(
          defaults.cheatsheetDelay,
          function() self:showCheatsheet(defaults) end)
    end
  end

  -- Callback for modal being exited. Hide cheatsheet.
  modalKey.exited = function()
    self:hideCheatsheet()
    self.activeModal = nil
  end

  return modalKey
end

--- ModalExt:newWithoutHotkey()
--- Constructor
--- Create a new modal without binding it to a hotkey. This allows it to be
--- bound to a hotkey via hs.hotkey.new(), for example:
---
--- ```lua
--- hs.hotkey.new({"ctrl"}, "s", function() modal:enter() end)```
---
--- For a description of modalConfig, see ModalExt:new()
---
--- Parameters:
--- * modalConfig: Table with configuration
--- * extConfg: Optional dictionary with extended configuration, all optional.
---   See ModalExt.defaults for values.
---
--- Returns:
--- * hs.hotkey.modal instance
function ModalExt:newWithoutHotkey(modalConfig, extConfig)
  return self:new(nil, nil, nil, modalConfig, extConfig)
end

--- ModalExt:hideCheatsheet()
--- Method
--- Hide the cheatsheet.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function ModalExt:hideCheatsheet()
  if self.cheatsheetTimer then
    self.cheatsheetTimer:stop()
  end
  if self.cheatsheetBG then
    self.cheatsheetBG:delete()
    self.cheatsheetBG = nil
  end
  if self.cheatsheetTextLeft then
    self.cheatsheetTextLeft:delete()
    self.cheatsheetTextLeft = nil
  end
  if self.cheatsheetTextRight then
    self.cheatsheetTextRight:delete()
    self.cheatsheetTextRight = nil
  end
end

--- ModalExt:showCheatsheet()
--- Method
--- Show a cheatsheet with available hotkeys for the current modal.
---
--- Parameters:
--- * defaults: copy of ModalExt.defaults
---
--- Returns:
--- * Nothing
function ModalExt:showCheatsheet(defaults)
  -- Hide any outstanding cheatsheet
  -- This will also cancel any outstanding cheatsheet timer
  self:hideCheatsheet()

  -- The cheatsheet is constructed from three elements, a background rectangle
  -- and then two styled text elements, one for each of the columns of hotkeys
  -- to be displayed.

  local mainScreen = hs.screen.mainScreen()
  local mainRes = mainScreen:fullFrame()

  local rectBG = hs.geometry.rect(
    mainRes.w/5,
    mainRes.h/5,
    mainRes.w/5*3,
    mainRes.h/5*3)
  self.cheatsheetBG = hs.drawing.rectangle(rectBG)
  self.cheatsheetBG:setFillColor(defaults.cheatsheetBGColor)
  self.cheatsheetBG:setRoundedRectRadii(10, 10)
  self.cheatsheetBG:setLevel(hs.drawing.windowLevels.modalPanel)
  self.cheatsheetBG:setBehavior(hs.drawing.windowBehaviors.stationary)

  local rectLeft = hs.geometry.rect(
    rectBG.x + defaults.cheatsheetHMargin,
    rectBG.y + defaults.cheatsheetVMargin,
    (rectBG.w - defaults.cheatsheetHMargin)/2,
    rectBG.h - defaults.cheatsheetVMargin*2)
  self.cheatsheetTextLeft = hs.drawing.text(rectLeft, "")
  self.cheatsheetTextLeft:setLevel(hs.drawing.windowLevels.modalPanel)
  self.cheatsheetTextLeft:setBehavior(hs.drawing.windowBehaviors.stationary)

  local rectRight = hs.geometry.rect(
    rectBG.x + rectBG.w/2 + defaults.cheatsheetHMargin/2,
    rectBG.y + defaults.cheatsheetVMargin,
    (rectBG.w - defaults.cheatsheetHMargin)/2,
    rectBG.h - defaults.cheatsheetVMargin*2)
  self.cheatsheetTextRight = hs.drawing.text(rectRight, "")
  self.cheatsheetTextRight:setLevel(hs.drawing.windowLevels.modalPanel)
  self.cheatsheetTextRight:setBehavior(hs.drawing.windowBehaviors.stationary)

  -- Filter out all hotkeys which don't have a help string defined
  local hotkeys = hs.fnutils.filter(
    -- Use just hotkeys from modal if one is active.
    -- Note: 'keys' is not advertised in the API for hs.hotkey.modal
    --       so this could break at some point.
    self.activeModal and self.activeModal.keys or hs.hotkey.getHotKeys(),
    function(h) return h.msg ~= h.idx end)

  table.sort(hotkeys,
    function(a,b)
      -- Optimization: If both are single, unmodified keys, then
      -- sort alphabetically
      if #a.idx == 1 and #b.idx ==1 then return a.idx < b.idx end

      -- Split keys into modifiers and keys
      -- Note keys could be a single key or something like "ESCAPE"
      _, _, amod, akey = string.find(a.idx, "([⌃⇧⌘⌥]*)(.*)")
      _, _, bmod, bkey = string.find(b.idx, "([⌃⇧⌘⌥]*)(.*)")

      -- If keys aren't equal, then sort by key
      if akey ~= bkey then
        -- Sort by key length
        if #akey ~= #bkey then return #akey < #bkey end

        -- If same length, then sort alphabetically
        return akey < bkey
      end

      -- Same keys, sort by modifiers
      return amod < bmod
    end)

  local textLeft = ""
  local textRight = ""
  -- TODO: If we have more hotkeys than room to print them, they will
  -- silently be truncated. Handle this somehow.
  -- See https://github.com/von/ModalExt.spoon/issues/1
  for i=1,#hotkeys do
    if math.fmod(i, 2) == 1 then
      textLeft = textLeft .. hotkeys[i].msg .. "\n"
    else
      textRight = textRight .. hotkeys[i].msg .. "\n"
    end
  end

  local style = {
      font = defaults.cheatsheetFont,
      color = defaults.cheatsheetFGColor,
      paragraphStyle = defaults.cheatsheetParagraphStyle
    }
  local stextLeft = hs.styledtext.new(textLeft, style)
  self.cheatsheetTextLeft:setStyledText(stextLeft)
  local stextRight = hs.styledtext.new(textRight, style)
  self.cheatsheetTextRight:setStyledText(stextRight)

  self.cheatsheetBG:show(defaults.cheatsheetFadeTime)
  self.cheatsheetTextLeft:show(defaults.cheatsheetFadeTime)
  self.cheatsheetTextRight:show(defaults.cheatsheetFadeTime)
end

return ModalExt
