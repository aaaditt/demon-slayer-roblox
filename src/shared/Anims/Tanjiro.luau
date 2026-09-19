-- Tanjiro's sword kit keyframes (pure data; no requires). Format: see src/shared/AnimData.luau.
-- Right-handed two-hand grip; blade runs along the right hand's -Z axis. Degrees; stud offsets on Root.
-- M1 string follows kenjutsu cuts: kesa-giri, gyaku-kesa, yoko-giri, then an overhead kara-take-wari finisher.

-- Shared stances --------------------------------------------------------------------------
-- Chudan (mid guard): both hands forward at the navel, blade angled up toward the opponent's eyes.
local CHUDAN = {
    Root = {0, 0, 0, 0, -0.15, 0}, Waist = {0, 12, 0}, Neck = {0, -10, 0},
    RightShoulder = {48, 0, -12}, RightElbow = {28, 0, 0}, RightWrist = {-8, 0, 0},
    LeftShoulder = {52, 0, 30}, LeftElbow = {40, 0, 0}, LeftWrist = {-8, 0, 0},
    RightHip = {14, 0, 4}, RightKnee = {-14, 0, 0}, LeftHip = {-12, 0, -4}, LeftKnee = {-10, 0, 0},
}
-- Right hand crossed to the hilt on the left hip, left hand holding the saya mouth.
local AT_HILT = {
    Root = {0, 0, 0, 0, -0.1, 0}, Waist = {0, 22, 0}, Neck = {0, -18, 0},
    RightShoulder = {32, 0, -48}, RightElbow = {62, 0, 0}, RightWrist = {0, 0, 0},
    LeftShoulder = {18, 0, 18}, LeftElbow = {38, 0, 0}, LeftWrist = {0, 0, 0},
    RightHip = {8, 0, 0}, RightKnee = {-8, 0, 0}, LeftHip = {-6, 0, 0}, LeftKnee = {-6, 0, 0},
}
local NEUTRAL = {
    Root = {0, 0, 0}, Waist = {0, 0, 0}, Neck = {0, 0, 0},
    RightShoulder = {0, 0, 0}, RightElbow = {0, 0, 0}, RightWrist = {0, 0, 0},
    LeftShoulder = {0, 0, 0}, LeftElbow = {0, 0, 0}, LeftWrist = {0, 0, 0},
    RightHip = {0, 0, 0}, RightKnee = {0, 0, 0}, LeftHip = {0, 0, 0}, LeftKnee = {0, 0, 0},
}
local LYING = {
    Root = {82, 0, 0, 0, -2.3, 0.6}, Waist = {6, 0, 0}, Neck = {-10, 0, 0},
    RightShoulder = {150, 0, 20}, RightElbow = {10, 0, 0}, LeftShoulder = {150, 0, -20}, LeftElbow = {10, 0, 0},
    RightHip = {6, 0, 6}, RightKnee = {-10, 0, 0}, LeftHip = {-4, 0, -6}, LeftKnee = {-20, 0, 0},
}
local HIT_BOX = {length = 8, width = 7, height = 6, forwardOffset = 4, tolerance = 1.5}
local ARMS = {"Waist", "Neck", "RightShoulder", "RightElbow", "RightWrist", "LeftShoulder", "LeftElbow", "LeftWrist"}

local function k(t, pose, easing) return {t = t, pose = pose, easing = easing or "inout"} end

local set = {}

