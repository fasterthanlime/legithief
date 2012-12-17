
import structs/[ArrayList, HashMap]

import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use deadlogger
import deadlogger/[Log, Logger]

use yaml
import yaml/[Parser, Document]

PropDef: class {

    name: String
    image: String

    init: func (=name) {
        doc := parseYaml("assets/props/%s.yml" format(name))

        dict := doc toMap()
        dict each(|k, v|
            match k {
                case "image" =>
                    image = v toScalar()
                case =>
                    Prop logger warn("Unhandled prop key %s" format(k))
            }
        )
    }

}

Prop: class {

    defs := static HashMap<String, PropDef> new()
    logger := static Log getLogger("prop")

    layer: Layer

    def: PropDef

    rect: GlSprite

    init: func (=layer, =def, pos: Vec2)  {
        rect = GlSprite new(def image)
        rect pos set!(pos)
        layer group add(rect)
    }

    /* loading */

    loadDefinitions: static func {
        for (name in listDefs("assets/props")) {
            Prop define(name)
        }
    }

    define: static func (propName: String) {
        defs put(propName, PropDef new(propName))
    }

    getDefinition: static func (propName: String) -> PropDef {
        defs get(propName)
    }

}

