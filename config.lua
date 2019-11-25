Config = {
    Permission = 'demmycam', -- add_ace group.admin demmycam allow
    BoostFactor = 10.0,
    Sensitivity = 5.0,
    Conceal = false,
    Speed = {
        Min = 5,
        Start = 10,
        Max = 100,
        Interval = 5,
    },
    EnableInCam = {245, 249}, -- What controls are enabled while in cam? 245 is INPUT_MP_TEXT_CHAT_ALL, and 249  is INPUT_PUSH_TO_TALK
    UseModifier = false,
    Keys = {
        Modifier = 21, -- INPUT_SPRINT, Left Shift
        Toggle = 199, -- INPUT_FRONTEND_PAUSE, P
        Boost = 21, -- INPUT_SPRINT, Left Shift
        Teleport = 37, -- INPUT_SELECT_WEAPON, Tab
        SlowDown = 44, -- INPUT_COVER, Q
        SpeedUp = 38, -- INPUT_PICKUP, E
        SwitchMode = 25, -- INPUT_AIM, right click
        Forward = 32, -- W
        Back = 33, -- S
        Left = 34, -- A
        Right = 35, -- D
        Up = 22, -- INPUT_JUMP, Space
        Down = 36, -- INPUT_DUCK
    },
}
