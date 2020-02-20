PickOne = {

}
function PickOne:new()
    local instance = {
        begin = vector2(0.2, 0.3),
        fontSize = 0.3,
        widest = 0.0,
        verticalSpace = 0.04,
        verticalOffset = -0.003,
        itemHeight = 0.029,
        buttons = {},
        colors = {
            idle = {
                button = {255, 255, 255, 100},
                text = {0,0,0,255},
            },
            active = {
                button = {255, 255, 255, 200},
                text = {255, 255, 0, 255},
            },
        },
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end
function PickOne:_disableControls()
    for i=0, 31 do
        DisableAllControlActions(i)
    end
end
function PickOne:_buttonTextMeta(text, highlighted)
    SetTextCentre(false)
    SetTextFont(0)
    SetTextScale(self.fontSize, self.fontSize)
    AddTextComponentSubstringPlayerName(text)
    if highlighted then
        SetTextOutline(true)
        SetTextColour(table.unpack(self.colors.active.text))
    else
        SetTextColour(table.unpack(self.colors.idle.text))
    end
end
function PickOne:_drawButton(aspectRatio, cursor, button, mouseX, mouseY)

    local left = cursor.x
    local right = cursor.x + self.widest
    local top = cursor.y + -self.itemHeight/2
    local bottom = cursor.y + self.itemHeight/2

    local hover = false

    if mouseX < right and mouseX > left then
        if mouseY < bottom and mouseY > top then
            hover = true
        end
    end

    r,g,b,a = table.unpack(self.colors.idle.button)
    if hover then
        r,g,b,a = table.unpack(self.colors.active.button)
    end

    DrawRect(
        cursor.x + (self.widest/2), cursor.y + self.itemHeight/2,
        self.widest, self.itemHeight,
        r, g, b, a
    )

    BeginTextCommandDisplayText('STRING')
    self:_buttonTextMeta(button.label, hover)
    EndTextCommandDisplayText(cursor.x, cursor.y)
    return hover
end
function PickOne:_draw(mouseX, mouseY)
    local cursor = vector2(self.begin.x, self.begin.y)
    local hoveredButton = nil
    local aspectRatio = GetAspectRatio(true)
    for index, button in pairs(self.buttons) do
        local hovered = self:_drawButton(aspectRatio, cursor, button, mouseX, mouseY)
        if hovered then
            hoveredButton = button
        end
        cursor = vector2(cursor.x, self.verticalSpace + cursor.y)
    end
    return hoveredButton
end
function PickOne:addButton(raw)
    local button = {
        label = raw.label or '(Unknown)',
        value = raw.value, -- nil and false are allowed!
    }
    table.insert(self.buttons, button)
    BeginTextCommandWidth('STRING')
    self:_buttonTextMeta(button.label, true)
    local width = EndTextCommandGetWidth(false)
    if width > self.widest then
        self.widest = width
    end
end

function PickOne:pick()
    Citizen.Wait(0)
    local active = true
    while active do
        SetMouseCursorActiveThisFrame()
        local cursorX = GetDisabledControlNormal(0, 239)
        local cursorY = GetDisabledControlNormal(0, 240)
        self:_disableControls()
        local hoveredButton = self:_draw(cursorX,cursorY)
        if IsDisabledControlJustPressed(0, 24) then
            Citizen.Wait(0) -- So that click doesn't also happen in the requesting loop
            if hoveredButton then
                return hoveredButton.value
            else
                return
            end
        elseif IsDisabledControlJustPressed(0, 25) then
            active = false
        end
        Citizen.Wait(0)
    end
end