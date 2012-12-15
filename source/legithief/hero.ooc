
import legithief/level

import dye/[core, input, sprite, font, math, primitives]

Hero: class {

    level: Level
    input: Input 

    pos := vec2(600, 200)

    gfx: GlGroup

    init: func (=level) {
        gfx = GlGroup new()
        gfx add(GlSprite new("assets/png/hero.png"))

        level heroLayer add(gfx)

        input = level input sub()
    }

    update: func {
        gfx pos set!(pos)
    }

}
