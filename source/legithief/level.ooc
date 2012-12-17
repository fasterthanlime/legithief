
import legithief/[utils, hero, item, tile, prop]
import legithief/[level-loader]

import structs/ArrayList

import dye/[core, input, sprite, font, primitives, math]

use chipmunk
import chipmunk

use deadlogger
import deadlogger/[Log, Logger]

ShapeGroup: class {
    HERO := static 1
    FURNITURE := static 2
    HOUSE := static 4
}

Level: class {

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger("Level")

    dye: DyeContext
    input: Input

    hero: Hero

    group: GlGroup

    space: CpSpace

    /* layers */
    bgLayer: Layer
    hbgLayer: Layer
    hLayer: Layer
    sLayer: Layer

    layers := ArrayList<Layer> new()

    layerGroup: GlGroup
    hudGroup: GlGroup

    init: func (=dye, globalInput: Input) {
        input = globalInput sub()
        
        initGfx()
        initPhysx()
        initLayers()

        hero = Hero new(sLayer)
        load("level1")
    }

    load: func (name: String) {
        LevelLoader new(name, this)
    }

    update: func {
        timeStep: CpFloat = 1.0 / 60.0 // goal = 60 FPS
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)

        hero update()
        for (layer in layers) {
            layer update()
        }

        mouseOffset := dye center sub(input getMousePos()) mul(0.5)
        target := dye center sub(hero gfx pos) add(mouseOffset)
        group pos interpolate!(target, 0.12)
    }

    reset: func {
        logger warn("level: should reset more thoroughly")
    }

    initGfx: func {
        group = GlGroup new()
        dye add(group)

            layerGroup = GlGroup new()
            group add(layerGroup)

        hudGroup = GlGroup new()
        dye add(hudGroup)

        buildHud()
    }

    buildHud: func {
        text := GlText new(fontPath, "Legithief")
        text color = Color black()
        hudGroup add(text)
    }

    initPhysx: func {
        space = CpSpace new()

        gravity := cpv(0, 500)
        space setGravity(gravity)
        space setDamping(0.9)
    }

    initLayers: func {
        bgLayer = addLayer("background")
        hbgLayer = addLayer("house background")
        hLayer = addLayer("house")
        sLayer = addLayer("sprites")
    }

    addLayer: func (name: String) -> Layer {
        layer := Layer new(this, name)
        layers add(layer)
        layerGroup add(layer group)
        layer
    }

    /* Here for testing purposes */
    spawnJunk: func {
        sLayer spawnItem("sofa-double", vec2(500, 100))
        sLayer spawnItem("sofa", vec2(600, 100))
        sLayer spawnItem("nightstand", vec2(650, 100))
        sLayer spawnItem("kitchen", vec2(400,200))
        sLayer spawnItem("tv-support", vec2(700,200))
        sLayer spawnItem("tv", vec2(700,100))
        sLayer spawnItem("trash", vec2(400, 100))

        for (i in -13..28) {
            hLayer spawnTile("brick", vec2(i * 32, 200))
        }
    }

}

Layer: class {

    logger: Logger

    items := ArrayList<Item> new()
    tiles := ArrayList<Tile> new()
    props := ArrayList<Prop> new()

    level: Level

    name: String
    group: GlGroup

    init: func (=level, =name) {
        group = GlGroup new()
        logger = Log getLogger("layer: %s" format(name))
    }

    update: func {
        for (i in items) {
            i update()
        }

        for (t in tiles) {
            t update()
        }
    }

    spawnItem: func (name: String, pos: Vec2) -> Item {
        def := Item getDefinition(name)

        if (def) {
            item := Item new(this, def, pos)
            items add(item)
            item
        } else {
            logger warn("Unknown item type: %s" format(name))
            null
        }
    }

    spawnTile: func (name: String, pos: Vec2) -> Tile {
        def := Tile getDefinition(name)

        if (def) {
            tile := Tile new(this, def, pos)
            tiles add(tile)
            tile
        } else {
            logger warn("Unknown tile type: %s" format(name))
            null
        }
    }

    spawnProp: func (name: String, pos: Vec2) -> Prop {
        def := Prop getDefinition(name)

        if (def) {
            prop := Prop new(this, def, pos)
            props add(prop)
            prop
        } else {
            logger warn("Unknown prop type: %s" format(name))
            null
        }
    }

}