-- Stances ---------------------------------------------------------------------------------
set.idle_sheathed = {
    duration = 2, loop = true, priority = "Idle", mask = {"LeftShoulder", "LeftElbow", "LeftWrist"},
    keyframes = {k(0, {LeftShoulder = {18, 0, 18}, LeftElbow = {38, 0, 0}}), k(1, {LeftShoulder = {20, 0, 17}, LeftElbow = {40, 0, 0}}), k(2, {LeftShoulder = {18, 0, 18}, LeftElbow = {38, 0, 0}})},
    markers = {},
}
set.idle_drawn = {
    duration = 2, loop = true, priority = "Idle", mask = ARMS,
    keyframes = {k(0, CHUDAN), k(1, {
        Root = {0, 0, 0, 0, -0.2, 0}, Waist = {2, 12, 0}, Neck = {0, -10, 0},
        RightShoulder = {50, 0, -12}, RightElbow = {30, 0, 0}, RightWrist = {-8, 0, 0},
        LeftShoulder = {54, 0, 30}, LeftElbow = {42, 0, 0}, LeftWrist = {-8, 0, 0},
        RightHip = {14, 0, 4}, RightKnee = {-14, 0, 0}, LeftHip = {-12, 0, -4}, LeftKnee = {-10, 0, 0},
    }), k(2, CHUDAN)},
    markers = {},
}
set.block = {
    duration = 1, loop = true, priority = "Action",
    -- Blade held flat across the body, left palm braced behind the spine of the blade.
    keyframes = {k(0, {
        Root = {-6, 0, 0, 0, -0.35, 0}, Waist = {0, 8, 0}, Neck = {6, 0, 0},
        RightShoulder = {92, 0, -18}, RightElbow = {58, 0, 0}, RightWrist = {0, 0, 88},
        LeftShoulder = {92, 0, 38}, LeftElbow = {72, 0, 0}, LeftWrist = {0, 0, -20},
        RightHip = {16, 0, 6}, RightKnee = {-22, 0, 0}, LeftHip = {-14, 0, -6}, LeftKnee = {-18, 0, 0},
    }), k(1, {
        Root = {-6, 0, 0, 0, -0.38, 0}, Waist = {0, 8, 0}, Neck = {6, 0, 0},
        RightShoulder = {92, 0, -18}, RightElbow = {58, 0, 0}, RightWrist = {0, 0, 88},
        LeftShoulder = {92, 0, 38}, LeftElbow = {72, 0, 0}, LeftWrist = {0, 0, -20},
        RightHip = {16, 0, 6}, RightKnee = {-22, 0, 0}, LeftHip = {-14, 0, -6}, LeftKnee = {-18, 0, 0},
    })},
    markers = {},
}

-- Draw / sheathe -----------------------------------------------------------------------------
set.draw = {
    duration = 0.35, priority = "Action",
    keyframes = {
        k(0, NEUTRAL),
        k(0.12, AT_HILT, "out"),
        -- Iai-style pull: the blade leaves the saya on a rising diagonal before settling into chudan.
        k(0.22, {
            Root = {0, 0, 0, 0, -0.2, 0}, Waist = {0, -18, 0}, Neck = {0, 6, 0},
            RightShoulder = {88, 0, 36}, RightElbow = {10, 0, 0}, RightWrist = {-20, 0, 0},
            LeftShoulder = {20, 0, 12}, LeftElbow = {30, 0, 0},
            RightHip = {12, 0, 4}, RightKnee = {-12, 0, 0}, LeftHip = {-10, 0, -4}, LeftKnee = {-8, 0, 0},
        }, "out"),
        k(0.35, CHUDAN, "inout"),
    },
    markers = {Grip = 0.14, End = 0.35},
}
set.sheathe = {
    duration = 0.5, priority = "Action",
    keyframes = {
        k(0, CHUDAN),
        -- Chiburi: a sharp flick to shed blood before returning the blade.
        k(0.15, {
            Root = {0, 0, 0, 0, -0.2, 0}, Waist = {0, -14, 0}, Neck = {0, 8, 0},
            RightShoulder = {70, 0, 42}, RightElbow = {12, 0, 0}, RightWrist = {-30, 0, 0},
            LeftShoulder = {20, 0, 12}, LeftElbow = {30, 0, 0},
            RightHip = {12, 0, 4}, RightKnee = {-12, 0, 0}, LeftHip = {-10, 0, -4}, LeftKnee = {-8, 0, 0},
        }, "out"),
        k(0.36, AT_HILT, "inout"),
        k(0.5, NEUTRAL, "inout"),
    },
    markers = {Release = 0.38, End = 0.5},
}

