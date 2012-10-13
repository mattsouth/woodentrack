// A javascript library for constructing toy wooden train track designs in SVG
// a track object consists of multiple track sections
// a track section is a continuous section of track elements
// there are different types of track element: (S)traight, (R)ight, (L)eft  
// works with d3 v2 (see www.d3js.org)
// TODO: calculate the dimensions of a track / section
// TODO: allow all element lengths to be scaled in all dimensions!

// constants
var gridSize=100;
var trackWidth=20;
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

function Track(sections) {
  this.sections = sections;
}

Track.prototype.draw = function(svg) {
  // draw new track
  for (i=0; i<this.sections.length;i++) {
    this.sections[i].draw(svg);
  }
}

function Section() {
  this.pieces=new Array();
}

// TODO: get rid of hard code translation - calculate dimensions or provide attributes
Section.prototype.draw = function(svg) {
  if (this.pieces.length>0) {
    var element = svg.append("g")
          .attr("transform","translate(300,200)")
          .attr("fill","lightgrey")
          .attr("stroke", "white")
          .attr("stroke-width",2);
    for(i=0;i<this.pieces.length;i++){
      element=this.pieces[i].draw(element);         
    } 
  }
}    

// track pieces

function Straight(size) {
  this.size = size; // multiple of gridsize, e.g. 2, 1, 2/3, 1/2, 1/3
}

Straight.prototype.draw = function(svg) {
  // draw track
  svg.append("path").attr("d", "M 0 0 v -" + trackWidth/2 + 
    " h " + this.size*gridSize + 
    " v " + trackWidth + 
    " h -" + this.size*gridSize + " z ");
  // draw rails
  svg.append("path").attr("d", "M 0 -" + trackWidth/4 + 
    " h " + this.size*gridSize + 
    " m 0," + trackWidth/2 + 
    " h -" + this.size*gridSize);
  return svg.append("g").attr("transform", "translate(" + this.size*gridSize + ",0)");
}

function Bend(flip) {
  this.flip = flip; // 1 : "R", -1 : "L"
}

Bend.prototype.draw = function(svg) {
  // draw track
  svg.append("path").attr("d", "M 0 0 v " + (-1*this.flip*trackWidth/2) +
    curvePath(this.flip, 1, (this.flip==1?1:0), gridSize+trackWidth/2, Math.PI/4) +
    " l -" + (sin45*trackWidth) + " " + (this.flip*sin45*trackWidth) +
    curvePath(-1*this.flip, -1, (this.flip==1?0:1), gridSize-trackWidth/2, Math.PI/4) + 
    " z");
  // draw rails
  svg.append("path").attr("d", "M 0 "+ (-1*this.flip*trackWidth/4) +
    curvePath(this.flip, 1, (this.flip==1?1:0), gridSize+trackWidth/4, Math.PI/4) +
    " l -" + (sin45*trackWidth/2) + " " + (this.flip*sin45*trackWidth/2) +
    curvePath(this.flip*-1, -1, (this.flip==1?0:1), gridSize-trackWidth/4, Math.PI/4));
  return svg.append("g").attr("transform", "translate(" + (sin45*gridSize) +"," + (this.flip*(1-sin45)*gridSize) +")").append("g").attr("transform","rotate(" + this.flip*45 + ")");
}

function Junction(flip, exit) {
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C"
}

Junction.prototype.draw = function(svg) {
  // draw track
  svg.append("path").attr("d", "M 0 0 v " + (-1*this.flip*trackWidth/2) +
    " h " + (2/3)*gridSize + 
    " v " + (this.flip*trackWidth) +
    " h -" + ((2/3)*gridSize-(Math.sqrt(2*trackWidth*gridSize))) +
    " a " + outsideRadius() + ", " + outsideRadius() + " 0 " + ((this.flip==1) ? "0,1 " : "0,0 ") + ((sin45*outsideRadius())-(Math.sqrt(2*gridSize*trackWidth))) + ", " + (this.flip*(insideRadius()-(sin45*outsideRadius()))) +
    " l -" + (sin45*trackWidth) + " " + (this.flip*sin45*trackWidth) +
    curvePath(-1*this.flip, -1, (this.flip==1?0:1), gridSize-trackWidth/2, Math.PI/4) + 
    " z");
  // draw rails
  svg.append("path").attr("d", "M 0 -"+trackWidth/4+" h " + 2*gridSize/3 + " m 0," + trackWidth/2 + " h -" + 2*gridSize/3);
  svg.append("path").attr("d", "M 0 "+(-1*this.flip*trackWidth/4)+
    curvePath(this.flip, 1, (this.flip==1?1:0), gridSize+trackWidth/4, Math.PI/4) +
    " l -" + (sin45*trackWidth/2) + " " + (this.flip*sin45*trackWidth/2) +
    curvePath(this.flip*-1, -1, (this.flip==1?0:1), gridSize-trackWidth/4, Math.PI/4)).attr("fill", "none");
  if (this.exit=="C") {
    return svg.append("g").attr("transform", "translate(" + (sin45*gridSize) +"," + (this.flip*(1-sin45)*gridSize) +")").append("g").attr("transform","rotate(" + this.flip*45 + ")");
  } else { // default exit is "B"
    return svg.append("g").attr("transform", "translate(" + (2/3)*gridSize + ",0)");
  }
}

function Crossover(flip, exit) {
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C"
}

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
