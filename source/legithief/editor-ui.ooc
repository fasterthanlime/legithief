
import legithief/[level, utils, item, tile, prop]
import legithief/[editor-objects, level-loader, level-saver]

import dye/[core, input, sprite, font, math, primitives]

use sdl
import sdl/[Core]

import math
import structs/[ArrayList, Stack]

use deadlogger
import deadlogger/[Log, Logger]

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

    initialized := false

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
    }

    update: func {
        if (initialized) return

        cb := this cb // silly workaround..
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
        initialized = true
    }

}

UI: class extends LevelBase {

    prevMousePos := vec2(0, 0)

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger("editor-ui")

    dye: DyeContext
    input: Input

    hero: HeroObject

    running := true

    /* dragging */
    dragging := false
    dragStart := false
    dragThreshold := 2.0
    dragPath := vec(0, 0)

    gridSize := 32.0

    /* Camera */
    camPos := vec2(0, 0)
    draggingCam := false
    camNudge := 128.0
    
    /* Dye groups */
    group: GlGroup
    worldGroup: GlGroup
        layerGroup: GlGroup
    hudGroup: GlGroup
    dialogGroup: GlGroup
    
    /* Dialogs */
    dialogStack := Stack<Dialog> new()

    /* Layers */
    bgLayer, hbgLayer, hLayer, sLayer: EditorLayer

    layers := ArrayList<EditorLayer> new()
    activeLayer: EditorLayer

    /* HUD */
    camPosText: GlText
    mousePosText: GlText
    activeLayerText: GlText

    /* Constructor */
    init: func (=dye, globalInput: Input) {
        Item loadDefinitions()
        Tile loadDefinitions()
        Prop loadDefinitions()

        group = GlGroup new()
        dye add(group)

        worldGroup = GlGroup new()
        group add(worldGroup)

        {
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

        initHud()
        initLayers()
    }

    reset: func {
        initLayers()
    }

    clearLayers: func {
        while (!layers empty?()) {
            layers get(0) destroy()
        }

        hero = null
    }

    initLayers: func {
        clearLayers()

        bgLayer = PropLayer new(this, "background")
        layers add(bgLayer)

        hbgLayer = PropLayer new(this, "house background")
        layers add(hbgLayer)

        grid := GlGrid new()
        grid width = gridSize
        grid color set!(200, 200, 200)
        layerGroup add(grid)

        cross := GlCross new()
        layerGroup add(cross)

        hLayer = TileLayer new(this, "house")
        layers add(hLayer)

        sLayer = ItemLayer new(this, "sprites")
        layers add(sLayer)

        hero = HeroObject new()
        hero pos set!(0, 0)
        sLayer add(hero)

        setActiveLayer(sLayer)
    }

    setHeroPos: func (pos: Vec2) {
        hero pos set!(pos)
    }

    initHud: func {
        camPosText = GlText new(fontPath, "camera pos")
        camPosText color set!(Color black())
        hudGroup add(camPosText)

        mousePosText = GlText new(fontPath, "camera pos")
        mousePosText color set!(Color black())
        mousePosText pos add!(300, 0)
        hudGroup add(mousePosText)

        activeLayerText = GlText new(fontPath, "active layer: sprites")
        activeLayerText color set!(Color black())
        activeLayerText pos set!(100, dye height - 100)
        hudGroup add(activeLayerText)
    }

    updateHud: func {
        camPosText value = "camera pos: %s" format(camPos _)
        mousePosText value = "mouse pos: %s" format(handPos() _)
    }

    handPos: func -> Vec2 {
        toWorld(input getMousePos())
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
        
        if (draggingCam) {
            camPos sub!(delta)
        }

        if (dragging && activeLayer) {
            activeLayer drag(delta)
        }

        if (dragStart) {
            dragPath add!(delta)

            if (dragPath norm() >= dragThreshold) {
                // Yup, it's a drag
                dragStart = false
                dragging = true

                if (activeLayer) {
                    activeLayer dragStart(handPos() sub(dragPath))
                    activeLayer drag(dragPath)
                }
            }
        }

        prevMousePos set!(mousePos)
    }

    setActiveLayer: func (layer: EditorLayer) {
        if (activeLayer) {
            activeLayer clearSelection()
        }
        activeLayer = layer
        activeLayerText value = "active layer: %s" format(activeLayer name)
    }

    initEvents: func {
        input onKeyPress(|kev|
            if (!root?) return

            match (kev code) {
                case Keys ESC =>
                    running = false
                case Keys F1 =>
                    push(InputDialog new(this, "Enter level path to load", |name|
                        LevelLoader new(name, this)
                    ))
                case Keys F2 =>
                    push(InputDialog new(this, "Enter level path to save", |name|
                        LevelSaver new(name, this)
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
                case Keys I =>
                    if (activeLayer) {
                        activeLayer insert()
                    }
                case Keys BACKSPACE || Keys DEL =>
                    if (activeLayer) activeLayer deleteSelected()
                case Keys _1 =>
                    setActiveLayer(bgLayer)
                case Keys _2 =>
                    setActiveLayer(hbgLayer)
                case Keys _3 =>
                    setActiveLayer(hLayer)
                case Keys _4 =>
                    setActiveLayer(sLayer)
            }
        )

        input onMousePress(Buttons LEFT, ||
            dragStart = true
            dragPath = vec2(0, 0)
            dragging = false
        )

        input onMouseRelease(Buttons LEFT, ||
            dragStart = false
            if (dragging) {
                dragging = false
                if (activeLayer) {
                    activeLayer dragEnd()
                }
            } else {
                if (activeLayer) {
                    activeLayer click()
                }
            }
        )

        input onMousePress(Buttons MIDDLE, ||
            draggingCam = true
        )

        input onMouseRelease(Buttons MIDDLE, ||
            draggingCam = false
        )
    }

    screenSize: func -> Vec2 {
        vec2(dye width, dye height)
    }

    /* Coordinate */

    toWorld: func (mouseCoords: Vec2) -> Vec2 {
        mouseCoords sub(screenSize() mul(0.5)) add(camPos)
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