-- M1 string ---------------------------------------------------------------------------------
-- 1. Kesa-giri: diagonal cut from above the right shoulder down through the left hip.
set.m1_1 = {
    duration = 0.42, priority = "Action", hitbox = HIT_BOX, swing = "right",
    keyframes = {
        k(0, CHUDAN),
        k(0.1, {
            Root = {4, 0, 0, 0, -0.1, 0}, Waist = {-6, -32, 0}, Neck = {0, 26, 0},
            RightShoulder = {150, 0, 34}, RightElbow = {42, 0, 0}, RightWrist = {-20, 0, 0},
            LeftShoulder = {140, 0, 8}, LeftElbow = {50, 0, 0},
            RightHip = {-8, 0, 6}, RightKnee = {-8, 0, 0}, LeftHip = {18, 0, -4}, LeftKnee = {-12, 0, 0},
        }, "out"),
        k(0.2, {
            Root = {-10, 0, 0, 0, -0.35, -0.5}, Waist = {10, 30, 0}, Neck = {0, -24, 0},
            RightShoulder = {38, 0, -42}, RightElbow = {8, 0, 0}, RightWrist = {10, 0, 0},
            LeftShoulder = {44, 0, 12}, LeftElbow = {20, 0, 0},
            RightHip = {-12, 0, 6}, RightKnee = {-14, 0, 0}, LeftHip = {30, 0, -4}, LeftKnee = {-30, 0, 0},
        }, "in"),
        k(0.42, {
            Root = {-6, 0, 0, 0, -0.3, -0.3}, Waist = {6, 24, 0}, Neck = {0, -18, 0},
            RightShoulder = {32, 0, -38}, RightElbow = {12, 0, 0}, RightWrist = {6, 0, 0},
            LeftShoulder = {40, 0, 14}, LeftElbow = {22, 0, 0},
            RightHip = {-10, 0, 6}, RightKnee = {-12, 0, 0}, LeftHip = {24, 0, -4}, LeftKnee = {-24, 0, 0},
        }, "out"),
    },
    markers = {Hit = 0.16, CanChain = 0.28, End = 0.42},
}
-- 2. Gyaku-kesa: reverse diagonal rising from the left hip to above the right shoulder.
set.m1_2 = {
    duration = 0.42, priority = "Action", hitbox = HIT_BOX, swing = "left",
    keyframes = {
        k(0, {
            Root = {-6, 0, 0, 0, -0.3, -0.3}, Waist = {6, 24, 0}, Neck = {0, -18, 0},
            RightShoulder = {32, 0, -38}, RightElbow = {12, 0, 0}, RightWrist = {6, 0, 0},
            LeftShoulder = {40, 0, 14}, LeftElbow = {22, 0, 0},
            RightHip = {-10, 0, 6}, RightKnee = {-12, 0, 0}, LeftHip = {24, 0, -4}, LeftKnee = {-24, 0, 0},
        }),
        k(0.08, {
            Root = {-4, 0, 0, 0, -0.45, -0.2}, Waist = {8, 38, 0}, Neck = {0, -26, 0},
            RightShoulder = {18, 0, -50}, RightElbow = {20, 0, 0}, RightWrist = {20, 0, 0},
            LeftShoulder = {26, 0, 18}, LeftElbow = {28, 0, 0},
            RightHip = {20, 0, 6}, RightKnee = {-26, 0, 0}, LeftHip = {-10, 0, -4}, LeftKnee = {-16, 0, 0},
        }, "out"),
        k(0.2, {
            Root = {6, 0, 0, 0, -0.05, -0.6}, Waist = {-8, -34, 0}, Neck = {0, 24, 0},
            RightShoulder = {142, 0, 48}, RightElbow = {18, 0, 0}, RightWrist = {-26, 0, 0},
            LeftShoulder = {118, 0, 4}, LeftElbow = {34, 0, 0},
            RightHip = {28, 0, 6}, RightKnee = {-20, 0, 0}, LeftHip = {-16, 0, -4}, LeftKnee = {-10, 0, 0},
        }, "in"),
        k(0.42, {
            Root = {2, 0, 0, 0, -0.1, -0.4}, Waist = {-4, -24, 0}, Neck = {0, 18, 0},
            RightShoulder = {120, 0, 40}, RightElbow = {26, 0, 0}, RightWrist = {-18, 0, 0},
            LeftShoulder = {104, 0, 8}, LeftElbow = {38, 0, 0},
            RightHip = {22, 0, 6}, RightKnee = {-16, 0, 0}, LeftHip = {-12, 0, -4}, LeftKnee = {-10, 0, 0},
        }, "out"),
    },
    markers = {Hit = 0.16, CanChain = 0.28, End = 0.42},
}
-- 3. Yoko-giri: flat horizontal cut from right to left, hips and chest driving the blade.
set.m1_3 = {
    duration = 0.42, priority = "Action", hitbox = {length = 8, width = 9, height = 6, forwardOffset = 4, tolerance = 1.5}, swing = "right",
    keyframes = {
        k(0, {
            Root = {2, 0, 0, 0, -0.1, -0.4}, Waist = {-4, -24, 0}, Neck = {0, 18, 0},
            RightShoulder = {120, 0, 40}, RightElbow = {26, 0, 0}, RightWrist = {-18, 0, 0},
            LeftShoulder = {104, 0, 8}, LeftElbow = {38, 0, 0},
            RightHip = {22, 0, 6}, RightKnee = {-16, 0, 0}, LeftHip = {-12, 0, -4}, LeftKnee = {-10, 0, 0},
        }),
        k(0.1, {
            Root = {0, 0, 0, 0, -0.35, 0}, Waist = {0, -48, 0}, Neck = {0, 36, 0},
            RightShoulder = {88, 0, 70}, RightElbow = {18, 0, 0}, RightWrist = {0, 0, 86},
            LeftShoulder = {84, 0, 40}, LeftElbow = {40, 0, 0},
            RightHip = {10, 0, 8}, RightKnee = {-22, 0, 0}, LeftHip = {-8, 0, -8}, LeftKnee = {-22, 0, 0},
        }, "out"),
        k(0.2, {
            Root = {-4, 0, 0, 0, -0.4, -0.4}, Waist = {0, 50, 0}, Neck = {0, -36, 0},
            RightShoulder = {86, 0, -52}, RightElbow = {6, 0, 0}, RightWrist = {0, 0, 86},
            LeftShoulder = {80, 0, 10}, LeftElbow = {16, 0, 0},
            RightHip = {-10, 0, 8}, RightKnee = {-16, 0, 0}, LeftHip = {26, 0, -8}, LeftKnee = {-28, 0, 0},
        }, "in"),
        k(0.42, {
            Root = {-2, 0, 0, 0, -0.35, -0.3}, Waist = {0, 40, 0}, Neck = {0, -28, 0},
            RightShoulder = {80, 0, -40}, RightElbow = {14, 0, 0}, RightWrist = {0, 0, 70},
            LeftShoulder = {76, 0, 14}, LeftElbow = {22, 0, 0},
            RightHip = {-8, 0, 8}, RightKnee = {-14, 0, 0}, LeftHip = {22, 0, -8}, LeftKnee = {-24, 0, 0},
        }, "out"),
    },
    markers = {Hit = 0.16, CanChain = 0.28, End = 0.42},
}
-- 4. Finisher: both hands raise the blade overhead, then a stepping kara-take-wari straight down.
set.m1_4 = {
    duration = 0.6, priority = "Action", finisher = true, swing = "down",
    hitbox = {length = 9, width = 7, height = 7, forwardOffset = 4.5, tolerance = 1.5},
    keyframes = {
        k(0, {
            Root = {-2, 0, 0, 0, -0.35, -0.3}, Waist = {0, 40, 0}, Neck = {0, -28, 0},
            RightShoulder = {80, 0, -40}, RightElbow = {14, 0, 0}, RightWrist = {0, 0, 70},
            LeftShoulder = {76, 0, 14}, LeftElbow = {22, 0, 0},
            RightHip = {-8, 0, 8}, RightKnee = {-14, 0, 0}, LeftHip = {22, 0, -8}, LeftKnee = {-24, 0, 0},
        }),
        k(0.16, {
            Root = {8, 0, 0, 0, 0.05, 0.3}, Waist = {-10, 0, 0}, Neck = {10, 0, 0},
            RightShoulder = {172, 0, 8}, RightElbow = {30, 0, 0}, RightWrist = {-30, 0, 0},
            LeftShoulder = {170, 0, -6}, LeftElbow = {34, 0, 0}, LeftWrist = {-30, 0, 0},
            RightHip = {-6, 0, 4}, RightKnee = {-6, 0, 0}, LeftHip = {10, 0, -4}, LeftKnee = {-8, 0, 0},
        }, "out"),
        k(0.27, {
            Root = {-22, 0, 0, 0, -0.75, -1.6}, Waist = {18, 0, 0}, Neck = {-14, 0, 0},
            RightShoulder = {30, 0, -8}, RightElbow = {4, 0, 0}, RightWrist = {6, 0, 0},
            LeftShoulder = {32, 0, 20}, LeftElbow = {10, 0, 0}, LeftWrist = {6, 0, 0},
            RightHip = {48, 0, 6}, RightKnee = {-46, 0, 0}, LeftHip = {-34, 0, -6}, LeftKnee = {-26, 0, 0},
        }, "in"),
        k(0.6, {
            Root = {-12, 0, 0, 0, -0.5, -1.2}, Waist = {10, 0, 0}, Neck = {-8, 0, 0},
            RightShoulder = {38, 0, -10}, RightElbow = {12, 0, 0}, RightWrist = {0, 0, 0},
            LeftShoulder = {40, 0, 22}, LeftElbow = {18, 0, 0}, LeftWrist = {0, 0, 0},
            RightHip = {36, 0, 6}, RightKnee = {-36, 0, 0}, LeftHip = {-24, 0, -6}, LeftKnee = {-20, 0, 0},
        }, "out"),
    },
    markers = {Hit = 0.26, CanChain = 0.6, End = 0.6},
}

