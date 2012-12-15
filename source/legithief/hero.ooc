
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

    bat: CpBody
    batShape: CpShape

    moveVel := 150
    jumpVel := 300

    batGfx: GlGroup
    batConstraint: CpConstraint

    init: func (=level) {
        gfx = GlGroup new()
        sprite := GlSprite new("assets/png/hero.png") 
        gfx add(sprite)

        level heroLayer add(gfx)

        input = level input sub()

        pos := vec2(100, 50)

        mass := 10.0
        moment := cpMomentForBox(mass, sprite width, sprite height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        shape = level space addShape(CpBoxShape new(body, sprite width, sprite height))
        shape setFriction(0.8)

        level space addConstraint(CpConstraint newRotaryLimit(body, level space getStaticBody(), 0, 0))
        shape setLayers(ShapeGroup HERO)
        shape setGroup(1)

        // initialize bat
        batWidth := 8.0
        batHeight := 28.0

        batMass := 15.0
        batMoment := cpMomentForBox(batMass, batWidth, batHeight)

        bat = level space addBody(CpBody new(batMass, batMoment))
        bat setPos(cpv(pos add(0, -10)))

        batShape = level space addShape(CpBoxShape new(bat, batWidth, batHeight))
        batShape setGroup(1)

        batConstraint = level space addConstraint(CpConstraint newPin(bat, body, cpv(0, 0 - batHeight / 2), cpv(0, -10)))

        batGfx = GlGroup new()
        batSprite := GlRectangle new()
        batSprite size set!(batWidth, batHeight)
        batGfx add(batSprite)

        level heroLayer add(batGfx)
    }

    update: func {
        pos := body getPos()
        gfx pos set!(pos x, pos y)
        gfx angle = toDegrees(body getAngle())

        batPos := bat getPos()
        batGfx pos set!(batPos x, batPos y)
        batGfx angle = toDegrees(bat getAngle())

        alpha := 0.3
        if (input isPressed(Keys RIGHT)) {
            vel := body getVel()
            vel x = vel x * alpha + (moveVel * (1 - alpha))
            body setVel(vel)
        } else if (input isPressed(Keys LEFT)) {
            vel := body getVel()
            vel x = vel x * alpha + (-moveVel * (1 - alpha))
            body setVel(vel)
        }

        if (input isPressed(Keys SPACE)) {
            vel := body getVel()
            vel y = -jumpVel
            body setVel(vel)
        }
    }

}
