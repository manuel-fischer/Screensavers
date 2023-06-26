from contextlib import contextmanager
import math
import time; PI = math.pi
import cairo
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk
import dataclasses
from dataclasses import dataclass
import random

DRAW_FILL = False
STAR_COUNT = 30
CONTOUR_COUNT = 30#40
CONTOUR_WIDTH = 15#-20
INTERVAL = 1000//30
DECAY = 0.3

def props(obj, *names):
    return [getattr(obj, n) for n in names]
def bind(c, fnname):
    def bind_fn(fn):
        c.connect(fnname, fn)
        return fn
    return bind_fn

def timeout(delta):
    def timeout_fn(fn):
        GLib.timeout_add(delta, fn)
        return fn
    return timeout_fn

@contextmanager
def clip(dc):
    dc.save()
    dc.clip()
    yield
    dc.restore()

win = Gtk.Window()
canvas = Gtk.DrawingArea()
window_is_fullscreen = True
pause = False
def toggle_fullscreen():
    global window_is_fullscreen
    if window_is_fullscreen:
        win.unfullscreen()
    else:
        win.fullscreen()
    window_is_fullscreen = not window_is_fullscreen

win.add(canvas)
win.connect("destroy", Gtk.main_quit)
@bind(win, "key-press-event")
def key_press(win, event):
    keyval = event.keyval
    #keyname = Gdk.keyval_name(event.keyval)
    if keyval in [Gdk.KEY_Escape, Gdk.KEY_q, Gdk.KEY_Q]:
        Gtk.main_quit(event)
    elif keyval == Gdk.KEY_space:
        global pause; pause ^= True
    elif keyval == Gdk.KEY_F11:
        toggle_fullscreen()

@bind(win, "button-press-event")
def dbl_clk(win, event):
    if event.type == getattr(Gdk.EventType, "2BUTTON_PRESS"):
        toggle_fullscreen()

def bit_color(bits):
    r,g,b = (bool(bits&1), bool(bits&2), bool(bits&4))
    return (float(r), float(g), float(b))

def random_color():
    return bit_color(random.randrange(1, 8))

def index_color(i):
    return bit_color((i-1)%7+1)


def f(x):
    return min(x*x*3, 1)

def X():
    return (x/(CONTOUR_WIDTH-1)*2-1 for x in range(CONTOUR_WIDTH))

def color(z):
    z *= 0.3
    #return ((1-z), z, (1-2*z))
    #return ((1-z), z, (1-2*z))[::-1]
    return ((1-z), 0.2, (1-2*z))[::-1]

@dataclass
class Star:
    # Coordinates in range [0, 1)
    x: float
    y: float
    size: float
    seed: float

    @staticmethod
    def random():
        return Star(random.random(), random.random(), random.random(), random.random())

    def draw(self, dc, w, h, ignore_if):
        R = h*self.size*0.003*(2+math.sin((time.time()/3+self.seed)*2*PI))
        x, y = self.x*w, self.y*h/2
        if ignore_if(x, y): return
        dc.arc(x-R, y-R, R, 0, PI/2)
        dc.arc(x-R, y+R, R, -PI/2, 0)
        dc.arc(x+R, y+R, R, -PI, -PI/2)
        dc.arc(x+R, y-R, R, PI/2, PI)
        dc.fill()


@dataclass
class Contour:
    contour: 'list[float]'

    @staticmethod
    def random():
        return Contour([random.random()*f(x)*2-1 for x in X()])

    def draw(self, dc, z0, z1, w, h, next):
        project_x = lambda x, y, z: w*(0.5+0.5*x/z)
        project_y = lambda x, y, z: h*(0.5-0.2*y/z)

        alpha = min(1, 1.25*0.6**z0)

        def draw_fill():
            if next is None: return
            prev_sx0 = prev_sx1 = prev_sy0 = prev_sy1 = None
            for ix, (x, y0, y1) in enumerate(zip(X(), next.contour, self.contour)):
                sx0 = project_x(x, y0, z0)
                sy0 = project_y(x, y0, z0)
                sx1 = project_x(x, y1, z1)
                sy1 = project_y(x, y1, z1)
                if ix:
                    dc.set_source_rgba(0, 0, 0.13-0.15*abs(y0-y1), alpha)
                    dc.move_to(prev_sx0, prev_sy0)
                    dc.line_to(sx0, sy0)
                    dc.line_to(sx1, sy1)
                    dc.line_to(prev_sx1, prev_sy1)
                    dc.fill()

                prev_sx0 = sx0
                prev_sy0 = sy0
                prev_sx1 = sx1
                prev_sy1 = sy1


        def draw_x_grid():
            for ix, (x, y) in enumerate(zip(X(), self.contour)):
                sx = project_x(x, y, z1)
                sy = project_y(x, y, z1)
                (dc.move_to, dc.line_to)[ix!=0](sx, sy)
            dc.stroke()

        def draw_z_grid():
            if next is None: return
            for ix, (x, y0, y1) in enumerate(zip(X(), next.contour, self.contour)):
                sx0 = project_x(x, y0, z0)
                sy0 = project_y(x, y0, z0)
                sx1 = project_x(x, y1, z1)
                sy1 = project_y(x, y1, z1)
                dc.move_to(sx0, sy0)
                dc.line_to(sx1, sy1)
                dc.stroke()
        if DRAW_FILL:
            draw_fill()
        dc.set_source_rgb(*color(z0))
        dc.set_line_width(h/100*DECAY**z1)
        draw_z_grid()
        dc.set_line_width(h/100*DECAY**z0)
        draw_x_grid()

