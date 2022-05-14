# (c) 2022 Andreas Rumpf

import sdl2, sdl2/ttf

const
  WindowWidth = 640
  WindowHeight = 480

  TextWidth = 128
  TextHeight = 15

when false:
  proc draw(renderer: RendererPtr, paddle: Paddle) =
    renderer.setDrawColor 255, 255, 255, 255 # white
    var r = rect(
      cint(paddle.x), cint(paddle.y),
      cint(PaddleWidth), cint(PaddleHeight)
    )
    renderer.fillRect(r)

  proc drawScores(
    renderer: RendererPtr, font: FontPtr, scores: tuple[player: uint, opponent: uint]
  ) =
    let
      color = color(255, 255, 255, 0)
      text = $scores.player & " : " & $scores.opponent
      surface = ttf.renderTextSolid(font, text, color)
      texture = renderer.createTextureFromSurface(surface)

    surface.freeSurface
    defer: texture.destroy

    var r = rect(
      (WindowWidth - TextWidth) div 2,
      0,
      TextWidth,
      TextHeight
    )
    renderer.copy texture, nil, addr r

type SDLException = object of Defect

template sdlFailIf(condition: typed, reason: string) =
  if condition: raise SDLException.newException(
    reason & ", SDL error " & $getError()
  )


type
  Color* = distinct uint32

const
  White = 0xffffff
  Orange = 0xFFA500
  Blue = 0x00FFFF
  Red = 0xFF0000
  Yellow = 0xFFFF00
  Pink = 0xFF00FF
  Gray = 0x808080
  Green = 0x44FF44
  Deeppink = 0xFF1493


var
  window: WindowPtr
  renderer: RendererPtr
  font: FontPtr

proc fontByName(name: string; size: int): FontPtr =
  result = openFont(name & ".ttf", size.cint)
  if result.isNil:
    when defined(windows):
      const location = "C:\\Windows\\Fonts\\"
    elif defined(macosx):
      const location = r"/Library/Fonts/"
    elif defined(linux):
      const location = r"/usr/share/fonts/truetype/"
    elif defined(bsd):
      const location = "/usr/local/lib/X11/fonts/TrueType"
    else:
      const location = ""
    result = openFont(location & name & ".ttf", size.cint)

proc setup() =
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_EVENTS)): "SDL2 initialization failed"
  window = createWindow(
    title = "Pixels Canvas",
    x = SDL_WINDOWPOS_CENTERED,
    y = SDL_WINDOWPOS_CENTERED,
    w = WindowWidth,
    h = WindowHeight,
    flags = SDL_WINDOW_SHOWN
  )
  sdlFailIf window.isNil: "window could not be created"
  renderer = createRenderer(
    window = window,
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )
  sdlFailIf renderer.isNil: "renderer could not be created"
  sdlFailIf(not ttfInit()): "SDL_TTF initialization failed"
  font = fontByName(when defined(osx): "Arial Unicode" else: "Arial", TextHeight)
  sdlFailIf font.isNil: "font could not be created"

proc waitLoop() =
  var keepRunning = true
  while keepRunning:
    var event = defaultEvent
    while pollEvent(event):
      if event.kind == QuitEvent:
        keepRunning = false
        break
  ttfQuit()
  renderer.destroy()
  window.destroy()
  sdl2.quit()

setup()

addQuitProc(proc () {.noconv.} = waitLoop())

when false:
  import sdl2

  proc putPixel*(x, y: int; col: Color) = discard

  # don't make the Window disappear:
  addQuitProc(proc () =
    while true:
      discard
  )

  when isMainModule:
    discard

