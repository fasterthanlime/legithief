
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

            if (o contains?(ui handPos())) {
                o outlineGroup visible = true
            } else {
                o outlineGroup visible = false
            }
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
        outlineGroup visible = false
        group add(outlineGroup)
    }

    destroy: func {
        layer remove(this)
    }
    
    contains?: func (hand: Vec2) -> Bool {
        false
    }

    contains?: func ~rect (size, hand: Vec2) -> Bool {
        left := pos x - size x
        right :=  pos x + size x
        top := pos y - size y
        bottom := pos y + size y

        if (hand x < left) return false
        if (hand x > right) return false
        if (hand y < top) return false
        if (hand y > bottom) return false

        true
    }

    update: func {
        group pos set!(pos)
        outlineGroup pos set!(pos)
    }

}

HeroObject: class extends EditorObject {

    sprite: GlSprite

    init: func {
        super()

        sprite = GlSprite new("assets/png/hero.png")
        group add(sprite)

        rect := GlRectangle new()
        rect size set!(sprite size)
        rect color = Color red()
        rect filled = false
        outlineGroup add(rect)
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    update: func {
        super()
    }

}

