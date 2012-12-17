
import legithief/[utils, hero, item, tile, prop, level, editor-ui, editor-objects]

import structs/ArrayList

import dye/[core, math]

use yaml
import yaml/[Emitter, Document]

use deadlogger
import deadlogger/[Log, Logger]

LevelSaver: class {

    logger := static Log getLogger("level-saver")

    name: String
    level: UI

    init: func (=name, =level) {
        emit()
    }

    emit: func {
        doc := Document new()
        map := MappingNode new()
        doc insert(map)

        emitHero(map)

        layerMap := MappingNode new()
        layerMap put("bg", emitLayer(level bgLayer))
        layerMap put("hbg", emitLayer(level hbgLayer))
        layerMap put("h", emitLayer(level hLayer))
        layerMap put("s", emitLayer(level sLayer))
        map put("layers", layerMap)

        emitter := YAMLEmitter new()
        path := "assets/levels/%s.yml" format(name)
        emitter setOutputFile(path)

        emitter streamStart()
        doc emit(emitter)
        emitter streamEnd()

        emitter flush()
        emitter delete()
        logger info("Saved level %s" format(path))
    }

    emitHero: func (root: MappingNode) {
        map := MappingNode new() 

        map put("pos", toSeq(level hero pos))

        root put("hero", map)
    }

    emitLayer: func (layer: EditorLayer) -> SequenceNode {
        seq := SequenceNode new()

        for (object in layer objects) {
            objMap := emitObject(object)
            if (objMap) {
                seq add(objMap)
            }
        }

        seq
    }

    emitObject: func (object: EditorObject) -> MappingNode {
        if (object instanceOf?(HeroObject)) {
            // special case
            return null
        }

        type: String = null
        
        type = match object {
            case io: ItemObject => "item"
            case to: TileObject => "tile"
            case po: PropObject => "prop"
            case =>
                null
        }

        if (!type) {
            logger warn("Unknown object type: %s" format(object class name))
            return null
        }

        map := MappingNode new()
        map put("type", ScalarNode new(type))

        match object {
            case o: ItemObject => map put("name", ScalarNode new(o def name))
            case o: TileObject => map put("name", ScalarNode new(o def name))
            case o: PropObject => map put("name", ScalarNode new(o def name))
        }

        map put("pos", toSeq(object pos))
        map
    }

    /* utils */

    toSeq: func (v: Vec2) -> SequenceNode {
        seq := SequenceNode new()
        seq add(ScalarNode new(v x toString()))
        seq add(ScalarNode new(v y toString()))
        seq
    }

}
