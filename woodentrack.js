// A javascript library for constructing toy wooden train track designs in SVG
// a track object consists of multiple track sections
// a track section is a continuous section of track elements
// there are different types of track element: (S)traight, (R)ight, (L)eft  
// works with d3 v2 (see www.d3js.org)
// TODO: calculate the dimensions of a track / section
// TODO: allow element lengths to be scaled, e.g. half, two thirds, double

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
          .attr("fill","none")
          .attr("stroke", "grey")
          .attr("stroke-width",2);
    for(i=0;i<this.pieces.length;i++){
      element=this.pieces[i].draw(element);         
    } 
  }
}    

// track pieces

function Straight() {
}

Straight.prototype.draw = function(svg) {
  svg.append("path").attr("d", "M 0 0 v -"+trackWidth/2+" h " + gridSize + " v " + trackWidth + " h -" + gridSize + " z ");
  return svg.append("g").attr("transform", "translate(" + gridSize + ",0)");
}

function Bend(flip) {
  this.flip = flip; // 1 : "R", -1 : "L"
}

Bend.prototype.draw = function(svg) {
  var path = "M 0 0 v " + (-1*this.flip*trackWidth/2) +
    " a " + outsideRadius() + ", " + outsideRadius() + " 0 " + ((this.flip==1) ? "0,1 " : "0,0 ") + (sin45*outsideRadius()) + ", " + (this.flip*(1-sin45)*outsideRadius()) +
    " l -" + (sin45*trackWidth) + " " + (this.flip*sin45*trackWidth) +
    " a " + insideRadius() + ", " + insideRadius() + " 0 " + ((this.flip==1) ? "0,0  -" : "0,1 -") + (sin45*insideRadius()) + ", " + (-1*this.flip*(1-sin45)*insideRadius())
    " z";
  svg.append("path").attr("d", path);
  return svg.append("g").attr("transform", "translate(" + (sin45*gridSize) +"," + (this.flip*(1-sin45)*gridSize) +")").append("g").attr("transform","rotate(" + this.flip*45 + ")");
}

function Junction(flip, exit) {
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C"
}

/*
Junction.prototype.draw = function(svg) {
  if (this.side="L") {
    svg.append("path").attr("d", "M 0 0 v "+trackWidth/2+" h " + gridSize + " v -" + trackWidth + " h -" + (gridsize-(Math.sqrt(2*trackWidth*gridSize))) + " a " + outsideRadius() + ", " + outsideRadius() + " 0 0,1 " + ((sin45*gridSize)-(Math.sqrt(2*gridSize*trackWidth)) + ", " + (insideRadius()-(sin45*outsideRadius()))+ " l -" + (sin45*trackWidth) + ", -" + (sin45*trackWidth) + " z ");
  } else if (this.side="R") {
  }
}
*/

function Crossover(flip, exit) {
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C"
}

