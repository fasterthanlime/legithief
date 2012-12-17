
import structs/[ArrayList, HashMap]

import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use yaml
import yaml/[Parser, Document]

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

    defs := static HashMap<String, ItemDef> new()
    logger := static Log getLogger("item")

    level: Level
    layer: Layer

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
    }

    update: func {
        gfx sync(body)
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

