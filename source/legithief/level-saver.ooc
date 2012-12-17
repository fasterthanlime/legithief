
import legithief/[utils, hero, item, tile, level, editor-ui, editor-objects]

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

        emitter := YAMLEmitter new()
        emitter setOutputFile("assets/levels/%s.yml" format(name))

        emitter streamStart()
        doc emit(emitter)
        emitter streamEnd()

        emitter flush()
        emitter delete()
    }

    emitHero: func (root: MappingNode) {
        map := MappingNode new() 

        map put("pos", toSeq(level hero pos))

        root put("hero", map)
    }

    /* utils */

    toSeq: func (v: Vec2) -> SequenceNode {
        seq := SequenceNode new()
        seq add(ScalarNode new(v x toString()))
        seq add(ScalarNode new(v y toString()))
        seq
    }

}
