
import structs/[ArrayList, HashMap]

import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use yaml
import yaml/[Parser, Document]

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

    defs := static HashMap<String, TileDef> new()
    logger := static Log getLogger("tile")

    level: Level
    layer: Layer

    gfx: GlGroup
    rect: GlSprite

    body: CpBody
    shape: CpShape

    def: TileDef

    init: func (=layer, =def, pos: Vec2) {
        level = layer level

        gfx = GlGroup new()

        rect = GlSprite new(def image)
        rect pos set!(pos)
        gfx add(rect)

        layer group add(gfx)

        if (!def inert) {
            logger warn("Non-inert tiles are not supported yet!")
        }

        // workaround. Le sigh.
        (sBody, sShape) := level space createStaticBox(rect)
        body = sBody
        shape = sShape

        shape setFriction(def friction)
        shape setLayers(ShapeGroup FURNITURE | ShapeGroup HERO)
        shape setCollisionType(1)
        level space addShape(shape)
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

