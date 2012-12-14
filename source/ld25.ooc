
use doll
import doll/[core, dye]

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

            engine emit("quit")
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

}

