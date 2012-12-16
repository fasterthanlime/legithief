
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use sdl
import sdl/[Core]

import math
import structs/[ArrayList, Stack, HashMap]

import legithief/[editor-ui]

EditorLayer: class {

    objects := ArrayList<EditorObject> new()
    ui: UI

    group: GlGroup

    init: func (=ui) {
        group = GlGroup new()
        ui layerGroup add(group)
    }

    add: func (object: EditorObject) {
        object layer = this
        objects add(object)
        group add(object group)
    }

    remove: func (object: EditorObject) {
        object layer = null
        objects remove(object)
        group remove(object group)
    }

    update: func {
        for (o in objects) {
            o update()
        }
    }

    destroy: func {
        while (!objects empty?()) {
            objects get(0) destroy()
        }
        ui layerGroup remove(group)
        ui layers remove(this)
    }

}

EditorObject: class {

    pos := vec2(0, 0)

    layer: EditorLayer

    group: GlGroup
    outlineGroup: GlGroup

    init: func {
        group = GlGroup new()
        outlineGroup = GlGroup new()
        // outlineGroup visible = false
    }

    destroy: func {
        layer remove(this)
    }
    
    contains?: func (pos: Vec2) {
        false
    }

    update: func {
    }

}

HeroObject: class extends EditorObject {

    sprite: GlSprite

    init: func {
        super()

        sprite = GlSprite new("assets/png/hero.png")
        group add(sprite)
    }

    contains?: func (pos: Vec2) {
        true
    }

    update: func {
        sprite pos set!(pos)
    }

}

