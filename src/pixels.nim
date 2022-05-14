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
  Color* = distinct int

const
  White* = Color 0xffffff
  Orange* = Color 0xFFA500
  Blue* = Color 0x00FFFF
  Red* = Color 0xFF0000
  Yellow* = Color 0xFFFF00
  Pink* = Color 0xFF00FF
  Gray* = Color 0x808080
  Green* = Color 0x44FF44
  Deeppink* = Color 0xFF1493

var
  window: WindowPtr
  renderer: RendererPtr
  font: FontPtr

proc toSdlColor(x: Color): sdl2.Color {.inline.} =
  let x = x.int
  result = color(x shr 16 and 0xff, x shr 8 and 0xff, x and 0xff, 0)

proc putPixel*(x, y: int; col: Color) =
  renderer.setDrawColor toSdlColor(col)
  renderer.drawPoint(x.cint, y.cint)
  #var r = rect(cint(x), cint(y), cint(10), cint(10))
  #renderer.fillRect(r)

proc drawText*(x, y: int; text: string; size: int; color: Color) =
  let surface = ttf.renderTextSolid(font, text, toSdlColor color)
  let texture = renderer.createTextureFromSurface(surface)
  var d: Rect
  d.x = 1
  d.y = cint y
  queryTexture(texture, nil, nil, addr(d.w), addr(d.h))
  renderer.copy texture, nil, addr d
  surface.freeSurface
  texture.destroy

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
  renderer.present()
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

for i in 0..80:
  putPixel 80, 80+i, Yellow

drawtext 80, 800, "Hello World", 15, Yellow

addQuitProc(proc () {.noconv.} = waitLoop())
