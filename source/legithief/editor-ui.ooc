
import legithief/[level, utils]

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
        ui modalLayer add(group)
    }

    update: func {
    }

    destroy: func {
        ui modalLayer remove(group)
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
        promptText size = 0.2
        promptText pos set!(- rect size x / 2 + 10, -10)
        group add(promptText)

        text = GlText new(UI fontPath, "")
        text color = color lighten(0.03)
        text size = 0.2
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

    fontPath := static "assets/ttf/font.ttf"

    dye: DyeContext
    input: Input
    
    group: GlGroup
    modalLayer: GlGroup
    
    dialogStack := Stack<Dialog> new()

    running := true

    init: func (=dye, globalInput: Input) {
        group = GlGroup new()
        dye add(group)

        modalLayer = GlGroup new()
        group add(modalLayer)

        input = globalInput sub()

        test()

        initEvents()
    }

    test: func {
        push(InputDialog new(this, "Enter level path to load", |path|
            "Should load level %s" printfln(path)
        ))
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
        if (!root?) {
            dialog := dialogStack peek()
            dialog update()
        }
    }

    initEvents: func {
        input onKeyPress(Keys ESC, ||
            if (!root?) return

            running = false
        )
    }

}

