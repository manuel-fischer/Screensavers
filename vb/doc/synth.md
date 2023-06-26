# SYNTH

SYNTH — A synthwave themed screensaver written in Visual Basic

![](../images/synth.png)

## Source code

The main code for this screensaver can be found in [`SYNTH.BAS`](../src/SYNTH.BAS)

The project also consists of the following files: 

- Common screensaver functionality
  - Source code
    - Main Window (Form) — [`SCRSV.FRM`](../src/SCRSV.FRM)
    - Constants — [`SCRSV.BAS`](../src/SCRSV.BAS)
  - Binary files: blank icon/cursor
    - Blank icon — [`BLANK.ICO`](../src/BLANK.ICO)
    - Blank icon (embedded) — [`SCRSV.FRX`](../src/SCRSV.FRX)
- Screensaver specific
  - Project File — [`SYNTH.VBP`](../src/SYNTH.VBP)
  - **Drawing Code — [`SYNTH.BAS`](../src/SYNTH.BAS)**

## Usage

- `[Space]` — Toggle pause
- `[T]` — Toggle clock
- `[F5]` — Redraw whole screen

## Developement

This screensaver was developed after [the implementation in python, which used GTK](../../pygtk/doc/synthwave.md). I challenged my self to implement a similar screensaver for Windows 3.1 in Visual Basic 4. Technically this implementation is a little different to the Python implementation. It uses some tricks to deal with the performance and limitations of the old hardware and software.


## Environment

- 16-Bit Windows 3.1
- Visual Basic 4
- Tested and developed in DosBox and VirtualBox

$\implies$ No 3D hardware acceleration  
$\implies$ Small color palette (4 bit, 16 colors)

## Goals

- Rendering 3D perspective
- OK performance
- Color gradients
- Clock

## Tricks used in the implementation

- Simplification
  - Grid is now flat, instead of a mountainous grid

- Clock text rendering
  - Cache old rendered text
  - Redraw background of changing characters
  - Draw text on top of old text

- Gradients
  - Linear interpolation of colors
  - Dithering
    - Problem
      - Border with solid color is drawn
    - Solution
      - Render black rectangle
      - Enable xor-draw mode
      - Render filled rectangle expanded by 1 pixel
      - Render non-filled rectangle expanded by 1 pixel
      - The border is canceled out by the xor-operation
      - The actual rectangle is colored correctly by the overlay on top of the black color


- 3D perspective
  - Unproject $y$ coordinate to $z$ coordinate
    - Divide constant by $y$
  - Project $x$ coordinate
    - Multiply $x$ by $y$ and constant
  - Draw pixel row/scans
    - Regular repeating pattern per row
    - Shift initial position of pattern to create curve
  - Depth
    - exponential decay of luminance

- 3D movement
  - The moving lines are parallel to the $x$-axis  
    $\implies$ Color only needs to be computed for each row of pixels
  - Store color of each pixel row of the ground in an array
    - Use language feature of a custom lower bound other than 0 or 1
  - Only update rows if the new computed color changes


- Mip-"Mapping"/LOD
  - Why?
    - <u>Performance:</u> For further distant rows, the `For` loop drawing the repeating pattern would loop much more often, because the grid cells are more smaller
    - <u>Flickering lines</u> ocurr if the lines are much thinner than a pixel. This would also mean that those pixel rows need to be updated much more often.
  - How?
    - Use mipped color mixed between grid line color and grid cell color
    - For the region near the horizon, simply render mipped color
    - For a region approximately in the center of the ground region
      - Interpolate grid line width, to be more "thicker" (in world space) further away
      - Interpolate colors with the mipped color


- Drawing sun
  - Draw sun by pixel rows
  - Gradient from yellow to orange
  - Semicircle
  - Iterate along $y$-coordinates in range $[-R, 0]$
  - Use the following formular to compute the left and right boundary of the pixel row, relative to the center $y$-axis:  
    $$\Delta x = \sqrt{R^2 - y^2}$$