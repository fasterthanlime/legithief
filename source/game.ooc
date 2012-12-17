
use dye
import dye/[core, input, sprite, font]

use deadlogger
import deadlogger/[Log, Logger, Handler, Formatter]

import legithief/[level, hero, item, tile, prop]
import legithief/[utils]

import os/[Time, Env]
import structs/[ArrayList, HashMap]

use bleep
import bleep

use yaml
import yaml/[Parser, Document]

main: func (argc: Int, argv: CString*) {

    app := App new()
    app run()

}

App: class {

    logger: Logger
    dye: DyeContext
    input: Input
    running := true

    level: Level
    bleep: Bleep

    config := HashMap<String, String> new()
    
    init: func {
        initLogging()

        loadConfig()

        // SDL suxxorz, no function but an env var? Wtf?
        Env set("SDL_VIDEO_CENTERED", "1")

        logger info("Creating game engine")

        dye = DyeContext new(1280, 720, "legithief", false)
        dye setClearColor(Color white())

        bleep = Bleep new()

        setupEvents()
        
        /* Load the definitions for items, tiles, and all assets */
        Item loadDefinitions()
        Tile loadDefinitions()
        Prop loadDefinitions()

        level = Level new(dye, input, bleep)
        level load(config get("level"))
    }

    loadConfig: func {
        parser := YAMLParser new()
        path := "config/config.yml"
        logger info("Loading config from %s" format(path))
        parser setInputFile(path)

        doc := Document new()
        parser parseAll(doc)

        dict := doc getRootNode() toMap()
        dict each(|k, v|
            config put(k, v toScalar())
        )
    }

    run: func {
        logger info("Starting engine")

        while (running) {
            timeStep := 1000.0 / 60.0
            Time sleepMilli(timeStep)
            update()
        }

        logger info("Engine exited")

        bleep destroy()
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
        logger = Log getLogger("legithief")
    }

    setupEvents: func {
        input = Input new()

        input onKeyPress(Keys ESC, ||
            running = false
        )
    }

}

