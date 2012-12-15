
import legithief/[utils, hero, block]

import structs/ArrayList

import dye/[core, input, sprite, font, primitives, math]

use chipmunk
import chipmunk

ShapeGroup: class {
    HERO := static 1
    FURNITURE := static 2
    HOUSE := static 4
}

Level: class {

    dye: DyeContext
    input: Input

    hero: Hero
    blocks := ArrayList<Block> new()

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

        spawnBlock("red-sofa", vec2(500, 100))
        spawnBlock("red-single-sofa", vec2(600, 100))
        for (i in 0..6) {
            spawnBlock("trash", vec2(400 - i * 40, 100))
        }
    }

    spawnBlock: func (blockType: String, pos: Vec2) {
        blocks add(Block new(this, blockType, pos))
    }

    update: func {
        timeStep: CpFloat = 1.0 / 60.0 // goal = 60 FPS
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)
        space step(timeStep * 0.5)

        hero update()
        for (block in blocks) {
            block update()
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

    buildHud: func {
        text := GlText new("assets/ttf/font.ttf", "Legithief - space = jump, shift = swing bat")
        text color = Color black()
        hudLayer add(text)
    }
}

