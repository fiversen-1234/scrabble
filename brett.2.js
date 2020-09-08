//
//

function Brett() {
}

Brett.prototype.brettfeldwert = function(tdobj) {
    let clname = tdobj.className;
 
    if (clname.search("leer") >= 0)
       return "Feld/Wortwert=1";
    else if (clname.search("buch2") >= 0)
       return "Feldwert=2";
    else if (clname.search("wort2") >= 0)
       return "Wortwert=2";
    else if (clname.search("buch3") >= 0)
       return "Feldwert=3";
    else
       return "Wortwert=1";
 }
 
 Brett.prototype.get_buchstabeBrett = function(x, y)
 {
    //table field
    let fnameI = "_brett_" + x + "_" + y + "_i";
    let fI     = _ctrl(fnameI);
    return fI.name;
 }

 Brett.prototype.set_buchstabeBrett = function(letter, x, y, neu=false)
 {
    //table field
    let fname  = "_brett_" + x + "_" + y + "_";
    let fnameI = "_brett_" + x + "_" + y + "_i";
    let f     = _ctrl(fname);
    let fI    = _ctrl(fnameI);
    dbg.switch(0);
    dbg.print("set_buchstabeBrett:" + fname + ", " + fnameI + ", "+ letter);
    dbg.switch(0);
    fI.src = steinO.svg_inline_img(letter,neu);
    fI.name = letter;
    
    let old = f.className;
    
    if (neu == true) {
       f.title = this.brettfeldwert(f);
    }
    else  {
       f.title = this.brettfeldwert(f);
    }
    return old;
 }
 
 Brett.prototype.setundo_buchstabeBrett = function (x, y, clname)
 {
    let fname  = "_brett_" + x + "_" + y + "_";
    let fnameI = "_brett_" + x + "_" + y + "_i";
    let f     = _ctrl(fname);
    let fI    = _ctrl(fnameI);
 
    //table field
    fI.src = steinO.svg_inline_img(".",false);
    fI.name = ".";
    fI.title = "";
    f.title = "";
    //notd f.className = clname;
 
    //dbg.print("setundo_buchstabeBrett:" + fnameI + "," + fI.name);
 }
 
 var brettO = new Brett();