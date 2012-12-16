
import legithief/[level, utils]
import legithief/[editor-objects]

import dye/[core, input, sprite, font, math, primitives]

use sdl
import sdl/[Core]

import math
import structs/[ArrayList, Stack]

Dialog: class {

    ui: UI
    input: Input
    group: GlGroup
    color := Color new(15, 15, 15)

    init: func (=ui) {
        group = GlGroup new()
        input = ui input sub()
        ui dialogGroup add(group)
    }

    update: func {
    }

    destroy: func {
        ui dialogGroup remove(group)
        input nuke()
        ui pop(this)
    }

}

InputDialog: class extends Dialog {
    
    prompt: String
    text, promptText: GlText

    cb: Func (String)

    init: func (=ui, =prompt, =cb) {
        super(ui)

        bgRect := GlRectangle new()
        bgRect size set!(300, 60)
        bgRect color = color
        group add(bgRect)

        rect := GlRectangle new()
        rect size set!(300, 60)
        rect filled = false
        rect color = color lighten(0.1)
        group add(rect)

        promptText = GlText new(UI fontPath, "> " + prompt)
        promptText color = color lighten(0.1)
        promptText pos set!(- rect size x / 2 + 10, -10)
        group add(promptText)

        text = GlText new(UI fontPath, "")
        text color = color lighten(0.03)
        text pos set!(- rect size x / 2 + 10, 15)
        group add(text)

        group center!(ui dye)

        input onKeyPress(|kev|
            if (kev code == Keys ESC) {
                destroy()
            } if (kev code == Keys ENTER) {
                cb(text value)
                destroy()
            } else if (kev code == Keys BACKSPACE) {
                if (text value size > 0) {
                    text value = text value[0..-2]
                }
            } else if (isPrintable(kev unicode)) {
                text value = "%s%c" format(text value, kev unicode as Char)
            }
        )
    }

    update: func {
    }

}

UI: class {

    prevMousePos := vec2(0, 0)

    fontPath := static "assets/ttf/font.ttf"

    dye: DyeContext
    input: Input

    running := true

    /* Camera */
    camPos := vec2(0, 0)
    dragging := false
    camNudge := 64.0
    
    /* Dye groups */
    group: GlGroup
    worldGroup: GlGroup
        layerGroup: GlGroup
    hudGroup: GlGroup
    dialogGroup: GlGroup
    
    /* Dialogs */
    dialogStack := Stack<Dialog> new()

    /* Layers */
    heroLayer: EditorLayer

    layers := ArrayList<EditorLayer> new()

    /* HUD */
    camPosText: GlText
    mousePosText: GlText

    /* Constructor */
    init: func (=dye, globalInput: Input) {
        group = GlGroup new()
        dye add(group)

        worldGroup = GlGroup new()
        group add(worldGroup)

        {
            cross := GlCross new()
            worldGroup add(cross)

            layerGroup = GlGroup new()
            worldGroup add(layerGroup)
        }

        hudGroup = GlGroup new()
        group add(hudGroup)

        dialogGroup = GlGroup new()
        group add(dialogGroup)

        input = globalInput sub()

        initEvents()
        prevMousePos set!(input getMousePos())

        initLayers()
        initHud()
    }

    clearLayers: func {
        while (!layers empty?()) {
            layers get(0) destroy()
        }
    }

    initLayers: func {
        clearLayers()

        heroLayer = EditorLayer new(this)
        layers add(heroLayer)

        hero := HeroObject new()
        hero pos set!(0, 0)
        heroLayer add(hero)
    }

    initHud: func {
        camPosText = GlText new(fontPath, "camera pos")
        camPosText color set!(Color black())
        hudGroup add(camPosText)

        mousePosText = GlText new(fontPath, "camera pos")
        mousePosText color set!(Color black())
        mousePosText pos add!(250, 0)
        hudGroup add(mousePosText)
    }

    updateHud: func {
        camPosText value = "camera pos: %s" format(camPos _)
        mousePosText value = "mouse pos: %s" format(toWorld(input getMousePos()) _)
    }

    openDialog: func {
    }

    push: func (dialog: Dialog) {
        dialogStack push(dialog)
    }

    pop: func (dialog: Dialog) {
        if (root?) return
        dialogStack pop()
    }

    root?: Bool { get { dialogStack empty?() } }

    update: func {
        updateMouse()

        for (layer in layers) {
            layer update()
        }
        updateCamera()
        updateHud()

        if (!root?) {
            dialog := dialogStack peek()
            dialog update()
        }
    }

    updateCamera: func {
        worldGroup pos set!(screenSize() mul(0.5) add(camPos mul(-1.0)))
    }

    updateMouse: func {
        mousePos := input getMousePos()
        delta := mousePos sub(prevMousePos)
        
        if (dragging) {
            camPos sub!(delta)
        }

        prevMousePos set!(mousePos)
    }

    initEvents: func {
        input onKeyPress(|kev|
            if (!root?) return

            match (kev code) {
                case Keys ESC =>
                    running = false
                case Keys F1 =>
                    push(InputDialog new(this, "Enter level path to load", |path|
                        "Should load level %s" printfln(path)
                    ))
                case Keys F2 =>
                    push(InputDialog new(this, "Enter level path to save", |path|
                        "Should save level %s" printfln(path)
                    ))
                case Keys KP0 =>
                    camPos set!(0, 0)
                case Keys KP4 =>
                    camPos sub!(camNudge, 0)
                case Keys KP6 =>
                    camPos add!(camNudge, 0)
                case Keys KP2 =>
                    camPos add!(0, camNudge)
                case Keys KP8 => 
                    camPos sub!(0, camNudge)
            }
        )

        input onMousePress(Buttons MIDDLE, ||
            dragging = true
        )

        input onMouseRelease(Buttons MIDDLE, ||
            dragging = false
        )
    }

    screenSize: func -> Vec2 {
        vec2(dye width, dye height)
    }

    /* Coordinate */

    toWorld: func (mouseCoords: Vec2) -> Vec2 {
        mouseCoords sub(screenSize() mul(0.5)) add(camPos)
    }

}

