
use doll
import doll/[core, dye]
import dye/[input]

use deadlogger
import deadlogger/[Log, Logger, Handler]

main: func (argc: Int, argv: CString*) {

    app := App new()
    app run()

}

App: class {

    log: Logger
    engine: Engine
    
    init: func {
        initLogging()

        log info("Creating doll engine")

        engine = Engine new()
        loadLibraries()

        engine def("game", |game|
            log info("Game starting up")

            screen := engine make("screen")
            engine add(screen)
        )

        engine def("screen", |game|
            dw := engine make("dye-window", |dw|
                dw set("width", 1024)
                dw set("height", 768)
                //dw set("full-screen", true)
                dw set("title", "LD25")
            )

            setupEvents(dw)

            engine listen("update", |m|
                dw update()
            )
        )

        engine listen("start", |m|
            engine add(engine make("game"))
        )
    }

    run: func {
        log info("Starting engine")
        engine start()
        log info("Engine exited")
    }

    initLogging: func {
        Log root attachHandler(StdoutHandler new())
        log = Log getLogger("ld25")
    }

    loadLibraries: func {
        engine initDye()
    }

    setupEvents: func (dw: Entity) {
        dw listen("key-released", |m|
            key := m get("keycode", Int)
            match key {
                case Keys ESC =>
                    dw engine emit("quit")
            }
        ) 
    }

}

