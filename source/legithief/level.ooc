
import legithief/[utils, hero, item, tile, prop, flame, molotov]
import legithief/[level-loader]

import structs/ArrayList
import os/Time

import dye/[core, input, sprite, font, primitives, math]

use chipmunk
import chipmunk

use deadlogger
import deadlogger/[Log, Logger]

use bleep
import bleep

PhysicLayers: class {
    HERO := static 1
    FURNITURE := static 2
    HOUSE := static 4
    HERO_TILES := static 8
    HERO_STAIRS := static 16
    HERO_THROUGH := static 32
    FIRE := static 64
}

PhysicGroups: class {
    HERO := static 1
    FIRE := static 2
}

Level: class extends LevelBase {

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
    fLayer: Layer // flame layer, not in level spec

    layers := ArrayList<Layer> new()

    layerGroup: GlGroup
    hudGroup: GlGroup

    bleep: Bleep

    /* clock */
    clock: Clock

    /* code */
    init: func (=dye, globalInput: Input, =bleep) {
        input = globalInput sub()
        
        initGfx()
        initPhysx()
        initLayers()

        hero = Hero new(sLayer)
        clock = Clock new(this)
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

        clock update()

        hero update()
        for (layer in layers) {
            layer update()
        }
        
        mouseOffset := dye center sub(input getMousePos()) mul(1.2)
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
        fLayer = addLayer("flames")
    }

    addLayer: func (name: String) -> Layer {
        layer := Layer new(this, name)
        layers add(layer)
        layerGroup add(layer group)
        layer
    }

    setHeroPos: func (v: Vec2) {
        hero setPos(v)
    }

    getLayer: func (key: String) -> LayerBase {
        match key {
            case "bg" => bgLayer
            case "hbg" => hbgLayer
            case "h" => hLayer
            case "s" => sLayer
        }
    }

}

/* game layer */

Layer: class extends LayerBase {

    logger: Logger

    items := ArrayList<Item> new()
    tiles := ArrayList<Tile> new()
    props := ArrayList<Prop> new()

    flames := ArrayList<Flame> new()
    molotovs := ArrayList<Molotov> new()

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

        updateFlames()
        updateMolotovs()
    }

    updateFlames: func {
        flameIter := flames iterator()
        while (flameIter hasNext?()) {
            flame := flameIter next()
            if (!flame update()) {
                flame destroy()
                flameIter remove()
            }
        }
    }

    updateMolotovs: func {
        molotovIter := molotovs iterator()
        while (molotovIter hasNext?()) {
            molotov := molotovIter next()
            if (!molotov update()) {
                molotov destroy()
                molotovIter remove()
            }
        }
    }

    spawnItem: func (name: String, pos: Vec2) {
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

    spawnTile: func (name: String, pos: Vec2) {
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

    spawnProp: func (name: String, pos: Vec2) {
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

    spawnFlame: func (pos: Vec2) -> Flame {
        flame := Flame new(this, pos)
        flames add(flame)
        flame
    }

    spawnMolotov: func (pos: Vec2) -> Molotov {
        molotov := Molotov new(this, pos)
        molotovs add(molotov)
        molotov
    }

}

Clock: class {

    level: Level
    gfx: GlGroup
    text: GlText

    time := 30_000
    prev: UInt

    init: func (=level) {
        gfx = GlGroup new()

        bg := GlSprite new("assets/png/clock.png")
        gfx add(bg)

        text = GlText new(Level fontPath, "00:30")
        text color set!(0, 0, 0)
        text pos set!(-27, 10)
        gfx add(text)

        gfx pos set!(level dye width - 100, 80)

        level hudGroup add(gfx)

        prev = Time runTime()
    }

    update: func {
        curr := Time runTime()
        if (time > 0) {
            time -= (curr - prev)
        } else {
            time = 0
        }
        prev = curr

        seconds := time / 1_000
        text value = "00:%02d" format(seconds)
    }

}

