
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives, anim]

use chipmunk
import chipmunk

import math, math/Random
import structs/[ArrayList]

use bleep
import bleep

Molotov: class {

    debug := static true

    level: Level
    layer: Layer

    gfx: GlGroup

    body: CpBody
    shape: CpShape
    handler: CpCollisionHandler

    explodes := false

    explodeSamples := static ArrayList<Sample> new()

    init: func (=layer, pos: Vec2) {
        level = layer level

        gfx = GlGroup new()
        gfx pos set!(pos)

        sprite := GlSprite new("assets/png/molotov.png")
        gfx add(sprite)

        layer group add(gfx)

        mass := 20.0
        moment := cpMomentForBox(mass, sprite width, sprite height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        shape = level space addShape(CpBoxShape new(body, sprite width, sprite height))
        shape setFriction(0.0)
        shape setCollisionType(13)
        shape setLayers(PhysicLayers FURNITURE)

        handler = MolotovCollision new(this)
        level space addCollisionHandler(1, 13, handler)
        level space addCollisionHandler(4, 13, handler)

        initSamples()
    }

    initSamples: func {
        if (!explodeSamples empty?()) return

        for (i in 1..3) {
            path := "assets/wav/bottle%d.wav" format(i)
            explodeSamples add(level bleep loadSample(path))
        }
    }

    setVel: func (vel: Vec2) {
        body setVel(cpv(vel))
    }

    setAngVel: func (f: Float) {
        body setAngVel(f)
    }

    update: func -> Bool {
        gfx sync(body)

        if (explodes) {
            pos := vec2(body getPos())
            vel := vec2(body getVel())

            for (i in -3..3) {
                flame := level fLayer spawnFlame(pos)
                flame setVel(vel add(i * 30, -30))
            }
            Random choice(explodeSamples) play(0)
            return false
        }

        true
    }

    destroy: func {
        layer group remove(gfx)
        level space removeBody(body)
        level space removeShape(shape)
        level space removeCollisionHandler(1, 13)
        level space removeCollisionHandler(4, 13)
    }

}

MolotovCollision: class extends CpCollisionHandler {

    molotov: Molotov

    init: func (=molotov) {
    }

    begin: func (arbiter: CpArbiter, space: CpSpace) {
        molotov explodes = true
    }

}

