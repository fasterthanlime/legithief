
import legithief/[level, utils]

import dye/[core, input, sprite, font, math, primitives]

use sdl
import sdl/[Core]

import math
import structs/[ArrayList, Stack, HashMap]

import legithief/[editor-ui]

EditorLayer: class {

    moving := false

    objects := ArrayList<EditorObject> new()
    ui: UI

    selectedObjects := ArrayList<EditorObject> new()

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

    click: func {
        // Shift = multi-selection
        if (!ui input isPressed(Keys SHIFT)) {
            clearSelection()
        }

        singleSelect()
    }

    singleSelect: func {
        handPos := ui handPos()

        for (o in objects) {
            if (o contains?(handPos)) {
                if (ui input isPressed(Keys SHIFT)) {
                    toggleSelect(o)
                } else {
                    select(o)
                }
                break
            }
        }
    }

    toggleSelect: func (o: EditorObject) {
        if (selectedObjects contains?(o)) {
            deselect(o)
        } else {
            select(o)
        }
    }

    select: func (o: EditorObject) {
        if (!selectedObjects contains?(o)) {
            o outlineGroup visible = true
            selectedObjects add(o)
        }
    }

    deselect: func (o: EditorObject) {
        if (selectedObjects contains?(o)) {
            o outlineGroup visible = false
            selectedObjects remove(o)
        }
    }

    clearSelection: func {
        while (!selectedObjects empty?()) {
            deselect(selectedObjects get(0))
        }
    }

    drag: func (delta: Vec2) {
        if (!moving) return

        for (o in selectedObjects) {
            o pos add!(delta)
        }
    }

    dragStart: func (handStart: Vec2) {
        inSelection := false
        moving = false

        for (o in selectedObjects) {
            if (o contains?(handStart)) {
                inSelection = true
                break
            }
        }

        if (inSelection) {
            moving = true // all good
        } else {
            singleSelect()
            if (!selectedObjects empty?()) {
                moving = true
            }
        }
    }

    dragEnd: func {
        moving = false

        // CTRL = precise dragging
        if (ui input isPressed(Keys CTRL)) return

        for (o in selectedObjects) {
            o pos snap!(ui gridSize)
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

    clone: func -> This {
        null
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

