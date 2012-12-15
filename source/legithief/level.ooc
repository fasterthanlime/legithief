
import legithief/[utils, hero, block]

import structs/ArrayList

import dye/[core, input, sprite, font, primitives, math]

use chipmunk
import chipmunk

Level: class {

    dye: DyeContext
    input: Input

    hero: Hero
    blocks := ArrayList<Block> new()

    group: GlGroup

    space: CpSpace

    /* layers */
    bgLayer: GlGroup
    heroLayer: GlGroup
    hudLayer: GlGroup

    init: func (=dye, globalInput: Input) {
        input = globalInput sub()
        
        initGfx()
        initPhysx()

        hero = Hero new(this)

        block := Block new(this)
        blocks add(block)
    }

    update: func {
        hero update()
        for (block in blocks) {
            block update()
        }

        timeStep: CpFloat = 1.0 / 60.0 // goal = 60 FPS
        space step(timeStep)
        space step(timeStep)
    }

    initPhysx: func {
        space = CpSpace new()

        gravity := cpv(0, 500)
        space setGravity(gravity)

        p1 := vec2(0, 200)
        p2 := vec2(800, 400)

        ground := CpSegmentShape new(space getStaticBody(), cpv(p1), cpv(p2), 0)
        ground setFriction(1)
        space addShape(ground)

        bgLayer add(GlSegment new(p1, p2))
    }

    initGfx: func {
        group = GlGroup new()
        dye add(group)

        bgLayer = GlGroup new()
        group add(bgLayer)

        heroLayer = GlGroup new()
        group add(heroLayer)

        hudLayer = GlGroup new()
        group add(hudLayer)

        buildHud()
    }

    buildHud: func {
        text := GlText new("assets/ttf/font.ttf", "Legithief")
        hudLayer add(text)
    }
}

