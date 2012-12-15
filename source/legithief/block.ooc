
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use chipmunk
import chipmunk

Block: class {

    level: Level

    gfx: GlGroup
    rect: GlSprite

    body: CpBody
    shape: CpShape

    blockType: String

    init: func (=level, =blockType, pos: Vec2) {
        gfx = GlGroup new()

        rect = GlSprite new(spriteFor(blockType))
        gfx add(rect)

        level heroLayer add(gfx)

        mass := 50.0 / (78 * 44) * rect width * rect height
        moment := cpMomentForBox(mass, rect width, rect height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        shape = level space addShape(CpBoxShape new(body, rect width, rect height))
        shape setFriction(0.5)

        shape setLayers(ShapeGroup FURNITURE)
    }

    spriteFor: func (blockType: String) -> String {
        "assets/png/%s.png" format(blockType)
    }

    update: func {
        gfx sync(body)
    }

}

