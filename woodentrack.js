// A javascript library for constructing toy wooden train track designs in SVG
// a track object consists of multiple track sections
// a track section is a continuous section of track elements
// there are different types of track element: (S)traight, (R)ight, (L)eft  
// works with d3 v2 (see www.d3js.org)
// TODO: calculate the dimensions of a track / section

var gridSize=100;
var trackWidth=20;
var sin45 = Math.sqrt(2)/2; // sin(45deg)

function Straight() {
}

Straight.prototype.draw = function(svg) {
  svg.append("path").attr("d", "M 0 0 v -"+trackWidth/2+" h " + gridSize + " v " + trackWidth + " h -" + gridSize + " z ");
  return svg.append("g").attr("transform", "translate(" + gridSize + ",0)");
}

function Right() {}

Right.prototype.draw = function(svg) {
  svg.append("path").attr("d", "M 0 0 v -" + trackWidth/2 + " a " + outsideRadius() + ", " + outsideRadius() + " 0 0,1 " + (sin45*outsideRadius()) + ", " + ((1-sin45)*outsideRadius()) + " l -" + (sin45*trackWidth) + " " + (sin45*trackWidth) + " a " + insideRadius() + ", " + insideRadius() + " 0 0,0 -" + (sin45*insideRadius()) + ", -" + ((1-sin45)*insideRadius()) + " z");
  return svg.append("g").attr("transform", "translate(" + (sin45*gridSize) +"," + ((1-sin45)*gridSize) +")").append("g").attr("transform","rotate(45)");
}

function Left() {}

Left.prototype.draw = function(svg) {
  svg.append("path").attr("d", "M 0 0 v -" + trackWidth/2 + " a " + insideRadius() + ", " + insideRadius() + " 0 0,0 " + (sin45*insideRadius()) + ", -" + ((1-sin45)*insideRadius()) + " l " + (sin45*trackWidth) + " " + (sin45*trackWidth) + " a " + outsideRadius() + ", " + outsideRadius() + " 0 0,1 -" + (sin45*outsideRadius()) + ", " + ((1-sin45)*outsideRadius()) + " z");
  return svg.append("g").attr("transform", "translate(" + (sin45*gridSize) +",-" + ((1-sin45)*gridSize) +")").append("g").attr("transform","rotate(-45)");
}

function Section() {
  this.pieces=new Array();
}

// TODO: get rid of hard code translation - calculate dimensions or provide setters
Section.prototype.draw = function() {
  if (this.pieces.length>0) {
    var svg = d3.select("svg").append("g")
          .attr("transform","translate(300,200)")
          .attr("fill","none")
          .attr("stroke", "grey")
          .attr("stroke-width",2);
    for(i=0;i<this.pieces.length;i++){
      svg=this.pieces[i].draw(svg);         
    } 
  }
}    

function outsideRadius() {
  return gridSize+trackWidth/2;
}

function insideRadius() {
  return gridSize-trackWidth/2;
}
