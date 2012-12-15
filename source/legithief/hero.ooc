
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use chipmunk
import chipmunk

import math
import structs/[ArrayList]

Hero: class {

    level: Level
    input: Input 

    gfx: GlGroup

    spriteLeft, spriteRight: GlSprite

    body: CpBody
    shape: CpShape

    bat: CpBody
    batShape: CpShape

    moveVel := 120
    jumpVel := 240

    direction := 1

    batGfx: GlGroup
    batConstraint: CpConstraint

    batCounter := 0
    jumpCounter := 0

    touchesGround := false

    collisionHandlers := ArrayList<CpCollisionHandler> new()

    init: func (=level) {
        gfx = GlGroup new()
        spriteRight = GlSprite new("assets/png/hero-right.png") 
        spriteLeft = GlSprite new("assets/png/hero-left.png") 
        spriteLeft visible = false
        gfx add(spriteRight)
        gfx add(spriteLeft)

        sprite := spriteRight

        level heroLayer add(gfx)

        input = level input sub()

        pos := vec2(100, 50)

        mass := 120.0
        moment := cpMomentForBox(mass, sprite width, sprite height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        shape = level space addShape(CpBoxShape new(body, sprite width, sprite height))
        shape setFriction(0.8)

        level space addConstraint(CpConstraint newRotaryLimit(body, level space getStaticBody(), 0, 0))
        shape setLayers(ShapeGroup HERO)
        shape setGroup(1)
        shape setCollisionType(7)

        // initialize bat
        batGfx = GlGroup new()
        batSprite := GlSprite new("assets/png/bat.png")

        batGfx add(batSprite)
        level heroLayer add(batGfx)

        batWidth := batSprite width
        batHeight := batSprite height

        batMass := 50.0
        batMoment := cpMomentForBox(batMass, batWidth, batHeight)

        bat = level space addBody(CpBody new(batMass, batMoment))
        bat setPos(cpv(pos add(0, -10)))

        batShape = level space addShape(CpBoxShape new(bat, batWidth, batHeight))
        batShape setGroup(1)
        batShape setFriction(0.99)

        batConstraint = level space addConstraint(CpConstraint newPivot(bat, body, cpv(pos)))
        level space addConstraint(CpConstraint newRotaryLimit(bat, level space getStaticBody(),
            PI / 2, 3 * PI / 2))

        heroGround := HeroGroundCollision new(this)
        level space addCollisionHandler(1, 7, heroGround)
        collisionHandlers add(heroGround)
    }

    update: func {
        gfx sync(body)
        batGfx sync(bat)

        alpha := 0.3
        if (input isPressed(Keys RIGHT)) {
            vel := body getVel()
            vel x = vel x * alpha + (moveVel * (1 - alpha))
            body setVel(vel)
            direction = 1
        } else if (input isPressed(Keys LEFT)) {
            vel := body getVel()
            vel x = vel x * alpha + (-moveVel * (1 - alpha))
            body setVel(vel)
            direction = -1
        }

        if (jumpCounter > 0) {
            jumpCounter -= 1
        }
        if (input isPressed(Keys SPACE) && (touchesGround || jumpCounter > 0)) {
            vel := body getVel()
            vel y = -jumpVel
            body setVel(vel)

            if (touchesGround) {
                jumpCounter = 14
            }
        }
    
        if (batCounter > 0) {
            batCounter -= 1
            batShape setLayers(ShapeGroup HERO | ShapeGroup FURNITURE)
        } else {
            batShape setLayers(ShapeGroup HERO)
        }

        if (input isPressed(Keys SHIFT)) {
            if (batCounter <= 0) {
                batCounter = 20
                bat setAngVel(direction * -12 * PI)
            }
        }

        spriteRight visible = (direction > 0)
        spriteLeft visible = (direction <= 0)
    }

}

HeroGroundCollision: class extends CpCollisionHandler {

    hero: Hero

    init: func (=hero) {
    }

    begin: func (arbiter: CpArbiter, space: CpSpace) {
        hero touchesGround = true
    }

    separate: func (arbiter: CpArbiter, space: CpSpace) {
        hero touchesGround = false
    }

}

