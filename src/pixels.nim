# (c) 2022 Andreas Rumpf

import sdl2, sdl2/ttf

const
  WindowWidth = 1024
  WindowHeight = 768

type SDLException = object of Defect

template sdlFailIf(condition: typed, reason: string) =
  if condition: raise SDLException.newException(
    reason & ", SDL error " & $getError()
  )


type
  Color* = distinct int

const
  White* = Color 0xffffff
  Black* = Color 0
  Gold* = Color 0xffd700
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

proc toSdlColor(x: Color): sdl2.Color {.inline.} =
  let x = x.int
  result = color(x shr 16 and 0xff, x shr 8 and 0xff, x and 0xff, 0)

proc putPixel*(x, y: int; col: Color = White) =
  renderer.setDrawColor toSdlColor(col)
  renderer.drawPoint(x.cint, y.cint)
  #var r = rect(cint(x), cint(y), cint(10), cint(10))
  #renderer.fillRect(r)

proc fontByName(name: string; size: int): FontPtr =
  result = openFont(cstring(name & ".ttf"), size.cint)
  if result.isNil:
    when defined(windows):
      const location = "C:\\Windows\\Fonts\\"
    elif defined(macosx):
      const location = r"/Library/Fonts/"
    elif defined(linux):
      const location = r"/usr/share/fonts/TTF/"
    elif defined(bsd):
      const location = "/usr/local/lib/X11/fonts/TrueType/"
    else:
      const location = ""
    result = openFont(cstring(location & name & ".ttf"), size.cint)

proc drawText*(x, y: int; text: string; size: int; color: Color = White) =
  var font = fontByName(when defined(osx): "Arial Unicode"
                        elif defined(linux): "FiraSans-Regular"
                        else: "Arial",
                        size)
  sdlFailIf font.isNil: "font could not be created"

  let surface = ttf.renderUnicodeSolid(font, cast[ptr uint16](text.newWideCString), toSdlColor color)
  let texture = renderer.createTextureFromSurface(surface)
  var d: Rect
  d.x = 1
  d.y = cint y
  queryTexture(texture, nil, nil, addr(d.w), addr(d.h))
  renderer.copy texture, nil, addr d
  surface.freeSurface
  texture.destroy
  close font

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
    flags = Renderer_TargetTexture
  )
  # Renderer_Accelerated or Renderer_PresentVsync or
  sdlFailIf renderer.isNil: "renderer could not be created"
  sdlFailIf(not ttfInit()): "SDL_TTF initialization failed"
  renderer.setDrawColor toSdlColor(Color 0)
  clear(renderer)

proc waitLoop() =
  renderer.present()
  var keepRunning = true
  while keepRunning:
    var event = defaultEvent
    while pollEvent(event):
      if event.kind == QuitEvent:
        keepRunning = false
        break

    #present(renderer)
    delay(20)

  ttfQuit()
  renderer.destroy()
  window.destroy()
  sdl2.quit()

setup()

when isMainModule:
  for i in 0..80:
    putPixel 80, 80+i, Yellow

  drawtext 80, 80, "Hello World", 35, Gold

addQuitProc(proc () {.noconv.} = waitLoop())

