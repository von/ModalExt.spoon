--- === ModalExt ===
--- Extended hotkey modal support.
--- Kudos for cheatsheet: https://github.com/ashfinal/awesome-hammerspoon

local ModalExt = {}


-- Metadata
ModalExt.name="ModalExt"
ModalExt.version="0.1"
ModalExt.author="Von Welch"
-- https://opensource.org/licenses/Apache-2.0
ModalExt.license="Apache-2.0"
ModalExt.homepage=""

--- ModalExt.some_variable
--- Variable
--- Some exposed configuration variable.
ModalExt.some_variable = 42

--- ModalExt:debug(enable)
--- Method
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
--- Method
--- Initializes a ModalExt
--- When a user calls hs.loadSpoon(), Hammerspoon will execute init()
--- Do generally not perform any work, map any hotkeys, start any timers/watchers/etc.
--- in the main scope of your init.lua. Instead, it should simply prepare an object
--- with methods to be used later, then return the object.
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

  -- Currently displayed cheetsheet
  self.cheatsheetBG = nil
  self.cheatsheetText = nil

  -- Cheatsheet configuration
  self.cheatsheetFont = { name="Courier-Bold", size=16 }
  self.cheatsheetBGColor = { red=0, blue=0, green=0, alpha=0.5}
  self.cheatsheetFGColor = { list="ansiTerminalColors", name="fgWhite" }
  self.cheatsheetParagraphStyle = { lineSpacing=12.0, lineBreak='truncateMiddle' }
  -- Horizontal and vertical margins in pixels
  self.cheatsheetHMargin = 40
  self.cheatsheetVMargin = 40
  -- Width in characters
  self.cheatsheetWidth = 70

  return self
end

--start() and stop()
--If your Spoon provides some kind of background activity, e.g. timers, watchers,
--spotlight searches, etc. you should generally activate them in a :start()
--method, and de-activate them in a :stop() method

--- ModalExt:start()
--- Method
--- Start background activity.
---
--- Parameters:
---  * param - Some parameter
---
--- Returns:
---  * ModalExt object
function ModalExt:start()
  -- Code here
  return self
end

--- ModalExt:stop()
--- Method
--- Stop background activity.
---
--- Parameters:
---  * param - Some parameter
---
--- Returns:
---  * ModalExt object
function ModalExt:stop()
  -- Code here
  return self
end

--- ModalExt:new()
--- Method
--- Create a new modal hotkey using bindings from the given table. Table elements are
--- as follows:
---   * mod: table with hotkey modifiers
---   * key: string with hotkey
---   * title: string with modal title
---   * keyTable: Dictionary
---     * keys are strings descripbing keys to be active in modal
---     * values are dictionary:
---       * mod: Optional table of modifers for key.
---       * func: Function to call when key pressed
---       * desc: Description of action
---
--- Parameters:
--- * modalConfig: Table with configuration
---
--- Returns:
--- * hs.hotkey.modal instance
function ModalExt:new(mod, key, title, modalConfig)
  self.log.df("Creating modal for %s (%s)", key, title)
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
        log.e("Error executing hotkey: " .. errormsg)
        hs.alert.show("Error executing hotkey")
      end
    end
  end

  for mkey, conf in pairs(modalConfig) do
    local func = conf["func"]
    if func == nil then
      log.ef("Function for modal %s key %s is nil", key, mkey)
    else
      local mod = conf["mod"] or NoMod
      modalKey:bind(mod, mkey, conf["desc"], wrapFunc(func))
    end
  end

  -- Escape exits the modal
  modalKey:bind(NoMod, "escape", "Cancel", function() modalKey:exit() end)

-- Callback for modal being entered. Exits other modal that may
-- be active and show cheatsheet.
  modalKey.entered = function()
    if self.activeModal then
      self.activeModal:exit()
    end
    self.activeModal = modalKey
    self:showCheatsheet()
  end

  -- Callback for modal being exited. Hide cheatsheet.
  modalKey.exited = function()
    self:hideCheatsheet()
    self.activeModal = nil
  end

  return modalKey
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
  -- The disableScreenUpdates() and subsequent enableScreenUpdates()
  -- seems to make sure the help text actually gets off the screen
  -- before we execute our function, which is important if we're
  -- doing something such as a screen capture.
  hs.drawing.disableScreenUpdates()
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
  hs.drawing.enableScreenUpdates()
end

--- ModalExt:showCheatsheet()
--- Method
--- Show a cheatsheet with available hotkeys for the current modal.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function ModalExt:showCheatsheet()
  self:hideCheatsheet()

  -- The cheatsheet is constructed from three elements, a background rectangle
  -- and then two styled text elements, one for each of the columns of hotkeys
  -- to be displayed.

  local mainScreen = hs.screen.mainScreen()
  local mainRes = mainScreen:fullFrame()

  local rectBG = hs.geometry.rect(mainRes.w/5, mainRes.h/5, mainRes.w/5*3, mainRes.h/5*3)
  self.cheatsheetBG = hs.drawing.rectangle(rectBG)
  self.cheatsheetBG:setFillColor(self.cheatsheetBGColor)
  self.cheatsheetBG:setRoundedRectRadii(10, 10)
  self.cheatsheetBG:setLevel(hs.drawing.windowLevels.modalPanel)
  self.cheatsheetBG:setBehavior(hs.drawing.windowBehaviors.stationary)

  local rectLeft = hs.geometry.rect(
    rectBG.x + self.cheatsheetHMargin,
    rectBG.y + self.cheatsheetVMargin,
    (rectBG.w - self.cheatsheetHMargin)/2,
    (rectBG.h - self.cheatsheetVMargin)/2)
  self.cheatsheetTextLeft = hs.drawing.text(rectLeft, "")
  self.cheatsheetTextLeft:setLevel(hs.drawing.windowLevels.modalPanel)
  self.cheatsheetTextLeft:setBehavior(hs.drawing.windowBehaviors.stationary)

  local rectRight = hs.geometry.rect(
    rectBG.x + rectBG.w/2 + self.cheatsheetHMargin/2,
    rectBG.y + self.cheatsheetVMargin,
    (rectBG.w - self.cheatsheetHMargin)/2,
    (rectBG.h - self.cheatsheetVMargin)/2)
  self.cheatsheetTextRight = hs.drawing.text(rectRight, "")
  self.cheatsheetTextRight:setLevel(hs.drawing.windowLevels.modalPanel)
  self.cheatsheetTextRight:setBehavior(hs.drawing.windowBehaviors.stationary)

  local hotkeys = hs.hotkey.getHotkeys()
  local textLeft = ""
  local textRight = ""
  for i=1,#hotkeys do
    if math.fmod(i, 2) == 1 then
      textLeft = textLeft .. hotkeys[i].msg .. "\n"
    else
      textRight = textRight .. hotkeys[i].msg .. "\n"
    end
  end

  local style = {
      font = self.cheatsheetFont,
      color = self.cheatsheetFGColor,
      paragraphStyle = self.cheatsheetParagraphStyle
    }
  local stextLeft = hs.styledtext.new(textLeft, style)
  self.cheatsheetTextLeft:setStyledText(stextLeft)
  local stextRight = hs.styledtext.new(textRight, style)
  self.cheatsheetTextRight:setStyledText(stextRight)

  self.cheatsheetBG:show()
  self.cheatsheetTextLeft:show()
  self.cheatsheetTextRight:show()
end

return ModalExt
