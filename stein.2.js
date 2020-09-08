//stein.2.js

'use strict';

/////////////////////////////////////////////////////////// Stein
function Stein()
{
}

Stein.prototype.buchstabe_wert  = function (bst)
{
   if ("ENSIRTUAD".search(bst) != -1)
      return 1;
   if ("HGLO".search(bst) != -1)
      return 2;
   if ("MBWZ".search(bst) != -1)
      return 3;
   if ("CFKP".search(bst) != -1)
      return 4;
   if ("ÄJÜV".search(bst) != -1)
      return 6;
   if ("ÖX".search(bst) != -1)
      return 8;
   if ("QY".search(bst) != -1)
      return 10;
   //if (bst == "?")
      return 0;   
}

Stein.prototype.svg_inline_img = function(buch, mark=0)
{
	var buchwert  = this.buchstabe_wert(buch);
   var textcolor = "'black'";
   var textfont  = "'Arial, Helvetica, sans-serif'";

   //buchwert
   var xwert     = "'80'";
   var ywert     = "'90'";
   var fontsize  = "'30px'";

   if (buchwert > 9) {
      xwert = "'68'";
      ywert = "'94'";
      fontsize  = "'26px'";
   }

   if (mark)
      textcolor = "'red'";

	var ret = "data:image/svg+xml;utf8,<svg width='100' height='100' viewBox='0 0 100 100' " +
	    		"xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>" ;
	if (buch == '.') {
		ret += "<polygon points='0,0 100,0 100,100 0,100' style='fill:transparent' /> " +
			    "<text x='45' y='55' fill='black' font-size='80px' >.</text>";
	}
	else  {
      //font-family='monospace'
		ret += "<polygon points='0,0 100,0 100,100 0,100' style='fill:beige;stroke:brown;stroke-width:3' />" +
			"<text x='20'          y='75'          fill=" + textcolor +  " font-size='80px'           font-family=" + textfont + ">" + buch + "</text>"  +
			"<text x=" + xwert + " y=" + ywert + " fill=" + textcolor +  " font-size=" + fontsize + " font-family=" + textfont + ">" + buchwert + "</text>";
	}
	ret += "</svg>";
	return ret;
}

var steinO = new Stein();
