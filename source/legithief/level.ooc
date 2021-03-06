
import legithief/[utils, hero, item, tile, prop, flame, molotov]
import legithief/[level-loader]

import structs/ArrayList
import os/Time
import math/Random

import dye/[core, input, sprite, font, primitives, math]

use chipmunk
import chipmunk

use deadlogger
import deadlogger/[Log, Logger]

use bleep
import bleep

use yaml
import yaml/[Parser, Document]

PhysicLayers: class {
    HERO := static 1
    FURNITURE := static 2
    HOUSE := static 4
    HERO_TILES := static 8
    HERO_STAIRS := static 16
    HERO_THROUGH := static 32
    FIRE := static 64
    BREAKING := static 128
}

PhysicGroups: class {
    HERO := static 1
    FIRE := static 2
}

Level: class extends LevelBase {

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger("Level")

    dye: DyeContext
    input: Input

    hero: Hero

    group: GlGroup

    space: CpSpace

    /* layers */
    bgLayer: Layer
    hbgLayer: Layer
    hLayer: Layer
    sLayer: Layer
    fLayer: Layer // flame layer, not in level spec

    layers := ArrayList<Layer> new()

    layerGroup: GlGroup
    hudGroup, overHudGroup, bottomHudGroup: GlGroup

    bleep: Bleep

    /* Plan */
    plan: Plan
    def: StageDef
    levelEnd: LevelEnd
    gameoverScreen, titleScreen: FullScreen

    /* clock */
    clock: Clock

    score := 0
    scoreDisplay: Score

    cashSamples := ArrayList<Sample> new()
    lastNoiseCounter := Time runTime()

    /* code */
    init: func (=dye, globalInput: Input, =bleep) {
        input = globalInput sub()
        
        initSamples()
        initGfx()
        initPhysx()
        initLayers()

        hero = Hero new(sLayer)
        clock = Clock new(this)
        scoreDisplay = Score new(this)
        levelEnd = LevelEnd new(this)
        titleScreen = FullScreen new(this, "titlescreen")
        gameoverScreen = FullScreen new(this, "gameover")

        initEvents()
        
        titleScreen show()
    }

    initSamples: func {
        for (i in 1..3) {
            cashSamples add(bleep loadSample("assets/wav/cash%d.wav" format(i)))
        }
    }

    initEvents: func {
        input onMousePress(Buttons LEFT, ||
            if (levelEnd shown?()) {
                loadNextLevel()
            } else if (titleScreen shown?()) {
                titleScreen hide()
                loadNextLevel()
            } else if (gameoverScreen shown?()) {
                gameoverScreen hide()
                plan current = 0
                loadNextLevel()
            }
        )

        input onKeyPress(Keys F1, ||
            if (levelRunning?()) {
                endLevel()
            }
        )
    }

    loadPlan: func (name: String) {
        plan = Plan new(name)
    }

    loadNextLevel: func {
        levelEnd hide()
        next := plan nextStage()
        if (next) {
            load(next)
        } else {
            gameoverScreen show()
        }
    }

    load: func (=def) {
        LevelLoader new(def name, this)
        clock setDuration(def duration)

        if (def voice) {
            path := "assets/ogg/%s.ogg" format(def voice)
            bleep playMusic(path, 0)
        }
    }

    endLevel: func {
        levelEnd setScore(score)
        levelEnd show()
    }

    levelRunning?: func -> Bool {
        !(levelEnd shown?() || gameoverScreen shown?() || titleScreen shown?())
    }

    addScore: func (amount: Int) {
        score += amount
        scoreDisplay setScore(score)

        current := Time runTime()
        if (current - lastNoiseCounter > 600) {
            Random choice(cashSamples) play(0)
        }
        lastNoiseCounter = current
    }

    update: func {
        if (levelEnd shown?()) {
            levelEnd update()
        }

        clock update(levelRunning?())

        if (levelRunning?()) {
            timeStep: CpFloat = 1.0 / 60.0 // goal = 60 FPS
            space step(timeStep * 0.5)
            space step(timeStep * 0.5)
            space step(timeStep * 0.5)
            space step(timeStep * 0.5)

            hero update()
            for (layer in layers) {
                layer update()
            }
        }
        
        mouseOffset := dye center sub(input getMousePos()) mul(1.2)
        target := dye center sub(hero gfx pos) add(mouseOffset)
        group pos interpolate!(target, 0.12)
    }

    reset: func {
        for (layer in layers) {
            layer reset()
        }

        clock setDuration(0)
        levelEnd score = 0
        bleep stopMusic()
        score = 0
        scoreDisplay setScore(0)
        hero reset()
    }

    initGfx: func {
        group = GlGroup new()
        dye add(group)

            layerGroup = GlGroup new()
            group add(layerGroup)

        hudGroup = GlGroup new()
        dye add(hudGroup)

        overHudGroup = GlGroup new()
        dye add(overHudGroup)

        buildHud()
    }

    buildHud: func {
        bottomHudGroup = GlGroup new()
        bottomHudGroup pos set!(dye width / 2, dye height - 24)

        bottomHud := GlSprite new("assets/png/bottom-ui.png")
        bottomHudGroup add(bottomHud)

        hudGroup add(bottomHudGroup)

        skipText := GlText new(Level fontPath, "Bored? You can skip the level with F1")
        skipText color set!(20, 20, 20)
        skipText pos set!(20 - dye width / 2, 10)
        bottomHudGroup add(skipText)
    }

    initPhysx: func {
        space = CpSpace new()

        gravity := cpv(0, 500)
        space setGravity(gravity)
        space setDamping(0.9)
    }

    initLayers: func {
        bgLayer = addLayer("background")
        hbgLayer = addLayer("house background")
        hLayer = addLayer("house")
        sLayer = addLayer("sprites")
        fLayer = addLayer("flames")
    }

    addLayer: func (name: String) -> Layer {
        layer := Layer new(this, name)
        layers add(layer)
        layerGroup add(layer group)
        layer
    }

    setHeroPos: func (v: Vec2) {
        hero setPos(v)
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

/* game layer */

Layer: class extends LayerBase {

    logger: Logger

    items := ArrayList<Item> new()
    tiles := ArrayList<Tile> new()
    props := ArrayList<Prop> new()

    flames := ArrayList<Flame> new()
    molotovs := ArrayList<Molotov> new()

    level: Level

    name: String
    group: GlGroup

    init: func (=level, =name) {
        group = GlGroup new()
        logger = Log getLogger("layer: %s" format(name))
    }

    reset: func {
        for (i in items) {
            i destroy()
        }
        items clear()

        for (t in tiles) {
            t destroy()
        }
        tiles clear()

        for (p in props) {
            p destroy()
        }
        props clear()

        for (f in flames) {
            f destroy()
        }
        flames clear()

        for (m in molotovs) {
            m destroy()
        }
        molotovs clear()
    }

    update: func {
        updateItems()
        updateTiles()
        updateFlames()
        updateMolotovs()
    }

    updateTiles: func {
        tileIter := tiles iterator()
        while (tileIter hasNext?()) {
            tile := tileIter next()
            if (!tile update()) {
                tile destroy()
                tileIter remove()
            }
        }
    }

    updateItems: func {
        itemIter := items iterator()
        while (itemIter hasNext?()) {
            item := itemIter next()
            if (!item update()) {
                item destroy()
                itemIter remove()
            }
        }
    }

    updateFlames: func {
        flameIter := flames iterator()
        while (flameIter hasNext?()) {
            flame := flameIter next()
            if (!flame update()) {
                flame destroy()
                flameIter remove()
            }
        }
    }

    updateMolotovs: func {
        molotovIter := molotovs iterator()
        while (molotovIter hasNext?()) {
            molotov := molotovIter next()
            if (!molotov update()) {
                molotov destroy()
                molotovIter remove()
            }
        }
    }

    spawnItem: func (name: String, pos: Vec2) {
        def := Item getDefinition(name)

        if (def) {
            item := Item new(this, def, pos)
            items add(item)
            item
        } else {
            logger warn("Unknown item type: %s" format(name))
            null
        }
    }

    spawnTile: func (name: String, pos: Vec2) {
        def := Tile getDefinition(name)

        if (def) {
            tile := Tile new(this, def, pos)
            tiles add(tile)
            tile
        } else {
            logger warn("Unknown tile type: %s" format(name))
            null
        }
    }

    spawnProp: func (name: String, pos: Vec2) {
        def := Prop getDefinition(name)

        if (def) {
            prop := Prop new(this, def, pos)
            props add(prop)
            prop
        } else {
            logger warn("Unknown prop type: %s" format(name))
            null
        }
    }

    spawnFlame: func (pos: Vec2) -> Flame {
        // too many flames!
        if (flames size > 120) {
            f := flames removeAt(0)
            f setPos(pos)
            flames add(f)
            return f
        }

        flame := Flame new(this, pos)
        flames add(flame)
        flame
    }

    spawnMolotov: func (pos: Vec2) -> Molotov {
        molotov := Molotov new(this, pos)
        molotovs add(molotov)
        molotov
    }

}

Score: class {

    level: Level

    gfx: GlGroup
    text: GlText

    init: func (=level) {
        gfx = GlGroup new()

        text = GlText new(Level fontPath, "Score: 0")
        text color set!(0, 0, 0)
        text pos set!(0, 10)
        gfx add(text)

        level bottomHudGroup add(gfx)
    }

    setScore: func (score: Int) {
        text value = "Score: %d" format(score)
    }


}

Clock: class {

    level: Level

    gfx: GlGroup
    text: GlText

    time := 0
    ended := false
    prev: UInt

    init: func (=level) {
        gfx = GlGroup new()

        text = GlText new(Level fontPath, "Time left: 00:00")
        text color set!(0, 0, 0)
        text pos set!(level dye width / 2 - 180, 10)
        gfx add(text)

        level bottomHudGroup add(gfx)

        prev = Time runTime()
    }

    setDuration: func (seconds: Int) {
        time = seconds * 1_000
        ended = false
    }

    update: func (running: Bool) {
        if (!running) {
            prev = Time runTime()
            return
        }

        curr := Time runTime()
        if (time > 0) {
            time -= (curr - prev)
        } else {
            time = 0
        }

        if (time < 999 && !ended) {
            ended = true
            level endLevel()
        }
        prev = curr

        seconds := time / 1_000

        minutes := (seconds - seconds % 60) / 60
        seconds = seconds - minutes * 60
        text value = "Time left: %02d:%02d" format(minutes, seconds)
    }

}

FullScreen: class {

    name: String
    level: Level

    gfx: GlGroup

    init: func (=level, =name) {
        gfx = GlGroup new()

        bg := GlSprite new("assets/png/%s.png" format(name))
        gfx add(bg)

        gfx center!(level dye)
        gfx visible = false

        level overHudGroup add(gfx)
    }

    shown?: func -> Bool {
        gfx visible
    }

    show: func {
        gfx visible = true
    }

    hide: func {
        gfx visible = false
    }

    update: func {
    }

}

LevelEnd: class {

    level: Level

    gfx: GlGroup
    text: GlText
    scoreText: GlText
    tauntText: GlText
    clickText: GlText

    taunts := ArrayList<String> new()

    score, scoreDisplayed: Int

    scoreIncrement := 579

    init: func (=level) {
        initTaunts()

        gfx = GlGroup new()

        bg := GlSprite new("assets/png/level-end.png")
        gfx add(bg)

        textGroup := GlGroup new()
        textGroup pos set!(-230, 30)
        gfx add(textGroup)

        text = GlText new(Level fontPath, "Level cleared")
        text color set!(0, 0, 0)
        text pos set!(0, -160)
        textGroup add(text)

        tauntText = GlText new(Level fontPath, "")
        tauntText color set!(0, 0, 0)
        tauntText pos set!(0, -110)
        textGroup add(tauntText)

        scoreText = GlText new(Level fontPath, "Score: 0")
        scoreText color set!(0, 0, 0)
        scoreText pos set!(0, 80)
        textGroup add(scoreText)

        clickText = GlText new(Level fontPath, "Click to continue")
        clickText color set!(20, 20, 20)
        clickText pos set!(0, 130)
        textGroup add(clickText)

        gfx center!(level dye)
        gfx visible = false

        level overHudGroup add(gfx)
    }
   
    initTaunts: func {
        taunts add("A stunning performance.")
        taunts add("A-fucking-mazing. Not.")
        taunts add("Words fail me.")
        taunts add("I think I just peed a little.")
        taunts add("Someday you won't be totally worthless.")
    }

    shown?: func -> Bool {
        gfx visible
    }

    show: func {
        gfx visible = true
        scoreDisplayed = 0
        tauntText value = Random choice(taunts)
    }

    hide: func {
        gfx visible = false
    }

    setScore: func (=score) {}

    update: func {
        if (gfx visible) {
            if (scoreDisplayed < score) {
                scoreDisplayed += scoreIncrement
                if (scoreDisplayed > score) {
                    scoreDisplayed = score
                }
            }
        }

        scoreText value = "Score: %d" format(scoreDisplayed)
    }

}

Plan: class {

    logger := static Log getLogger("plan")

    stages := ArrayList<StageDef> new()
    current := 0
    name: String

    init: func (=name) {
        path := "assets/plans/%s.yml" format(name)
        logger info("Loading plan from %s" format(path))
        root := parseYaml(path)
        seq := root toList()
        for (node in seq) {
            stages add(StageDef new(node))
        }
    }

    nextStage: func -> StageDef {
        if (current >= stages size) return null
        
        def := stages get(current)
        current += 1
        def
    }

}

StageDef: class {

    name: String
    desc: String
    voice: String
    duration: Int

    init: func (node: DocumentNode) {
        map := node toMap()

        map each(|k, v|
            match k {
                case "name" =>
                    name = v toScalar()
                case "desc" =>
                    desc = v toScalar()
                case "voice" =>
                    voice = v toScalar()
                case "duration" =>
                    duration = v toInt()
            }
        )
    }

}


