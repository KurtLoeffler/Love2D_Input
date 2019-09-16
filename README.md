# Love2D_Input
An input handling library for Love2D. Supports event or polling based interactions.

## Example usage
```lua

Input = require("Input.Input")

input = Input() --create an input handler instance.

input:addAction{
    name = "pan",
    triggers = {
        --triggers when mouse is moved while mouse button 3 OR space bar are held down.
        all = true, --require all sibling conditions to be true. default is "any".
        "mouse:delta", --condition 1, only true when the mouse is moved...
        --...as the first condition to evaluate true, mouse delta x/y values will be passed to events and polling returns.
        {
            --nested trigger 
            down = true, --trigger when while the following conditions are held down.
            "mouse:3", --mouse button 3 is held down.
            "space" --OR space bar is held down.
        }
    },
    events = {
        --events are called once per frame when triggers evaluate true.
        function(scrollX, scrollY)
            --note scrollY represents scroll wheel movement.
            print("panning mouse delta:", scrollX, scrollY)
        end
    }
}
input:addAction{
    name = "zoom",
    triggers = {
        --triggers when mouse scroll wheel is moved.
        "mouse:scroll"
    },
    events = {
        function(x, y)
            print("mouse scroll wheel:", x, y)
        end
    }
}
input:addAction{
    name = "save",
    triggers = {
        --triggers when "s" key is pressed AND any "ctrl" key is also held down.
        all = true,
        "s",
        {
            down = true,
            "ctrl"
        }
    },
    events = {
        function()
            print("save")
        end
    }
}

--hookup love2D events.
function love.keypressed(key, scancode, isRepeat)
    input:onKeyPressed(key, scancode, isRepeat)
end

function love.keyreleased(key, scancode)
    input:onKeyReleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
    input:onMousePressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    input:onMouseReleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    input:onMouseMoved(x, y, dx, dy, istouch)
end

function love.wheelmoved(x, y)
    input:onWheelMoved(x, y)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    input:onTouchPressed(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    input:onTouchReleased(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    input:onTouchMoved(id, x, y, dx, dy, pressure)
end

function love.update(deltaTime)
    input:onUpdate()
    --additional update logic

    local deltaX, deltaY = input:get("pan") --poll the "pan" action.
end

function love.draw()
    --additional draw logic
    input:onEndFrame()
end
```

## Requirements
**middleclass** is required with a global `class()` defined at the time of import.
