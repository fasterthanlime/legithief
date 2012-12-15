
use chipmunk
import chipmunk

use dye
import dye/[core, input, sprite, font, primitives, math]

import math

// cpv from vec2

cpv: func ~fromVec2 (v: Vec2) -> CpVect {
    cpv(v x, v y)
}

toRadians: func (degrees: Float) -> Float {
    degrees * PI / 180.0
}

toDegrees: func (radians: Float) -> Float {
    radians * 180.0 / PI
}