@dataclass
class Landscape:
    contours: 'list[Contour]'
    stars: 'list[Star]'
    dz: float
    dd: float

    @staticmethod
    def random(w, h):
        contours = [Contour.random() for _ in range(CONTOUR_COUNT)]
        stars = [Star.random() for _ in range(STAR_COUNT)]
        return Landscape(contours, stars, 0, 0)

    def update(self, w, h):
        self.dz -= 2/CONTOUR_COUNT
        self.dd += 0.05; self.dd %= 1
        if self.dz < 0:
            self.dz += 1
            del self.contours[0]
            self.contours.append(Contour.random())

    def draw_sun_old(self, dc, w, h):
        R = int(h*0.1+1)
        K = 4
        C = R*K
        MOD = C//10
        cx = w*0.5
        cy = h*0.5

        dc.set_line_width(1)
        for i in range(0, C):
            if (i+MOD*self.dd) % MOD > (i)//10: continue

            yy = i/C
            xx = (1-yy*yy)**0.5
            dc.set_source_rgb(1, yy*0.8, yy*yy*0.2)

            dc.rectangle(cx-xx*R, cy-yy*R, 2*xx*R, (K-(i%K))/K)
            dc.fill()

    def sun_radius(self, w, h):
        return int(h*0.1+1)

    def draw_sun(self, dc, w, h):
        R = self.sun_radius(w, h)
        N = 10
        MOD = R//N
        cx = w*0.5
        cy = h*0.5

        dc.set_source_rgb(1,1,1)
        dc.arc(cx, cy, R, PI, 0)
        with clip(dc):
            for i in range(1, N+2):
                yy = (i-self.dd)/N
                dc.set_source_rgb(1, yy*0.8, yy*yy*0.2)
                dc.rectangle(cx-R, cy-yy*R, 2*R, yy*MOD)
                dc.fill()

    def draw_stars(self, dc, w, h):
        R2 = self.sun_radius(w, h)**2
        cx, cy = w/2, h/2
        for s in self.stars:
            dc.set_source_rgb(0.3+0.5*s.y, 0.8-0.2*s.y, 1.0-0.5*s.y)
            s.draw(dc, w, h, lambda x, y: (x-cx)**2+(y-cy)**2<R2)

    def draw_horizon(self, dc, w, h):
        dc.rectangle(0, h*0.5, w, h*0.5)
        #dc.set_source_rgb(0.05, 0, 0.1)
        dc.set_source_rgb(0.075, 0, 0.12)
        dc.fill()
        C = 20
        for i in range(C):
            y0 = i / C
            y1 = (i+1) / C
            #dc.set_source_rgb(0.05+y1*0.1, y1*0.05, 0.1)
            dc.set_source_rgb(0.1+y1*0.2, y1*0.1, 0.1+y1*0.1)
            sy0 = h*(y0*0.5)
            sy1 = h*(y1*0.5)
            dc.rectangle(0, sy0, w, sy1-sy0+1)
            dc.fill()

    def draw_landscape(self, dc, w, h):
        prv = None
        for iz, c in reversed(list(enumerate(self.contours))):
            z0 = (iz + self.dz+1) / CONTOUR_WIDTH * 2
            z1 = (iz + self.dz+2) / CONTOUR_WIDTH * 2
            if prv is not None:
                prv.draw(dc, z0, z1, w, h, c)
            prv = c

    def draw(self, dc, w, h):
        self.draw_horizon(dc, w, h)
        self.draw_sun(dc, w, h)
        self.draw_stars(dc, w, h)
        self.draw_landscape(dc, w, h)


w, h = 100, 100
def update_size():
    global w, h
    w, h = props(canvas.get_allocation(), "width", "height")
    w = max(w, 100)
    h = max(h, 100)
update_size()


state = Landscape.random(w, h)

dc = None

@timeout(INTERVAL)
def updateredraw():
    if not pause:
        update_size()
        state.update(w, h)
        canvas.queue_draw()
    return True


@bind(canvas, "draw")
def canvas_draw(self, dc : cairo.Context):
    update_size()
    state.draw(dc, w, h)

win.show_all()
win.fullscreen()
Gtk.main()
