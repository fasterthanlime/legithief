
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
        initItems()

        hero = Hero new(this)

        spawnItem("double-sofa", vec2(500, 100))
        spawnItem("single-sofa", vec2(600, 100))
        for (i in 0..6) {
            spawnItem("trash", vec2(400 - i * 40, 100))
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

        target := vec2(
            dye width / 2 - hero gfx pos x,
            dye height / 2 - hero gfx pos y
        )
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

    initItems: func {
        parser := YAMLParser new()
        parser setInputFile("assets/items/index.yml")

        doc := Document new()
        parser parseAll(doc)

        dict := doc getRootNode() toMap()
        items := dict get("items") toList()

        for (item in items) {
            name := item toString()
            "Loading item %s" printfln(name)
            Item define(name)
        }
    }

    buildHud: func {
        text := GlText new("assets/ttf/font.ttf", "Legithief - space = jump, shift = swing bat")
        text color = Color black()
        hudLayer add(text)
    }
}

