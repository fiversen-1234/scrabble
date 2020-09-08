// base.2.js


function _ctrl (idname) {
    return document.getElementById(idname);
}
 

function _spieler(no) {
    let a = "_spieler" + no  + "_";
    return document.getElementById(a);
}
//function _punkte(no) {
//    var cell = document.getElementById('aktiveSpieler').rows[1].cells; 
//    return cell[no];
//}
function _spielIdCopy() {
    let a = '_spielIdCopy_';
    return document.getElementById(a); 
}
//function _options() {
//    var cell = document.getElementById('aktiveSpieler').rows[1].cells; 
//    return cell[5];
//}


//Debug
function Dbg(lev){
    this.Level = lev;
} 

Dbg.prototype.switch = function (d) 
{
    this.Level = d;
}

Dbg.prototype.print = function (txt)
{
    if (this.Level >= 1) {
       console.log(txt);
       this.printscr(txt);
    }
}
 
//use chat list for debug
Dbg.prototype.printscr =  function (txt)
{
    let olddbg  = _ctrl("_oldchat_").innerHTML; 
    let neudbg = olddbg + "<br/>" + txt;
    _ctrl("_oldchat_").innerHTML = neudbg;
}

var dbg =  new Dbg(0);
