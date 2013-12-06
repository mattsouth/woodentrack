Woodentrack is a coffeescript library for designing and testing toy train track layouts.

It has as few dependencies, as shown in package.json.  run "npm install" to set them up.

## Notes

To use demos, try "python -m SimpleHTTPServer 8000".

The goals of this branch are to
 1. create a model that's independent of the painting toolkit (e.g. d3 or raphael)
 2. decent test coverage
 3. try out coffeescript
 4. all the goals of the master project

Potential demos
 1. simple page with empty canvas.  open console.  start building track.
 2. random track builder
 3. take existing track and click button to morph track into another layout with the same pieces and the same number of loose ends

### TODO:
 - use address i.e. "{section_index}.{piece_index}.{connection}" for connection, not pointer
 - get something painting
 - more piece types
 - remove need to pass section into piece constructor (lazy piece access to track.gridSize?)
 - focus more on Track API - track.add adds piece to top section?
