
import legithief/[utils, hero, item]

import structs/ArrayList

import dye/[core, input, sprite, font, primitives, math]

use chipmunk
import chipmunk

use yaml
import yaml/[Parser, Document]

ShapeGroup: class {
    HERO := static 1
    FURNITURE := static 2
    HOUSE := static 4
}

Level: class {

    dye: DyeContext
    input: Input

    hero: Hero
    items := ArrayList<Item> new()

    group: GlGroup

    space: CpSpace

    /* layers */
    bbgLayer: GlGroup
    bgLayer: GlGroup
    heroLayer: GlGroup
    hudLayer: GlGroup

    init: func (=dye, globalInput: Input) {
        input = globalInput sub()
        
        initGfx()
        initPhysx()

        hero = Hero new(this)

        spawnItem("double-sofa", vec2(500, 100))
        spawnItem("single-sofa", vec2(600, 100))
        spawnItem("bedside-table", vec2(650, 100))
        spawnItem("kitchen", vec2(400,200))
        spawnItem("tv-support", vec2(700,200))
        spawnItem("television", vec2(700,100))
        spawnItem("trash", vec2(400, 100))
        for (i in 0..6) {
            spawnItem("duck", vec2(400 - i * 40, 100))
        }
    }

    spawnItem: func (itemType: String, pos: Vec2) {
        items add(Item new(this, itemType, pos))
    }

    update: func {
        timeStep: CpFloat = 1.0 / 60.0 // goal = 60 FPS
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)

        hero update()
        for (item in items) {
            item update()
        }

        mouseOffset := dye center sub(input getMousePos()) mul(0.5)
        target := dye center sub(hero gfx pos) add(mouseOffset)
        group pos interpolate!(target, 0.12)
    }

    initPhysx: func {
        space = CpSpace new()

        gravity := cpv(0, 500)
        space setGravity(gravity)
        space setDamping(0.9)

        groundRect := GlRectangle new()
        groundRect size set!(16 * 50, 16)
        groundRect pos set!(16 * 25, 200)
        groundRect color = Color black()
        bgLayer add(groundRect)

        (groundBody, ground) := space createStaticBox(groundRect)
        ground setFriction(1)
        ground setLayers(ShapeGroup FURNITURE | ShapeGroup HERO)
        ground setCollisionType(1)
        space addShape(ground)
    }

    initGfx: func {
        bbgLayer = GlGroup new()
        dye add(bbgLayer)

        group = GlGroup new()
        dye add(group)

        bgLayer = GlGroup new()
        group add(bgLayer)

        heroLayer = GlGroup new()
        group add(heroLayer)

        hudLayer = GlGroup new()
        dye add(hudLayer)

        buildHud()
    }

    buildHud: func {
        text := GlText new("assets/ttf/font.ttf", "Legithief - move = wasd, jump = space, run = shift, left click = attack, right click = kick")
        text color = Color black()
        hudLayer add(text)
    }
}

