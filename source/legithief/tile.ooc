
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

Tile: class {

    debug := static false

    defs := static HashMap<String, TileDef> new()
    logger := static Log getLogger("tile")

    level: Level
    layer: Layer

    gfx: GlGroup
    rect: GlSprite

    body: CpBody
    shape: CpShape

    def: TileDef

    /* */
    handler: static CpCollisionHandler
    reverse := static HashMap<CpShape, Tile> new()

    /* properties */
    stair := false
    ladder := false
    through := false

    broken := false
    smashSamples := static ArrayList<Sample> new()

    init: func (=layer, =def, pos: Vec2) {
        initProperties()

        level = layer level

        gfx = GlGroup new()

        rect = GlSprite new(def image)
        rect pos set!(pos)
        gfx add(rect)

        layer group add(gfx)

        if (!def inert) {
            logger warn("Non-inert tiles are not supported yet!")
        }

        if (stair) {
            height := rect size norm() * 0.8
            p1 := pos sub(rect width / 2, 0 - rect height / 2)
            p2 := pos add(rect width / 2, 0 - rect height / 2)

            if (debug) {
                debugGfx := GlSegment new(p1, p2)
                layer group add(debugGfx)
            }

            body = CpBody newStatic()
            shape = level space addShape(CpSegmentShape new(body, cpv(p1), cpv(p2), 4))
            shape setLayers(PhysicLayers HERO_STAIRS)
            shape setCollisionType(1)
        } else {
            // workaround. Le sigh.
            (sBody, sShape) := level space createStaticBox(rect)
            body = sBody
            shape = sShape

            shape setFriction(def friction)
            layers := PhysicLayers FURNITURE | PhysicLayers FIRE
            if (through) {
                layers |= PhysicLayers HERO_THROUGH
            } else {
                layers |= PhysicLayers HERO_TILES
            }

            if (def breakable) {
                layers |= PhysicLayers BREAKING
            }
            shape setLayers(layers)
            level space addShape(shape)
            if (ladder) {
                shape setSensor(true)
                shape setCollisionType(2)
            } else {
                shape setCollisionType(1)
            }


            if (def breakable) {
                reverse put(shape, this)
                initSamples()
                if (!handler) {
                    handler = SmashCollision new(level)
                    level space addCollisionHandler(1, 21, handler)
                }
            }
        }
    }

    destroy: func {
        layer group remove(gfx)
        level space removeShape(shape)
        if (def breakable) {
            reverse remove(shape)
        }
    }

    initProperties: func {
        if (def name startsWith?("stair")) {
            stair = true
        }
        
        if (def name startsWith?("ladder")) {
            ladder = true
        }
       
        if (def name startsWith?("through")) {
            through = true
        }
    }

    initSamples: func {
        if (!smashSamples empty?()) return

        for (i in 1..3) {
            path := "assets/wav/shatter%d.wav" format(i)
            smashSamples add(level bleep loadSample(path))
        }
    }

    update: func -> Bool {
        if (def breakable && broken) {
            Random choice(smashSamples) play(0)
            return false
        }

        true
    }

    /* loading */

    loadDefinitions: static func {
        for (name in listDefs("assets/tiles")) {
            Tile define(name)
        }
    }

    define: static func (tileName: String) {
        defs put(tileName, TileDef new(tileName))
    }

    getDefinition: static func (tileName: String) -> TileDef {
        defs get(tileName)
    }

}

SmashCollision: class extends CpCollisionHandler {

    level: Level
    thudSamples := ArrayList<Sample> new()

    lastNoiseCounter := Time runTime()

    init: func (=level) {
        for (i in 1..3) {
            thudSamples add(level bleep loadSample("assets/wav/thud%d.wav" format(i)))
        }
    }

    begin: func (arbiter: CpArbiter, space: CpSpace) {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        tile: Tile = null
        tile = Tile reverse get(shape1)
        if (tile) {
            tile broken = true
        } else {
            // Something we can't break? make a sound anyway
            current := Time runTime()

            if (current - lastNoiseCounter > 600) {
                Random choice(thudSamples) play(0)
            }
            lastNoiseCounter = current
        }
    }

}


TileDef: class {

    name: String
    image: String
    fire := 0.0
    mass := 10.0
    friction := 1.0
    inert := true
    breakable := false

    init: func (=name) {
        doc := parseYaml("assets/tiles/%s.yml" format(name))

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
                case "inert" =>
                    inert = v toBool()
                case "breakable" =>
                    breakable = v toBool()
                case =>
                    Tile logger warn("Unhandled tile key %s" format(k))
            }
        )
    }

    explodeSamples := static ArrayList<Sample> new()

}
