
import legithief/[level, utils, item, tile, prop]
import legithief/[level-loader]

import dye/[core, input, sprite, font, math, primitives]

use sdl
import sdl/[Core]

import math
import structs/[ArrayList, Stack, HashMap]

import legithief/[editor-ui]

use deadlogger
import deadlogger/[Log, Logger]

InvalidInputException: class extends Exception {
    
    init: super func

}

EditorLayer: class extends LayerBase {

    moving := false

    logger: Logger
    objects := ArrayList<EditorObject> new()
    ui: UI

    selectedObjects := ArrayList<EditorObject> new()

    group: GlGroup

    name: String

    init: func (=ui, =name) {
        group = GlGroup new()
        ui layerGroup add(group)
        logger = Log getLogger("layer: %s" format(name))
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

    insert: func

    update: func {
        for (o in objects) {
            o update()
        }
    }

    deleteSelected: func {
        while (!selectedObjects empty?()) {
            o := selectedObjects get(0)
            deselect(o)
            o destroy()
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
        o := singlePick()
        if (o) {
            if (ui input isPressed(Keys SHIFT)) {
                toggleSelect(o)
            } else {
                select(o)
            }
        }
    }

    singlePick: func -> EditorObject {
        handPos := ui handPos()

        for (o in objects) {
            if (o contains?(handPos)) {
                return o
            }
        }

        null
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
            ourDelta := delta
            if(ui input isPressed(Keys X)) {
                ourDelta y = 0
            } else if (ui input isPressed(Keys Y)) {
                ourDelta x = 0
            }

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
            o := singlePick()
            if (o) {
                clearSelection()
                select(o)
                moving = true
            }
        }

        if (moving && ui input isPressed(Keys D)) {
            old := ArrayList<EditorObject> new()
            old addAll(selectedObjects)
            clearSelection()

            for (o in old) {
                c := o clone()
                add(c)
                select(c)
            }
        }
    }

    dragEnd: func {
        moving = false

        // CTRL = precise dragging
        if (!ui input isPressed(Keys CTRL)) {
            for (o in selectedObjects) {
                o snap!(ui gridSize)
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

    spawnItem: func (name: String, pos: Vec2) {
        def := Item getDefinition(name)
        if (def) {
            logger debug("Spawning item %s" format(name))
            obj := ItemObject new(def)
            obj pos set!(pos)
            add(obj)
        } else {
            logger warn("Unknown item type %s" format(name))
        }
    }

    spawnTile: func (name: String, pos: Vec2) {
        def := Tile getDefinition(name)
        if (def) {
            logger debug("Spawning tile %s" format(name))
            obj := TileObject new(def)
            obj pos set!(pos)
            add(obj)
        } else {
            logger warn("Unknown tile type %s" format(name))
        }
    }

    spawnProp: func (name: String, pos: Vec2) {
        def := Prop getDefinition(name)
        if (def) {
            logger debug("Spawning prop %s" format(name))
            obj := PropObject new(def)
            obj pos set!(pos)
            add(obj)
        } else {
            logger warn("Unknown prop type %s" format(name))
        }
    }

}

ItemLayer: class extends EditorLayer {

    init: super func

    insert: func {
        ui push(InputDialog new(ui, "Enter item name", |name|
            spawnItem(name, ui handPos())
        ))
    }
    
}

PropLayer: class extends EditorLayer {

    init: super func

    insert: func {
        ui push(InputDialog new(ui, "Enter prop name", |name|
            spawnProp(name, ui handPos())
        ))
    }

}

TileLayer: class extends EditorLayer {

    init: super func

    insert: func {
        ui push(InputDialog new(ui, "Enter tile name", |name|
            spawnTile(name, ui handPos())
        ))
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
        // By default objects aren't clonable - they'll just return themselves
        this
    }

    contains?: func ~rect (size, hand: Vec2) -> Bool {
        left  :=  pos x - size x * 0.5
        right :=  pos x + size x * 0.5
        top    := pos y - size y * 0.5
        bottom := pos y + size y * 0.5

        if (hand x < left) return false
        if (hand x > right) return false
        if (hand y < top) return false
        if (hand y > bottom) return false

        true
    }

    update: func {
        group pos set!(pos)
    }

    snap!: func (gridSize: Int) {
        pos snap!(gridSize)
    }
    
    snap!: func ~rect (size: Vec2, gridSize: Int) {
        halfSize := vec2(size x * 0.5, - size y * 0.5)
        pos set!(pos sub(halfSize) snap(gridSize) add(halfSize))
    }

}

HeroObject: class extends EditorObject {

    CHARACTER_COLOR := static Color new(180, 0, 0)

    sprite: GlSprite

    init: func {
        super()

        sprite = GlSprite new("assets/png/hero/hero-01.png")
        group add(sprite)

        rect := GlRectangle new()
        rect size set!(sprite size)
        rect color = CHARACTER_COLOR
        rect filled = false
        rect lineWidth = 2.0
        outlineGroup add(rect)
    }

    destroy: func {
        // the hero can't be destroyed!
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    snap!: func (gridSize: Int) {
        snap!(sprite size, gridSize)
    }

}

ItemObject: class extends EditorObject {

    ITEM_COLOR := static Color new(0, 160, 0)

    sprite: GlSprite
    def: ItemDef

    init: func (=def) {
        super()

        sprite = GlSprite new(def image)
        group add(sprite)

        rect := GlRectangle new()
        rect size set!(sprite size)
        rect color = ITEM_COLOR
        rect filled = false
        rect lineWidth = 2.0
        outlineGroup add(rect)
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    snap!: func (gridSize: Int) {
        snap!(sprite size, gridSize)
    }

    clone: func -> This {
        c := new(def)
        c pos set!(pos)
        c
    }

}

PropObject: class extends EditorObject {

    PROP_COLOR := static Color new(0, 160, 160)

    sprite: GlSprite
    def: PropDef

    init: func (=def) {
        super()

        sprite = GlSprite new(def image)
        group add(sprite)

        rect := GlRectangle new()
        rect size set!(sprite size)
        rect color = PROP_COLOR
        rect filled = false
        rect lineWidth = 2.0
        outlineGroup add(rect)
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    snap!: func (gridSize: Int) {
        snap!(sprite size, gridSize)
    }

    clone: func -> This {
        c := new(def)
        c pos set!(pos)
        c
    }

}

TileObject: class extends EditorObject {

    TILE_COLOR := static Color new(160, 160, 0)

    sprite: GlSprite
    def: TileDef

    init: func (=def) {
        super()

        sprite = GlSprite new(def image)
        group add(sprite)

        rect := GlRectangle new()
        rect size set!(sprite size)
        rect color = TILE_COLOR
        rect filled = false
        rect lineWidth = 2.0
        outlineGroup add(rect)
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    snap!: func (gridSize: Int) {
        snap!(sprite size, gridSize)
    }

    clone: func -> This {
        c := new(def)
        c pos set!(pos)
        c
    }

}

