local Input = class("Input")

function Input:initialize()
	self.actions = {}

	self.pressedMouseButtons = {}
	self.downMouseButtons = {}
	self.releasedMouseButtons = {}
	
	self.pressedKeys = {}
	self.downKeys = {}
	self.releasedKeys = {}
	self.touches = {}
	
	self.mouseDelta = {x = 0, y = 0}
	self.mouseScroll = {x = 0, y = 0}

	self.mouseScale = 1
end

function Input:addAction(action)
	assert(type(action) == "table" and type(action.name) == "string", "action must be a table containing a \"name\" key with string value")
	
	action.triggers = action.triggers or {}
	action.events = action.events or {}
	action.filters = action.filters or {}
	
	assert(type(action.triggers) == "table", "action.triggers must be a table")
	assert(type(action.events) == "table", "action.events must be a table")
	assert(type(action.filters) == "table", "action.filters must be a table")
	
	self.actions[action.name] = action
end

function Input:getAction(name)
	for _, v in pairs(self.actions) do
		if v.name == name then
			return v
		end
	end
end

function Input:keyMouseButtonTriggerTest(trigger, keyFunc, mouseFunc)
	local v1, v2
	v1, v2 = keyFunc(self, trigger)
	if v1 or v2 then return v1, v2 end

	v1, v2 = mouseFunc(self, trigger)
	if v1 or v2 then return v1, v2 end
end

function Input:evaluateTriggerTable(triggerTable)
	local onPressed = triggerTable.pressed
	local onDown = triggerTable.down
	local onReleased = triggerTable.released

	if onPressed == nil and onDown == nil and onReleased == nil then
		onPressed = true
	end

	local requireAll = triggerTable.all
	local value1, value2
	
	for _,v in ipairs(triggerTable) do
		local v1, v2
		local vType = type(v)
		
		if vType == "table" then
			v1, v2 = self:evaluateTriggerTable(v)
		elseif vType == "function" then
			local success
			success, v1, v2 = pcall(v)
			if not success then
				print("action trigger error:\n"..v1)
				v1 = nil
			end
		elseif vType == "string" then
			v1, v2 = self:mouseAxisIfActive(v)
			if not v1 and onPressed then
				v1, v2 = self:keyMouseButtonTriggerTest(v, self.keyPressed, self.mousePressed)
			end
			if not v1 and onDown then
				v1, v2 = self:keyMouseButtonTriggerTest(v, self.keyDown, self.mouseDown)
			end
			if not v1 and onReleased then
				v1, v2 = self:keyMouseButtonTriggerTest(v, self.keyReleased, self.mouseReleased)
			end
		end
		
		if v1 then
			if not value1 then
				value1, value2 = v1, v2
			end

			if not requireAll then
				break
			end
		else
			if requireAll then
				value1, value2 = nil, nil
				break
			end
		end
	end

	return value1, value2
end

function Input:evaluateTriggers(action)
	return self:evaluateTriggerTable(action.triggers)
end

function Input:evaluateFilters(action)
	for i,filter in ipairs(action.filters) do
		if type(filter) == "function" then
			if not filter() then
				return false
			end
		end
	end
	return true
end

function Input:invokeEvents(action, v1, v2)
	for i, event in ipairs(action.events) do
		local res, err = true, nil
		if type(event) == "function" then
			res, err = pcall(event, v1, v2)
		end
		if not res then
			print("action event error in \""..action.name.."\" event "..i..":\n"..err)
		end
	end
end

function Input:get(action)
	if type(action) == "string" then
		return self:get(self:getAction(action))
	end
	assert(type(action) == "table")

	if not self:evaluateFilters(action) then
		return
	end

	return self:evaluateTriggers(action)
end

local mouseNameIndexDict = {}
for i=1,32 do
	local name = "mouse:"..i
	mouseNameIndexDict[i] = name
	mouseNameIndexDict[name] = i
end

local function testKey(keyTable, key)
	local keyValue = false
	if key == "ctrl" then
		keyValue = keyTable["lctrl"] or keyTable["rctrl"]
	elseif key == "shift" then
		keyValue = keyTable["lshift"] or keyTable["rshift"]
	elseif key == "alt" then
		keyValue = keyTable["lalt"] or keyTable["ralt"]
	else
		keyValue = keyTable[key]
	end
	return keyValue
end

function Input:keyPressed(key)
	return testKey(self.pressedKeys, key)
end

function Input:keyDown(key)
	return testKey(self.downKeys, key)
end

function Input:keyReleased(key)
	return testKey(self.releasedKeys, key)
end

