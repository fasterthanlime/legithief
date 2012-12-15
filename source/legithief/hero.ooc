
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use chipmunk
import chipmunk

Hero: class {

    level: Level
    input: Input 

    gfx: GlGroup

    body: CpBody
    shape: CpShape

    moveVel := 120
    jumpVel := 300

    init: func (=level) {
        gfx = GlGroup new()
        sprite := GlSprite new("assets/png/hero.png") 
        gfx add(sprite)

        level heroLayer add(gfx)

        input = level input sub()

        mass := 10.0
        moment := cpMomentForBox(mass, sprite width, sprite height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(100, 50))

        shape = level space addShape(CpBoxShape new(body, sprite width, sprite height))
        shape setFriction(0.8)

        level space addConstraint(CpConstraint newRotaryLimit(body, level space getStaticBody(), -0.2, 0.2))
    }

    update: func {
        pos := body getPos()
        gfx pos set!(pos x, pos y)
        gfx angle = toDegrees(body getAngle())

        if (input isPressed(Keys RIGHT)) {
            vel := body getVel()
            vel x = moveVel
            body setVel(vel)
        } else if (input isPressed(Keys LEFT)) {
            vel := body getVel()
            vel x = -moveVel
            body setVel(vel)
        }

        if (input isPressed(Keys SPACE)) {
            vel := body getVel()
            vel y = -jumpVel
            body setVel(vel)
        }
    }

}
