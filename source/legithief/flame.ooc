
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives, anim]

use chipmunk
import chipmunk

import math, math/Random
import structs/[ArrayList]

use bleep
import bleep

FlameState: class {
    GROWING := static 1
    SHRINKING := static 2
}

Flame: class {

    debug := static true

    level: Level
    layer: Layer

    gfx: GlGroup
    anim: GlAnim

    scale := 0.3

    state := FlameState GROWING

    body: CpBody
    shape: CpShape
    rotaryLimit: CpRotaryLimitJoint

    init: func (=layer, pos: Vec2) {
        level = layer level

        gfx = GlGroup new()
        gfx pos set!(pos)

        anim = GlAnim sequence("assets/png/flames-%02d.png", 1, 6)
        anim scale set!(scale, scale)
        gfx add(anim)

        layer group add(gfx)

        // free flame:
        mass := 20.0
        moment := cpMomentForBox(mass, 32, 64)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        shape = level space addShape(CpBoxShape new(body, 32, 64))
        shape setGroup(PhysicGroups FIRE)
        shape setFriction(0.8)
        shape setCollisionType(12)
        shape setLayers(PhysicLayers FIRE)

        rotaryLimit = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotaryLimit)
    }

    setPos: func (pos: Vec2) {
        body setPos(cpv(pos))
    }

    setVel: func (vel: Vec2) {
        body setVel(cpv(vel))
    }

    update: func -> Bool {
        anim update()

        match state {
            case FlameState GROWING =>
                scale += 0.05
                if (scale > 1.2) {
                    state = FlameState SHRINKING
                }
            case FlameState SHRINKING =>
                scale -= 0.001
                if (scale < 0.2) {
                    return false // extinguish
                }
        }
        anim scale set!(scale, scale)

        gfx sync(body)

        true
    }

    destroy: func {
        layer group remove(gfx)
        level space removeBody(body)
        level space removeShape(shape)
        level space removeConstraint(rotaryLimit)
    }

}


