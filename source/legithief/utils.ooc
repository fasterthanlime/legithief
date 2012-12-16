
use chipmunk
import chipmunk

use dye
import dye/[core, input, sprite, font, primitives, math, anim]

import math

use yaml
import yaml/[Parser, Document]

import structs/[HashMap, List, ArrayList]

/* radians <-> degrees conversion */

toRadians: func (degrees: Float) -> Float {
    degrees * PI / 180.0
}

toDegrees: func (radians: Float) -> Float {
    radians * 180.0 / PI
}

extend CpSpace {

    createStaticBox: func ~fromGlRectangle (rect: GlRectangle) -> (CpBody, CpShape) {
        body := CpBody newStatic()
        body setPos(cpv(rect pos))
        shape := CpBoxShape new(body, rect size x, rect size y)
        return (body, shape)
    }

}

/* Dye <-> Chipmunk Vector conversion */

cpv: func ~fromVec2 (v: Vec2) -> CpVect {
    cpv(v x, v y)
}

/* Dye <-> Chipmunk physics/graphics sync */

extend GlDrawable {

    sync: func (body: CpBody) {
        bodyPos := body getPos()
        pos set!(bodyPos x, bodyPos y)
        angle = toDegrees(body getAngle())
    }

}

/* YAML utils */

extend DocumentNode {

    toMap: func -> HashMap<String, DocumentNode> {
        match this {
            case mn: MappingNode =>
                mn toHashMap()
            case =>
                Exception new("Called toMap() on a %s" format(class name)) throw()
                null
        }
    }

    toList: func -> List<DocumentNode> {
        match this {
            case sn: SequenceNode =>
                sn toList()
            case =>
                Exception new("Called toList() on a %s" format(class name)) throw()
                null
        }
    }

    toScalar: func -> String {
        match this {
            case sn: ScalarNode =>
                sn value
            case =>
                Exception new("Called toScalar() on a %s" format(class name)) throw()
                null
        }
    }

    toInt: func -> Int {
        toScalar() toInt()
    }

    toFloat: func -> Float {
        toScalar() toFloat()
    }

    toVec2: func -> Vec2 {
        list := toList()
        vec2(list[0] toFloat(), list[1] toFloat())
    }

    toVec2List: func -> List<Vec2> {
        list := toList()
        result := ArrayList<Vec2> new()
        list map(|e| e toVec2())
        result
    }

}

isPrintable: func (u: UInt16) -> Bool {
    /* ASCII 32 = ' ', ASCII 126 = '~' */
    (u >= 32 && u <= 126)
}

extend GlAnimSet {

    load: func (characterName: String, part: String, animationName: String, numFrames: Int) {
        numString: String

        if (numFrames < 100) {
            numString = "%02d"
        } else if (numFrames < 1000) {
            numString = "%03d"
        } else {
            Exception new("Too many animation frames!") throw()
        }

        formatString := "assets/png/%s/%s/%s/%s-%s.png" format(characterName, part, animationName, characterName, numString)

        put(animationName, GlAnim sequence(formatString, 1, numFrames))
    }

}