-- Dashes (sword held low and back, body leaning into travel) ------------------------------
local function dash(lean, side, hipsR, hipsL)
    return {
        duration = 0.28, priority = "Action",
        keyframes = {
            k(0, CHUDAN),
            k(0.06, {
                Root = {lean, 0, side, 0, -0.55, 0}, Waist = {-lean * 0.4, 0, -side * 0.3}, Neck = {-lean * 0.5, 0, 0},
                RightShoulder = {-32, 0, 26}, RightElbow = {18, 0, 0}, RightWrist = {-10, 0, 0},
                LeftShoulder = {-26, 0, -26}, LeftElbow = {16, 0, 0},
                RightHip = hipsR, RightKnee = {-48, 0, 0}, LeftHip = hipsL, LeftKnee = {-30, 0, 0},
            }, "out"),
            k(0.2, {
                Root = {lean * 0.8, 0, side * 0.8, 0, -0.5, 0}, Waist = {-lean * 0.3, 0, -side * 0.2}, Neck = {-lean * 0.4, 0, 0},
                RightShoulder = {-30, 0, 24}, RightElbow = {18, 0, 0}, RightWrist = {-10, 0, 0},
                LeftShoulder = {-24, 0, -24}, LeftElbow = {16, 0, 0},
                RightHip = hipsR, RightKnee = {-44, 0, 0}, LeftHip = hipsL, LeftKnee = {-28, 0, 0},
            }),
            k(0.28, CHUDAN, "inout"),
        },
        markers = {End = 0.28},
    }
