
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives, anim]

use chipmunk
import chipmunk

import math, math/Random
import structs/[ArrayList]

use bleep
import bleep

Hero: class {

    debug := static true

    level: Level
    layer: Layer
    input: Input 

    gfx: GlGroup
    sprite: GlSprite

    body: CpBody
    shape: CpShape

    walkSpeed := 150
    runSpeed := 220
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

    /* feet sensor */
    feet: CpBody
    feetShape: CpShape
    feetGfx: GlGroup
    feetConstraint: CpConstraint
    feetRotaryLimit: CpRotaryLimitJoint

    /* ladder movement */
    ladderGrip: CpBody
    ladderConstraint: CpPinJoint
    ladderSpeed := 6

    /* animations */
    bottom, top: GlAnimSet

    /* physics */
    jumpCounter := 0
    groundTouchNumber := 0
    groundTouchCounter := 0
    collisionHandlers := ArrayList<CpCollisionHandler> new()
    moving := false

    ladderTouchNumber := 0
    onLadder := false

    /* audio */
    walkSample: Sample
    jumpSample: Sample
    gruntSamples := ArrayList<Sample> new()

    /* weapon contour */
    handContour, batContour, lighterContour: WeaponContour
    weapon: WeaponContour

    init: func (=layer) {
        level = layer level

        gfx = GlGroup new()
        sprite = GlSprite new("assets/png/hero/hero-01.png") 
        gfx add(sprite)
        sprite visible = false
        layer group add(gfx)

        initAnims()

        input = level input sub()

        pos := vec2(100, 50)

        mass := 200.0
        moment := cpMomentForBox(mass, sprite width, sprite height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        xFactor := 0.7 // huhu

        if (debug) {
            rect := GlRectangle new()
            rect size set!(sprite width * xFactor, sprite height)
            rect filled = false
            gfx add(rect)
        }

        shape = level space addShape(CpBoxShape new(body, sprite width * xFactor, sprite height))
        shape setFriction(0.1)
        shape setCollisionType(8)

        level space addConstraint(CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0))
        shape setLayers(PhysicLayers HERO | PhysicLayers HERO_TILES)
        shape setGroup(PhysicGroups HERO)

        // initialize bat
        batGfx = GlGroup new()
        batSprite := GlRectangle new()
        batSprite size set!(8, 76)
        batSprite color set!(220, 80, 80)
        if (!debug) batSprite visible = false

        batGfx add(batSprite)
        layer group add(batGfx)

        batWidth := batSprite width
        batHeight := batSprite height

        batMass := 30.0
        batMoment := cpMomentForBox(batMass, batWidth, batHeight)

        bat = level space addBody(CpBody new(batMass, batMoment))
        bat setPos(cpv(pos add(0, -20)))

        batShape = level space addShape(CpBoxShape new(bat, batWidth, batHeight))
        batShape setGroup(PhysicGroups HERO)
        batShape setFriction(0.99)

        batConstraint = level space addConstraint(CpConstraint newPivot(bat, body, cpv(pos)))
        batRotaryLimit = CpRotaryLimitJoint new(bat, level space getStaticBody(), -0.1, 0.1)
        level space addConstraint(batRotaryLimit)

        // initialize leg
        legGfx = GlGroup new()
        legSprite := GlRectangle new()
        legSprite size set!(8, 80)
        legSprite color set!(80, 220, 80)
        if (!debug) legSprite visible = false

        legGfx add(legSprite)
        layer group add(legGfx)

        legWidth := legSprite width
        legHeight := legSprite height

        legMass := 20.0
        legMoment := cpMomentForBox(legMass, legWidth, legHeight)

        leg = level space addBody(CpBody new(legMass, legMoment))
        leg setPos(cpv(pos add(0, -20)))

        legShape = level space addShape(CpBoxShape new(leg, legWidth, legHeight))
        legShape setGroup(PhysicGroups HERO)
        legShape setFriction(0.99)

        legConstraint = level space addConstraint(CpConstraint newPivot(leg, body, cpv(pos)))
        legRotaryLimit = CpRotaryLimitJoint new(leg, level space getStaticBody(), PI - 0.1, PI + 0.1)
        level space addConstraint(legRotaryLimit)

        // initialize feet
        feetGfx = GlGroup new()
        feetSprite := GlRectangle new()
        feetSprite size set!(sprite width * 1.2, 16)
        feetSprite color set!(80, 220, 200)
        if (!debug) feetSprite visible = false

        feetGfx add(feetSprite)
        layer group add(feetGfx)

        feetMass := 20.0
        feetMoment := cpMomentForBox(feetMass, feetSprite width, feetSprite height)
        feet = level space addBody(CpBody new(feetMass, feetMoment))
        feet setPos(cpv(pos add(0, sprite height / 2)))

        feetShape = level space addShape(CpBoxShape new(feet, feetSprite width, feetSprite height))
        feetShape setSensor(true)
        feetShape setCollisionType(7)

        feetConstraint = level space addConstraint(CpConstraint newPivot(feet, body, feet getPos()))
        feetRotaryLimit = CpRotaryLimitJoint new(feet, level space getStaticBody(), 0, 0)
        level space addConstraint(feetRotaryLimit)

        // ladder grip
        ladderGrip = CpBody newStatic()
        ladderGrip setPos(body getPos())
        ladderConstraint = CpPinJoint new(body, ladderGrip, cpv(0, 0), cpv(0, 0))
        ladderConstraint setDist(0)

        // hero's feet <-> ground collision detection for jump
        heroGround := HeroGroundCollision new(this)
        level space addCollisionHandler(1, 7, heroGround)
        collisionHandlers add(heroGround)

        // hero's body <-> ladder collision detecton for.. ladder-ing
        heroLadder := HeroLadderCollision new(this)
        level space addCollisionHandler(2, 8, heroLadder)
        collisionHandlers add(heroLadder)

        initSamples()

        initEvents()

        initContours()
    }

    setPos: func (pos: Vec2) {
        body setPos(cpv(pos))
    }

    initContours: func {
        contourGroup := GlGroup new()

        handContour = WeaponContour new("hand")
        handContour gfx pos set!(0, 0)
        contourGroup add(handContour gfx)

        batContour = WeaponContour new("bat")
        batContour gfx pos set!(100, 0)
        contourGroup add(batContour gfx)

        lighterContour = WeaponContour new("lighter")
        lighterContour gfx pos set!(200, 0)
        contourGroup add(lighterContour gfx)

        contourGroup pos set!(70, 70)
        level hudGroup add(contourGroup)

        setWeapon(batContour)
    }

    setWeapon: func (value: WeaponContour) {
        if (weapon) {
            weapon setActive(false)
        }

        weapon = value
        weapon setActive(true)
    }

    initSamples: func {
        walkSample = level bleep loadSample("assets/wav/walk.wav")
        jumpSample = level bleep loadSample("assets/wav/jump.wav")

        for (i in 1..4) {
            path := "assets/wav/grunt%d.wav" format(i)
            gruntSamples add(level bleep loadSample(path))
        }
    }

    initEvents: func {
        input onKeyPress(Keys _1, ||
            setWeapon(handContour)
        )

        input onKeyPress(Keys _2, ||
            setWeapon(batContour)
        )

        input onKeyPress(Keys _3, ||
            setWeapon(lighterContour)
        )

        // short jump
        input onKeyPress(Keys SPACE, ||
            if (touchesGround? || onLadder) {
                vel := body getVel()
                vel y = -jumpVel
                body setVel(vel)
                jumpCounter = 14

                jumpSample play(0)

                if (onLadder) {
                    ladderDisable()
                }
            }
        )

        input onMousePress(Buttons LEFT, ||
            if (legCounter > 0) return

            if (batCounter <= 0) {
                batCounter = 15
                throwBat()
                grunt()
            }
        )

        input onMousePress(Buttons RIGHT, ||
            if (batCounter > 0) return

            if (legCounter <= 0) {
                legCounter = 15
                throwLeg()
                grunt()
            }
        )
    }

    initAnims: func {
        bottom = GlAnimSet new()
        bwalk := bottom load("hero", "bottom", "walking", 12)
        bwalk frameDuration = 4
        brun := bottom load("hero", "bottom", "running", 11)
        brun frameDuration = 3

        pfoot := bottom load("hero", "bottom", "punching-foot", 8)
        pfoot offset x = 8
        pfoot frameDuration = 3
        bottom play("walking")
        gfx add(bottom)

        top = GlAnimSet new()
        twalk := top load("hero", "top", "walking", 12)
        twalk frameDuration = 4
        trun := top load("hero", "top", "running", 11)
        trun frameDuration = 3

        twbat := top load("hero", "top", "walking-bat", 3)
        twbat offset x = 20
        twbat frameDuration = 6

        tpbat := top load("hero", "top", "punching-bat", 8)
        tpbat offset x = 38
        tpbat offset y = -24
        tpbat frameDuration = 2

        top play("walking-bat")
        gfx add(top)
    }

    updateAnimations: func {
        ticks := (direction * lookDir) * 1
        if (groundTouchNumber < 1) {
            ticks = 0
        }

        bottomWalking := bottom currentName startsWith?("walking") || bottom currentName startsWith?("running")
        if (bottomWalking) {
            // if bottom has a walking animation, only update if moving
            if (moving) {
                bottom update(ticks)
            }
        } else {
            // if we're not walking, update the animation anyway
            bottom update()
        }

        topWalking := top currentName startsWith?("walking")
        if (topWalking) {
            // if top has a walking animation, only update if moving
            if (moving) {
                top update(ticks)
            }
        } else {
            // if we're not walking, update the animation anyway
            top update()
        }
    }

    setMoving: func (value: Bool) {
        if (moving != value) {
            if (value) {
                walkSample play(-1)
            } else {
                walkSample stop()
            }
        }

        moving = value
    }

    grunt: func {
        Random choice(gruntSamples) play(0)
    }

    ladderEnable: func {
        onLadder = true

        ladderGrip setPos(body getPos())
        level space addConstraint(ladderConstraint)
    }

    ladderDisable: func {
        onLadder = false
        level space removeConstraint(ladderConstraint)
    }

    update: func {
        gfx sync(body)
        batGfx sync(bat)
        legGfx sync(leg)
        feetGfx sync(feet)

        if (input isPressed(Keys W) || input isPressed(Keys S)) {
            shape setLayers(PhysicLayers HERO | PhysicLayers HERO_TILES | PhysicLayers HERO_STAIRS)
        } else {
            shape setLayers(PhysicLayers HERO | PhysicLayers HERO_TILES | PhysicLayers HERO_THROUGH)
        }

        if (onLadder) {
            if (ladderTouchNumber <= 0) {
                ladderDisable()
            } else {
                if (input isPressed(Keys W)) {
                    gripPos := ladderGrip getPos()
                    gripPos y = gripPos y - ladderSpeed
                    ladderGrip setPos(gripPos)
                }
                
                if (input isPressed(Keys S)) {
                    gripPos := ladderGrip getPos()
                    gripPos y = gripPos y + ladderSpeed
                    ladderGrip setPos(gripPos)

                    if (touchesGround?) {
                        ladderDisable()
                    }
                }
                
                if (input isPressed(Keys A)) {
                    gripPos := ladderGrip getPos()
                    gripPos x = gripPos x - ladderSpeed
                    ladderGrip setPos(gripPos)
                }
                
                if (input isPressed(Keys D)) {
                    gripPos := ladderGrip getPos()
                    gripPos x = gripPos x + ladderSpeed
                    ladderGrip setPos(gripPos)
                }
            }
        } else {
            if (ladderTouchNumber > 0) {
                if (input isPressed(Keys W) || input isPressed(Keys S)) {
                    ladderEnable()
                }
            }
        }

        if (input isPressed(Keys D)) {
            direction = 1
            setMoving(true)
        } else if (input isPressed(Keys A)) {
            direction = -1
            setMoving(true)
        } else {
            setMoving(false)
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
        } else {
            vel := body getVel()
            vel x = vel x * 0.7
            body setVel(vel)
        }

        updateAnimations()

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
            throwBat()
        } else {
            holdBat()
        }

        if (legCounter > 0) {
            legCounter -= 1
            throwLeg()
        } else {
            holdLeg()
        }

        if (groundTouchNumber > 0) {
            groundTouchCounter = 20
        } else {
            if (groundTouchCounter > 0) {
                groundTouchCounter -= 1
            }
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
        sprite xSwap = (lookDir < 0)
        top xSwap = (lookDir < 0)
        bottom xSwap = (lookDir < 0)
    }

    walkAnim: func (animSet: GlAnimSet) {
        animSet play(running? ? "running" : "walking")
    }

    /* Leg operations */

    throwLeg: func {
        bottom play("punching-foot")
        base := PI + lookDir * (PI / 2)
        legRotaryLimit setMin(base - 0.1)
        legRotaryLimit setMax(base + 0.1)
        legShape setLayers(PhysicLayers HERO | PhysicLayers FURNITURE)
    }

    holdLeg: func {
        walkAnim(bottom)
        base := PI - lookDir * (PI / 4)
        legRotaryLimit setMin(base - 0.1)
        legRotaryLimit setMax(base + 0.1)
        legShape setLayers(PhysicLayers HERO)
    }

    /* Bat operations */

    throwBat: func {
        top play("punching-bat")
        base := 0 - lookDir * (3 * PI / 4)
        batRotaryLimit setMin(base - 0.1)
        batRotaryLimit setMax(base + 0.1)
        batShape setLayers(PhysicLayers HERO | PhysicLayers FURNITURE)
    }

    holdBat: func {
        top play("walking-bat")
        base := 0 + lookDir * (PI / 4)
        batRotaryLimit setMin(base - 0.1)
        batRotaryLimit setMax(base + 0.1)
        batShape setLayers(PhysicLayers HERO)
    }

    running?: Bool { get {
        input isPressed(Keys SHIFT)
    } }

    touchesGround?: Bool { get {
        groundTouchCounter > 0
    } }

}

