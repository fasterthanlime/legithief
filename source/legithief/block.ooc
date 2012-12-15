
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use chipmunk
import chipmunk

Block: class {

    level: Level

    gfx: GlGroup
    rect: GlRectangle

    body: CpBody
    shape: CpShape

    init: func (=level) {
        gfx = GlGroup new()

        rect = GlRectangle new()
        rect size set!(128, 128)
        gfx add(rect)

        level heroLayer add(gfx)

        mass := 10.0
        moment := cpMomentForBox(mass, rect size x, rect size y)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(300, 100))
        body setAngle(45)

        shape = level space addShape(CpBoxShape new(body, rect size x, rect size y))
        shape setFriction(0.7)
    }

    update: func {
        pos := body getPos()
        gfx pos set!(pos x, pos y)
        gfx angle = toDegrees(body getAngle())
    }

}

