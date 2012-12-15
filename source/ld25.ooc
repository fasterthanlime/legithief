
use doll
import doll/[core, dye]
import dye/[core, input, sprite, font]

use deadlogger
import deadlogger/[Log, Logger, Handler, Formatter]

main: func (argc: Int, argv: CString*) {

    app := App new()
    app run()

}

App: class {

    log: Logger
    engine: Engine
    dye: Entity
    
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
            dye = engine make("dye", |dye|
                dye set("width", 1024)
                dye set("height", 768)
                //dye set("full-screen", true)
                dye set("title", "LD25")
            )
            engine set("dye", dye)

            setupEvents(dye)
            buildHud(dye)

            game listen("update", |m|
                dye update()
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
        console := StdoutHandler new()
        formatter := NiceFormatter new()
        version (!windows) {
            formatter = ColoredFormatter new(formatter)
        }
        console setFormatter(formatter)

        Log root attachHandler(console)
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

    buildHud: func (dw: Entity) {
        hudGroup := GlGroup new()
        context := dw get("context", DyeContext)
        context add(hudGroup)
        context setClearColor(Color white())

        bg := GlSprite new("assets/png/hud_xcf-bg.png")
        hudGroup add(bg)

        mana := GlCroppedSprite new("assets/png/hud_xcf-blue.png")
        mana pos set!(800, 800)
        hudGroup add(mana)

        dw listen("update", |m|
            mana right = mana right + 1
        )
    }

}