HeroGroundCollision: class extends CpCollisionHandler {

    hero: Hero

    init: func (=hero) {
    }

    begin: func (arbiter: CpArbiter, space: CpSpace) {
        hero groundTouchNumber += 1
    }

    separate: func (arbiter: CpArbiter, space: CpSpace) {
        hero groundTouchNumber -= 1
    }

}

HeroLadderCollision: class extends CpCollisionHandler {

    hero: Hero

    init: func (=hero) {
    }

    begin: func (arbiter: CpArbiter, space: CpSpace) {
        hero ladderTouchNumber += 1
    }

    separate: func (arbiter: CpArbiter, space: CpSpace) {
        hero ladderTouchNumber -= 1
    }

}

WeaponContour: class {

    name: String

    gfx: GlGroup

    outline, activeOutline: GlSprite

    init: func (=name) {
        gfx = GlGroup new()

        outline = GlSprite new("assets/png/weapon-outline.png")
        gfx add(outline)

        activeOutline = GlSprite new("assets/png/weapon-outline-active.png")
        gfx add(activeOutline)
        activeOutline visible = false

        sprite := GlSprite new("assets/png/%s.png" format(name))
        gfx add(sprite)
    }

    setActive: func (active: Bool) {
        outline visible = !active
        activeOutline visible = active
    }

}


