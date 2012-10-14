// A javascript library for constructing toy wooden train track designs in SVG
// a track object consists of multiple track sections
// a track section is a continuous section of track elements
// there are different types of track element: (S)traight, (R)ight, (L)eft  
// works with d3 v2 (see www.d3js.org)
// TODO: calculate the dimensions of a track / section
// TODO: allow all element lengths to be scaled in all dimensions!

// constants
var sin45 = Math.sqrt(2)/2; // sin(45deg)

// derived values
function outsideRadius() {
  return gridSize+trackWidth/2;
}

function insideRadius() {
  return gridSize-trackWidth/2;
}

/*
starting position facing along x axis...
side = {1,-1} - 1: bend right, -1: bend left
direction = {1, -1} - 1: forwards, -1: backwards
orbit = {1,0} - 1: clockwise, 0: anti-clockwise
radius = radius of curve (pixels)
angle = angle of curve (radians)
*/
function curvePath(side, direction, orbit, radius, angle) {
  return " a " + radius + ", " + radius + " 0 0, " + orbit + " " + direction*(Math.sin(angle)*radius) + ", " + (side*(1-Math.cos(angle))*radius)
}

// objects
function Transform(translateX, translateY, rotation) {
  this.translateX = translateX;
  this.translateY = translateY;
  this.rotation = rotation;
}

// only use for svg g elements
Transform.prototype.transform = function(svg) {
    if (this.translateX>0 || this.translateY>0) {
      svg.attr("transform", "translate(" + this.translateX + ", " + this.translateY + ")");
      if (this.rotation!=0) {
        svg=svg.append("g").attr("transform", "rotate(" + this.rotation + ")");
      }  
    } else {
      if (this.rotation!=0) {
        svg.attr("transform", "rotate(" + this.rotation + ")");
      }      
    }
    return svg;
}

function Track() {
  this.gridSize = 100;
  this.trackWidth = 20;
  this.trackColor = "lightgrey";
  this.trackGap = 1;
  this.railColor = "white";
  this.railWidth = 2;
  this.railGauge = 10;
  this.sections = new Array();
}

Track.prototype.createSection = function() {
  var result = new Section(this);
  this.sections.push(result);
  return result;
}

Track.prototype.draw = function(svg) {
  // draw new track
  this.sections.forEach( function(section) {
    section.draw(svg);
  });
}

function Section(track) {
  this.track = track;
  this.transform = new Transform(0,0,0);  // position of first piece
  this.pieces = new Array();
}

Section.prototype.draw = function(svg) {
  if (this.pieces.length>0) {
    var element = svg.append("g")
          .attr("fill", "none")
          .attr("stroke", this.track.railColor)
          .attr("stroke-width", this.track.railWidth);
    element=this.transform.transform(element);
    this.pieces.forEach( function(piece) {
      element = piece.draw(element);
    });
  }
}

// track pieces

function Piece(section) {
  this.section = section;
  this.size = 2/3; // for straights: multiple of gridSize, e.g. 2, 1, 2/3, 1/2, 1/3
  this.angle = Math.PI/4; // radians
  this.radius = 1; // for bends: multiple of gridSize
  this.exit='B';
  this.flip=1; // 1 : "R", -1 : "L"
  this.connections = new Object();
  this.connections['A']=new Transform(0,0,0);
}

Piece.prototype.drawConnections = function(element) {
  for (var transform in this.connections) {
    if (this.connections.hasOwnProperty(transform)) {
      element.append("circle").attr("cx", this.connections[transform].translateX).attr("cy", this.connections[transform].translateY).attr("r", 2).attr("stroke-width", 0).attr("fill", "white");
    }
  }
}

Piece.prototype.drawStraightTrack = function(svg) {
  svg.append("path").attr("stroke-width", this.section.track.trackWidth).attr("stroke", this.section.track.trackColor).attr("d", "M 0 0 h " + this.size*this.section.track.gridSize);
}

Piece.prototype.drawStraightRails = function(svg) {
  svg.append("path").attr("d", "M 0 -" + this.section.track.railGauge/2 + " h " + this.size*this.section.track.gridSize + " m 0 " + this.section.track.railGauge + " h -" + this.size*this.section.track.gridSize);
}

Piece.prototype.drawBendTrack = function(svg) {
  svg.append("path").attr("stroke-width", this.section.track.trackWidth).attr("stroke", this.section.track.trackColor).attr("d", "M 0 0 " + curvePath(this.flip, 1, (this.flip==1?1:0), this.section.track.gridSize*this.radius, this.angle));
}

Piece.prototype.drawBendRails = function(svg) {
  svg.append("path").attr("d", "M 0 " + (-1*this.flip*this.section.track.railGauge/2) +
    curvePath(this.flip, 1, (this.flip==1?1:0), this.radius*this.section.track.gridSize+this.section.track.railGauge/2, this.angle) +
    " m -" + (Math.sin(this.angle)*this.section.track.railGauge) + " " + (this.flip*Math.cos(this.angle)*this.section.track.railGauge) +
    curvePath(this.flip*-1, -1, (this.flip==1?0:1), this.radius*this.section.track.gridSize-this.section.track.railGauge/2, this.angle));
}

Piece.prototype.draw = function(svg) {
  this.drawTrack(svg);
  this.drawRails(svg);
  this.drawConnections(svg); // make this optional;
  svg=svg.append("g");
  var transformToExit=this.connections[this.exit];
  svg=transformToExit.transform(svg);
  svg=svg.append("g");
  var gap=new Transform(this.section.track.trackGap,0,0);
  return gap.transform(svg);
}

