
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

        p1 := vec2(0, 200)
        p2 := vec2(800, 200)

        ground := CpSegmentShape new(space getStaticBody(), cpv(p1), cpv(p2), 0)
        ground setFriction(1)
        ground setLayers(ShapeGroup FURNITURE | ShapeGroup HERO)
        space addShape(ground)
        
        segment := GlSegment new(p1, p2)
        segment color = Color black()
        bgLayer add(segment)
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

