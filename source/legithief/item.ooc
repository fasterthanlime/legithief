
import structs/[ArrayList, HashMap]

import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

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

ItemDef: class {

    name: String
    image: String
    fire := 0.0
    mass := 10.0
    shape := BoxShape new()

    init: func (=name) {
        parser := YAMLParser new()
        parser setInputFile("assets/items/%s.yml" format(name))

        doc := Document new()
        parser parseAll(doc)

        dict := doc getRootNode() toMap()
        dict each(|k, v|
            match k {
                case "image" =>
                    image = v toScalar()
                case "mass" =>
                    mass = v toFloat()
                case "fire" =>
                    fire = v toFloat()
                case =>
                    "Unhandled item key %s" printfln(k)
            }
        )
    }

}

Item: class {

    defs := static HashMap<String, ItemDef> new()

    level: Level

    gfx: GlGroup
    rect: GlSprite

    body: CpBody
    shape: CpShape

    blockType: String

    def: ItemDef

    init: func (=level, =blockType, pos: Vec2) {
        gfx = GlGroup new()

        def = defs get(blockType)

        rect = GlSprite new(def image)
        gfx add(rect)

        level heroLayer add(gfx)

        mass := def mass
        moment := cpMomentForBox(mass, rect width, rect height)
        body = level space addBody(CpBody new(mass, moment))
        body setPos(cpv(pos))

        shape = level space addShape(CpBoxShape new(body, rect width, rect height))
        shape setFriction(0.5)

        shape setLayers(ShapeGroup FURNITURE)
    }

    update: func {
        gfx sync(body)
    }

    define: static func (itemName: String) {
        defs put(itemName, ItemDef new(itemName))
    }

}

