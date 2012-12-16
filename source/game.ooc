
use dye
import dye/[core, input, sprite, font]

use deadlogger
import deadlogger/[Log, Logger, Handler, Formatter]

import legithief/[level, hero, item]

import os/[Time, Env]

main: func (argc: Int, argv: CString*) {

    app := App new()
    app run()

}

App: class {

    log: Logger
    dye: DyeContext
    input: Input
    running := true

    level: Level
    
    init: func {
        initLogging()

        // SDL suxxorz, no function but an env var? Wtf?
        Env set("SDL_VIDEO_CENTERED", "1")

        log info("Creating game engine")

        dye = DyeContext new(1280, 720, "legithief", false)
        dye setClearColor(Color white())

        setupEvents()
        Item loadDefinitions()
        level = Level new(dye, input)
    }

    run: func {
        log info("Starting engine")

        while (running) {
            timeStep := 1000.0 / 60.0
            Time sleepMilli(timeStep)
            update()
        }

        log info("Engine exited")

        dye quit()
    }

    update: func {
        input _poll()
        level update()
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
        log = Log getLogger("legithief")
    }

    setupEvents: func {
        input = Input new()

        input onKeyPress(Keys ESC, ||
            running = false
        )
    }

}