function Straight(section) {
  Piece.call(this, section);
  this.connections['B'] = new Transform(this.size*this.section.track.gridSize, 0, 0);
}

Straight.prototype = new Piece();

Straight.prototype.drawTrack = function(svg) {
  this.drawStraightTrack(svg);
}

Straight.prototype.drawRails = function(svg) {
  this.drawStraightRails(svg);
}

function Bend(section, flip) {
  Piece.call(this, section);
  this.flip = flip; // 1 : "R", -1 : "L"
  this.connections['B'] = new Transform((Math.sin(this.angle)*this.section.track.gridSize*this.radius), this.flip*(1-Math.cos(this.angle))*this.section.track.gridSize*this.radius, this.flip*this.angle*180/Math.PI);
}

Bend.prototype = new Piece();

Bend.prototype.drawTrack = function(svg) {
  this.drawBendTrack(svg);
}

Bend.prototype.drawRails = function(svg) {
  this.drawBendRails(svg);
}

function Junction(section, flip, exit) {
  Piece.call(this, section);
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C"
  this.connections['B'] = new Transform(this.size*this.section.track.gridSize, 0, 0);
  this.connections['C'] = new Transform((Math.sin(this.angle)*this.section.track.gridSize*this.radius), this.flip*(1-Math.cos(this.angle))*this.section.track.gridSize*this.radius, this.flip*this.angle*180/Math.PI);
}

Junction.prototype = new Piece();

Junction.prototype.drawTrack = function(svg) {
  this.drawStraightTrack(svg);
  this.drawBendTrack(svg);
}

Junction.prototype.drawRails = function(svg) {
  this.drawStraightRails(svg);
  this.drawBendRails(svg);
}

function Crossover(section, flip, exit) {
  Piece.call(this, section);
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C" | "D"
  this.connections['B'] = new Transform((Math.sin(this.angle)*this.section.track.gridSize*this.radius), this.flip*(1-Math.cos(this.angle))*this.section.track.gridSize*this.radius, this.flip*this.angle*180/Math.PI);
  this.connections['C'] = new Transform(2*gridSize*Math.sin(this.angle/2), 2*this.flip*gridSize*(1-Math.cos(this.angle/2), 0);
  // TODO: connection D
}

Crossover.prototype = new Piece();

Crossover.prototype.draw = function(svg) {
  // draw track
  var truncatedWidth = ((gridSize/(Math.cos(Math.PI/8)))-gridSize+(trackWidth/2));
  svg.append("path").attr("d", "M 0 0 v " + this.flip*trackWidth/2 +
    curvePath(this.flip, 1, (this.flip==1?1:0), gridSize-(trackWidth/2), Math.PI/4) +
    " l " + (sin45*truncatedWidth) + " " + (-1*this.flip*sin45*truncatedWidth) +
    " v " + -1*this.flip*truncatedWidth + 
    " a " + (gridSize-(trackWidth/2)) + ", " + (gridSize-(trackWidth/2)) + " 0, " + (this.flip==1?"0 1 ":"0 0 ") + (-1*sin45*(gridSize-(trackWidth/2))) + ", " + (-1*this.flip*(1-sin45)*(gridSize-(trackWidth/2))) +
    " l -" + (sin45*truncatedWidth) + " " + (this.flip*sin45*truncatedWidth) +
    " z");
  // draw rails
  svg.append("path").attr("d", "M 0 " + this.flip*trackWidth/4 +
    curvePath(this.flip, 1, (this.flip==1?1:0), gridSize-(trackWidth/4), Math.PI/4) +
    " l " + (sin45*trackWidth/2) + " " + (-1*this.flip*sin45*trackWidth/2) +
    curvePath(-1*this.flip, -1, (this.flip==1?0:1), gridSize+(trackWidth/4), Math.PI/4) + " z");
  svg.append("path").attr("d", "M " + sin45*(truncatedWidth-3*trackWidth/4) + " " + -1*this.flip*((truncatedWidth-trackWidth/2)+(sin45*(truncatedWidth-3*trackWidth/4))) +
    " a " + (gridSize+(trackWidth/4)) + ", " + (gridSize+(trackWidth/4)) + " 0, " + (this.flip==1?"0 0 ":"0 1 ") + (sin45*(gridSize+(trackWidth/4))) + ", " + (this.flip*(1-sin45)*(gridSize+(trackWidth/4))) +
    " v " + -1*this.flip*trackWidth/2 +
    " a " + (gridSize-(trackWidth/4)) + ", " + (gridSize-(trackWidth/4)) + " 0, " + (this.flip==1?"0 1 ":"0 0") + (-1*sin45*(gridSize-(trackWidth/4))) + ", " + (-1*this.flip*(1-sin45)*(gridSize-(trackWidth/4))) + " z").attr("fill", "none");
  if (this.exit=="C") {
    var x = gridSize*Math.sin(Math.PI/8);
    var y = gridSize*Math.cos(Math.PI/8);
    return svg.append("g").attr("transform", "translate(" + 2*x + "," + this.flip*2*(gridSize-y) + ")");
  } else { // default exit is "B"
    return svg.append("g").attr("transform", "translate(" + (sin45*gridSize) +"," + (this.flip*(1-sin45)*gridSize) +")").append("g").attr("transform","rotate(" + this.flip*45 + ")");
  }
}