function Input:mousePressed(button)
	if type(button) == "string" then
		button = mouseNameIndexDict[button]
	end
	return self.pressedMouseButtons[button] ~= nil
end

function Input:mouseDown(button)
	if type(button) == "string" then
		button = mouseNameIndexDict[button]
	end
	return self.downMouseButtons[button] ~= nil
end

function Input:mouseReleased(button)
	if type(button) == "string" then
		button = mouseNameIndexDict[button]
	end
	return self.releasedMouseButtons[button] ~= nil
end

function Input:mouseAxisIfActive(name)
	if name == "mouse:delta" and (self.mouseDelta.x ~= 0 or self.mouseDelta.y ~= 0) then
		return self.mouseDelta.x*self.mouseScale, self.mouseDelta.y*self.mouseScale
	end
	if name == "mouse:deltaUnscaled" and (self.mouseDelta.x ~= 0 or self.mouseDelta.y ~= 0) then
		return self.mouseDelta.x, self.mouseDelta.y
	end
	if name == "mouse:scroll" and (self.mouseScroll.x ~= 0 or self.mouseScroll.y ~= 0) then
		return self.mouseScroll.x, self.mouseScroll.y
	end
end

function Input:mouseX(unscaled)
	return love.mouse.getX()*(unscaled and 1 or self.mouseScale)
end

function Input:mouseY(unscaled)
	return love.mouse.getY()*(unscaled and 1 or self.mouseScale)
end

function Input:mousePosition(unscaled)
	return self:mouseX(unscaled), self:mouseY(unscaled)
end

function Input:getTouch(id)
	for i,v in ipairs(self.touches) do
		if v.id == id then
			return v
		end
	end
end

function Input:onKeyPressed(key, scancode, isRepeat)
	self.pressedKeys[key] = true
	self.downKeys[key] = true
end

function Input:onKeyReleased(key, scancode)
	self.releasedKeys[key] = true
	self.downKeys[key] = nil
end

function Input:onMousePressed(x, y, button, istouch, presses)
	self.pressedMouseButtons[button] = presses
	self.downMouseButtons[button] = presses
end

function Input:onMouseReleased(x, y, button, istouch, presses)
	self.releasedMouseButtons[button] = presses
	self.downMouseButtons[button] = nil
end

function Input:onMouseMoved(x, y, dx, dy, istouch)
	self.mouseDelta.x = self.mouseDelta.x+dx
	self.mouseDelta.y = self.mouseDelta.y+dy
end

function Input:onWheelMoved(x, y)
	self.mouseScroll.x = self.mouseScroll.x+x
	self.mouseScroll.y = self.mouseScroll.y+y
end

function Input:onTouchPressed(id, x, y, dx, dy, pressure)
	local touch = self:getTouch(id)
	assert(not touch)
	touch = {id = id}
	touch.phase = "pressed"
	touch.x, touch.y = x, y
	touch.dx, touch.dy = dx, dy
	touch.pressure = pressure
end

function Input:onTouchReleased(id, x, y, dx, dy, pressure)
	local touch = self:getTouch(id)
	touch.phase = "released"
	touch.x, touch.y = x, y
	touch.dx, touch.dy = dx, dy
	touch.pressure = pressure
end

function Input:onTouchMoved(id, x, y, dx, dy, pressure)
	local touch = self:getTouch(id)
	touch.x, touch.y = x, y
	touch.dx, touch.dy = dx, dy
	touch.pressure = pressure
end

function Input:onUpdate()
	for _, action in pairs(self.actions) do
		if self:evaluateFilters(action) then
			local v1, v2 = self:evaluateTriggers(action)
			if self:evaluateTriggers(action) then
				self:invokeEvents(action, v1, v2)
			end
		end
	end
end

function Input:onEndFrame()
	for k,v in pairs(self.pressedMouseButtons) do
		self.pressedMouseButtons[k] = nil
	end
	for k,v in pairs(self.releasedMouseButtons) do
		self.releasedMouseButtons[k] = nil
	end

	for k,v in pairs(self.pressedKeys) do
		self.pressedKeys[k] = nil
	end

	for k,v in pairs(self.releasedKeys) do
		self.releasedKeys[k] = nil
	end
	
	self.mouseDelta.x = 0
	self.mouseDelta.y = 0
	self.mouseScroll.x = 0
	self.mouseScroll.y = 0

	for i=#self.touches, 1, -1 do
		local touch = self.touches[i]
		if touch.phase == "released" then
			table.remove(self.touches, i)
		elseif touch.phase == "pressed" then
			touch.phase = "active"
		end
	end
end

return Input
