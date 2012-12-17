
import structs/[ArrayList, HashMap]

import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use yaml
import yaml/[Parser, Document]

import math

TileDef: class {

    name: String
    image: String
    fire := 0.0
    mass := 10.0
    friction := 1.0
    inert := true

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
                case =>
                    Tile logger warn("Unhandled tile key %s" format(k))
            }
        )
    }

}

Tile: class {

    debug := static true

    defs := static HashMap<String, TileDef> new()
    logger := static Log getLogger("tile")

    level: Level
    layer: Layer

    gfx: GlGroup
    rect: GlSprite

    body: CpBody
    shape: CpShape

    def: TileDef

    /* properties */
    stair := false
    ladder := false
    through := false

    stairRect: GlSegment

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

            stairRect = GlSegment new(p1, p2)
            if (debug) layer group add(stairRect)

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
            if (through) {
                shape setLayers(PhysicLayers FURNITURE | PhysicLayers HERO_THROUGH)
            } else {
                shape setLayers(PhysicLayers FURNITURE | PhysicLayers HERO_TILES)
            }
            shape setCollisionType(1)
            level space addShape(shape)
        }
    }

    initProperties: func {
        if (def name startsWith?("stair")) {
            stair = true
        } else if (def name startsWith?("ladder")) {
            ladder = true
        } else if (def name startsWith?("through")) {
            through = true
        }
    }

    update: func {
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