end
set.dash_f = dash(-30, 0, {52, 0, 0}, {-38, 0, 0})
set.dash_b = dash(12, 0, {-18, 0, 0}, {34, 0, 0})
set.dash_l = dash(-10, 22, {10, 0, 22}, {-8, 0, -30})
set.dash_r = dash(-10, -22, {10, 0, 30}, {-8, 0, -22})

-- Reactions -------------------------------------------------------------------------------
local function flinch(dir)
    return {
        duration = 0.3, priority = "Action",
        keyframes = {
            k(0, NEUTRAL),
            k(0.05, {
                Root = {14, 0, -8 * dir, 0, -0.2, 0.3}, Waist = {10, 26 * dir, 0}, Neck = {18, -16 * dir, 0},
                RightShoulder = {28, 0, 30}, RightElbow = {40, 0, 0}, LeftShoulder = {26, 0, -30}, LeftElbow = {40, 0, 0},
                RightHip = {-6, 0, 4}, RightKnee = {-18, 0, 0}, LeftHip = {-6, 0, -4}, LeftKnee = {-18, 0, 0},
            }, "out"),
            k(0.3, NEUTRAL, "inout"),
        },
        markers = {End = 0.3},
    }
end
set.hit_l = flinch(1)
set.hit_r = flinch(-1)
set.knockback = {
    duration = 0.8, priority = "Action",
    keyframes = {
        k(0, NEUTRAL),
        k(0.12, {
            Root = {38, 0, 0, 0, 0.3, 0.4}, Waist = {18, 0, 0}, Neck = {24, 0, 0},
            RightShoulder = {120, 0, 50}, RightElbow = {30, 0, 0}, LeftShoulder = {120, 0, -50}, LeftElbow = {30, 0, 0},
            RightHip = {40, 0, 8}, RightKnee = {-50, 0, 0}, LeftHip = {26, 0, -8}, LeftKnee = {-36, 0, 0},
        }, "out"),
        k(0.55, LYING, "in"),
        k(0.8, LYING),
    },
    markers = {End = 0.8},
}
set.getup = {
    duration = 0.5, priority = "Action",
    keyframes = {
        k(0, LYING),
        k(0.25, {
            Root = {-10, 0, 0, 0, -1.4, 0}, Waist = {20, 0, 0}, Neck = {-6, 0, 0},
            RightShoulder = {20, 0, 20}, RightElbow = {30, 0, 0}, LeftShoulder = {40, 0, -10}, LeftElbow = {20, 0, 0},
            RightHip = {80, 0, 6}, RightKnee = {-90, 0, 0}, LeftHip = {-10, 0, -6}, LeftKnee = {-100, 0, 0},
        }, "out"),
        k(0.5, NEUTRAL, "inout"),
    },
    markers = {End = 0.5},
}
set.clash_recoil = {
    duration = 0.45, priority = "Action",
    keyframes = {
        k(0, CHUDAN),
        k(0.08, {
            Root = {18, 0, 0, 0, -0.1, 0.8}, Waist = {-12, 0, 0}, Neck = {14, 0, 0},
            RightShoulder = {150, 0, 40}, RightElbow = {20, 0, 0}, RightWrist = {-30, 0, 0},
            LeftShoulder = {110, 0, -20}, LeftElbow = {30, 0, 0},
            RightHip = {-16, 0, 6}, RightKnee = {-20, 0, 0}, LeftHip = {-24, 0, -6}, LeftKnee = {-24, 0, 0},
        }, "out"),
        k(0.45, CHUDAN, "inout"),
    },
    markers = {End = 0.45},
}

return set
