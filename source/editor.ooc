
use dye
import dye/[core, input, sprite, font]

use deadlogger
import deadlogger/[Log, Logger, Handler, Formatter]

import legithief/[editor-ui]

import os/[Time, Env]

use sdl
import sdl/Core

main: func (argc: Int, argv: CString*) {

    app := App new()
    app run()

}

App: class {

    log: Logger
    dye: DyeContext
    input: Input

    ui: UI
    
    init: func {
        initLogging()

        log info("Creating level editor")

        // SDL suxxorz, no function but an env var? Wtf?
        Env set("SDL_VIDEO_CENTERED", "1")

        dye = DyeContext new(1600, 900, "legithief level editor")
        dye setClearColor(Color white())
        dye setShowCursor(true)
        SDL enableUnicode(true)
        SDL enableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL)

        setupEvents()
        ui = UI new(dye, input)
    }

    run: func {
        log info("Starting engine")

        while (ui running) {
            timeStep := 1000.0 / 60.0
            Time sleepMilli(timeStep)
            update()
        }

        log info("Engine exited")
    }

    update: func {
        input _poll()
        ui update()
        dye render()
    }

    initLogging: func {
        console := StdoutHandler new()
        formatter := NiceFormatter new()
        version (!windows) {
            formatter = ColoredFormatter new(formatter)
        }
        console setFormatter(formatter)

        Log root attachHandler(console)
        log = Log getLogger("legithief-editor")
    }

    setupEvents: func {
        input = Input new()
    }

}

