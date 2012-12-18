
import structs/[ArrayList, HashMap]

import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use yaml
import yaml/[Parser, Document]

import math, math/Random
import os/Time

use bleep
import bleep

CollisionShape: abstract class {

}

BoxShape: class extends CollisionShape {

}

ConvexShape: class extends CollisionShape {

    points := ArrayList<Vec2> new()

}

/*
 * Items are stuff that the hero can kick around, but that
 * doesn't necessary collide with him.
 */

ItemDef: class {

    name: String
    image: String
    fire := 0.0
    mass := 10.0
    friction := 0.5
    shape := BoxShape new()

    init: func (=name) {
        doc := parseYaml("assets/items/%s.yml" format(name))

        dict := doc toMap()
        dict each(|k, v|
            match k {
                case "image" =>
                    image = v toScalar()
                case "friction" =>
                    friction = v toFloat()
                case "mass" =>
                    mass = v toFloat()
                case "fire" =>
                    fire = v toFloat()
                case =>
                    Item logger warn("Unhandled item key %s" format(k))
            }
        )
    }

}

Item: class {

    broken := false

    defs := static HashMap<String, ItemDef> new()
    logger := static Log getLogger("item")

    level: Level
    layer: Layer

    /* */
    handler: static CpCollisionHandler
    reverse := static HashMap<CpShape, Item> new()

    gfx: GlGroup
    rect: GlSprite

    body: CpBody
    shape: CpShape

    def: ItemDef

    init: func (=layer, =def, pos: Vec2) {
        level = layer level

        gfx = GlGroup new()

        rect = GlSprite new(def image)
        gfx add(rect)

        layer group add(gfx)

        mass := def mass
        moment := cpMomentForBox(mass, rect width, rect height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        shape = CpBoxShape new(body, rect width, rect height)
        level space addShape(shape)
        shape setFriction(def friction)

        shape setLayers(PhysicLayers FURNITURE)
        shape setCollisionType(4)

        reverse put(shape, this)
        if (!handler) {
            handler = BreakCollision new(level)
            level space addCollisionHandler(4, 1, handler)
        }
    }

    destroy: func {
        layer group remove(gfx)
        level space removeBody(body)
        level space removeShape(shape)
        reverse remove(shape)
    }

    update: func -> Bool {
        gfx sync(body)

        true
    }

    /* loading */

    loadDefinitions: static func {
        for (name in listDefs("assets/items")) {
            Item define(name)
        }
    }

    define: static func (itemName: String) {
        defs put(itemName, ItemDef new(itemName))
    }

    getDefinition: static func (itemName: String) -> ItemDef {
        defs get(itemName)
    }

}

BreakCollision: class extends CpCollisionHandler {

    level: Level
    samples := ArrayList<Sample> new()
    lastNoiseCounter := Time runTime()

    init: func (=level) {
        for (i in 1..3) {
            samples add(level bleep loadSample("assets/wav/thud%d.wav" format(i)))
        }
    }

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        body1, body2: CpBody
        arbiter getBodies(body1&, body2&)

        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        item: Item = null
        item = item reverse get(shape1)
        if (item) {
            vel := vec2(body1 getVel()) norm()
            if (vel > 500) {
                if (!item broken) {
                    item broken = true
                    item rect brightness = 0.1

                    score := (item def mass * vel) * 0.1
                    //"score = %.2f, mass = %.2f, vel = %.2f" printfln(score, item def mass, vel)
                    level addScore(score)

                    current := Time runTime()

                    if (current - lastNoiseCounter > 300) {
                        Random choice(samples) play(0)
                    }
                    lastNoiseCounter = current
                }
            }

        }

        true
    }

}

