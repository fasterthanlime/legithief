
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

    walkSpeed := 100
    runSpeed := 200
    jumpVel := 240

    lookDir := 1
    direction := 1

    /* bat */
    bat: CpBody
    batShape: CpShape
    batGfx: GlGroup
    batConstraint: CpConstraint
    batRotaryLimit: CpRotaryLimitJoint
    batCounter := 0

    /* leg */
    leg: CpBody
    legShape: CpShape
    legGfx: GlGroup
    legConstraint: CpConstraint
    legRotaryLimit: CpRotaryLimitJoint
    legCounter := 0

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

        level space addConstraint(CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0))
        shape setLayers(ShapeGroup HERO)
        shape setGroup(1)
        shape setCollisionType(7)

        // initialize bat
        batGfx = GlGroup new()
        batSprite := GlRectangle new()
        batSprite size set!(4, 38)
        batSprite color set!(220, 80, 80)

        batGfx add(batSprite)
        level heroLayer add(batGfx)

        batWidth := batSprite width
        batHeight := batSprite height

        batMass := 30.0
        batMoment := cpMomentForBox(batMass, batWidth, batHeight)

        bat = level space addBody(CpBody new(batMass, batMoment))
        bat setPos(cpv(pos add(0, -10)))

        batShape = level space addShape(CpBoxShape new(bat, batWidth, batHeight))
        batShape setGroup(1)
        batShape setFriction(0.99)

        batConstraint = level space addConstraint(CpConstraint newPivot(bat, body, cpv(pos)))
        batRotaryLimit = CpRotaryLimitJoint new(bat, level space getStaticBody(), -0.1, 0.1)
        level space addConstraint(batRotaryLimit)

        // initialize leg
        legGfx = GlGroup new()
        legSprite := GlRectangle new()
        legSprite size set!(4, 40)
        legSprite color set!(80, 220, 80)

        legGfx add(legSprite)
        level heroLayer add(legGfx)

        legWidth := legSprite width
        legHeight := legSprite height

        legMass := 20.0
        legMoment := cpMomentForBox(legMass, legWidth, legHeight)

        leg = level space addBody(CpBody new(legMass, legMoment))
        leg setPos(cpv(pos add(0, -10)))

        legShape = level space addShape(CpBoxShape new(leg, legWidth, legHeight))
        legShape setGroup(1)
        legShape setFriction(0.99)

        legConstraint = level space addConstraint(CpConstraint newPivot(leg, body, cpv(pos)))
        legRotaryLimit = CpRotaryLimitJoint new(leg, level space getStaticBody(), PI - 0.1, PI + 0.1)
        level space addConstraint(legRotaryLimit)

        // hero <-> ground collision detection for jump
        heroGround := HeroGroundCollision new(this)
        level space addCollisionHandler(1, 7, heroGround)
        collisionHandlers add(heroGround)

        initEvents()
    }

    initEvents: func {
        // short jump
        input onKeyPress(Keys SPACE, ||
            if (touchesGround) {
                vel := body getVel()
                vel y = -jumpVel
                body setVel(vel)
                jumpCounter = 14
            }
        )

        input onMousePress(Buttons LEFT, ||
            if (legCounter > 0) return

            if (batCounter <= 0) {
                batCounter = 15
                throwBat()
            }
        )

        input onMousePress(Buttons RIGHT, ||
            if (batCounter > 0) return

            if (legCounter <= 0) {
                legCounter = 15
                throwLeg()
            }
        )
    }

    update: func {
        gfx sync(body)
        batGfx sync(bat)
        legGfx sync(leg)

        moving := false
        if (input isPressed(Keys D)) {
            direction = 1
            moving = true
        } else if (input isPressed(Keys A)) {
            direction = -1
            moving = true
        }

        if (moving) {
            alpha := 0.3
            speed := running? ? runSpeed : walkSpeed
            if (lookDir * direction < 0.0) {
                // move noticeably slower if backtracking
                speed *= 0.5
            }

            vel := body getVel()
            vel x = vel x * alpha + (direction * speed * (1 - alpha))
            body setVel(vel)
        }

        if (jumpCounter > 0) {
            jumpCounter -= 1
        }

        // long jump = short jump + continued key press (up to 14 frames)
        if (input isPressed(Keys SPACE) && jumpCounter > 0) {
            vel := body getVel()
            vel y = -jumpVel
            body setVel(vel)
        }
    
        if (batCounter > 0) {
            batCounter -= 1
            batShape setLayers(ShapeGroup HERO | ShapeGroup FURNITURE)
            throwBat()
        } else {
            holdBat()
            batShape setLayers(ShapeGroup HERO)
        }

        if (legCounter > 0) {
            legCounter -= 1
            legShape setLayers(ShapeGroup HERO | ShapeGroup FURNITURE)
            throwLeg()
        } else {
            holdLeg()
            legShape setLayers(ShapeGroup HERO)
        }

        updateLookDir()
        updateSprites()
    }

    updateLookDir: func {
        mouse := input getMousePos()
        if (mouse x > level dye width / 2) {
            lookDir = 1
        } else {
            lookDir = -1
        }
    }

    updateSprites: func {
        spriteRight visible = (lookDir > 0)
        spriteLeft visible = (lookDir <= 0)
    }

    /* Leg operations */

    throwLeg: func {
        base := PI + lookDir * (PI / 2)
        legRotaryLimit setMin(base - 0.1)
        legRotaryLimit setMax(base + 0.1)
    }

    holdLeg: func {
        base := PI - lookDir * (PI / 4)
        legRotaryLimit setMin(base - 0.1)
        legRotaryLimit setMax(base + 0.1)
    }

    /* Bat operations */

    throwBat: func {
        base := 0 - lookDir * (3 * PI / 4)
        batRotaryLimit setMin(base - 0.1)
        batRotaryLimit setMax(base + 0.1)
    }

    holdBat: func {
        base := 0 + lookDir * (PI / 4)
        batRotaryLimit setMin(base - 0.1)
        batRotaryLimit setMax(base + 0.1)
    }

    running?: Bool { get {
        input isPressed(Keys SHIFT)
    } }

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

