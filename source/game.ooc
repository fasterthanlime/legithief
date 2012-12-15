
use dye
import dye/[core, input, sprite, font]

use deadlogger
import deadlogger/[Log, Logger, Handler, Formatter]

import legithief/[level, hero]

import os/Time

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

        log info("Creating game engine")

        dye = DyeContext new(1024, 768, "legithief")
        dye setClearColor(Color white())
        dye setShowCursor(false)

        setupEvents()
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

