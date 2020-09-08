//spiel3.js

'use strict';


/////////////////////////////////////////////////////////// Globale
// allg. funcs in  base.2.js
// var  dbg    = new Dbg();
// var  steinO = new Stein();
// var  bankO  = new Bank();
// var  brettO = new Brett();
// var  dlgO   = new Dlg();
// var  zugControlO = new ZugControl();

const BASEURL    = "/scrab";

function Spiel ()
{
   this.Spieler               = "";
   this.SpielId               = "";
   this.MitSpielerAdr         = new Array(3);
   //this.Angemeldet = 0;
   this.Steingesetzt          = 0;
   this.AktionsNr             = 0;
   this.WortZeilenNr          = 0;
   //this.ZugZeilenNr  = 0;
   this.VetoOption            = false;
   this.VetoWarteLoops        = 0;
   this.VetoWarteLoopsLIMIT   = 3;   
}
var spiel = new Spiel();


const MarkBgColor = "red";

// zustand von scrab
var Zustd = {
   not_def:    -1,   // -1 nicht vorhanden
   vor_anmeldung: 0, //  0 vor anmeldung
   angemeldet: 1,    //  1 angemeldet
   spielId_ok: 2,    //  2 spielId kontrolliert
   spiel_fertig: 3,  //  3 fertig zum spielstart
   spielen:  4,      //  4 im spiel modus
   laden_warten: 5,  //  5 nach loadall - warten bis alle spieler geladen haben
};
var zustand = Zustd.vor_anmeldung;

//-beim versetzen von steinen
function Actual ()
{
   this.Aktiv     = -1;
   this.SelectBst = "";
   this.SelBankFld = "";
   this.SelBrettBgColor= "";
   this.TauscheAktiv = 0;
   this.BeimLegen  = 0;
   this.SchreibeZugAktiv=0;
   this.DlgType = "";
}
var act = new Actual();


//-zustandsvariablen f�r die zustandsloop
function Lastzustand ()
{
   this.AktiveSpieler = "";
   this.Legen = "";
   this.LeseZug = "-";
}
var lastzustand = new Lastzustand();

//-Texte
const txtHelloEinladend = "<h3>Spielstart</h3>" +
      "<p>Du hast die WebSeite von 'scrab' aufgerufen,<br/>" +
      "tr&auml;gt bei '<b>Selbst</b>' Deinen Namen ein und<br/>" +
      "l&auml;dt bis zu 3 '<b>Mitspieler</b>' per Email ein." +
      "</p>" +
	  "<p>Mit <b>[Einladen]</b> werden die Emails versendet.<br/>"  +
	  "Die Mitspieler klicken auf den Link in der Email und k&ouml;nnen so mitspielen." +
      "</p>" +
      "<p>In der Zeile '<b>AKTIV</b>' werden alle angemeldeten Spieler und deren Punktestand angezeigt.<br/>" +
      "Sind alle Spieler angemeldet, kann einer das Spiel starten, <b>[Starte]</b>."  +
      "</p>"  +
	  "<p>Nur der aktive Spieler, Name in <span style='color:red;'><b>'rot'</b></span>, kann Buchstaben setzen." +
      "</p>" +
      "<h3>Spielen</h3>" +
      "<p>Um einen Buchstaben ins Brett zu setzen, klickt man erst auf den Buchstaben in der Bank, " + 
      "der wird markiert, und dann auf das Feld im Brett.<br/>" +
      "Hat man alle Buchstaben gesetzt, wird mit <b>[Fertig]</b> der Zug abgeschlossen " +
      "und der N&auml;chste ist dran.<br/> " +
      "Weitere und genauere Information gibt es im Tab-Reiter <b>'Info-Hilfe'" +
      "</p>";

const txtHelloEingeladen = "<h3>Spielstart</h3>" +
      "<p>Du bist per Email zum Spielen eingeladen und hast die Webseite per<br/>" +
      "Link in der Email gestartet.<br/>" +
      "Trage Deinen Namen in '<b>Selbst</b>' ein und melde Dich an, <b>[Anmelden]</b>." +
      "</p>" +
      "<p>In der Zeile '<b>AKTIV</b>' werden alle angemeldeten Spieler und deren Punktestand angezeigt.<br/>" +
      "Sind alle Spieler angemeldet, kann einer das Spiel starten, <b>[Starte]</b>."  +
      "</p>"  +
	   "<p>Nur der aktive Spieler, Name in <span style='color:red;'><b>'rot'</b></span>, kann Buchstaben setzen." +
      "</p>" +
      "<h3>Spielen</h3>" +
      "<p>Um einen Buchstaben ins Brett zu setzen, klickt man erst auf den Buchstaben in der Bank, " + 
      "der wird markiert, und dann auf das Feld im Brett.<br/>" +
      "Hat man alle Buchstaben gesetzt, wird mit <b>[Fertig]</b> der Zug abgeschlossen " +
      "und der N&auml;chste ist dran.<br/> " +
      "Weitere und genauere Information gibt es im Tab-Reiter <b>'Info-Hilfe'" +
      "</p>";

const txtLadenDlg = "Ein <b>'Gespeichertes Spiel'</b> markieren,<br/>" +
      "den <b>'Spieler'</b> eintragen und <br/>" + 
      "hier das <b>Passwort</b> der Speicherung.";
           
const txtSpeichernDlg = "Passwort zur Speicherung (mind. 4 Buchstaben).";

//-fuer die Zuege
/*const MaxZug = 50;
var Zug = new Array(MaxZug);
var ZugI=0;
for (ZugI=0; ZugI < MaxZug; ZugI++) {
   Zug[ZugI] = new Array(4);
}
ZugI = 0;
*/
var Zug = new Object();
Zug.MaxZug = 50;
Zug.arr = new Array(Zug.MaxZug);
Zug.idx = 0;
for (Zug.idx=0; Zug.idx < Zug.MaxZug; Zug.idx++) {
   Zug.arr[Zug.idx] = new Array(4);
}
Zug.idx = 0;


/////////////////////////////////////////////////////////// Dialog, KontrolFelder

//////////////////////// tab
function SetTab (id, aktivId)
{
   let butid = "but_" + id;
   let divid = "div_" + id; 
   let but    = _ctrl(butid);
   let div    = _ctrl(divid);
   if (id == aktivId) {
      but.className  = 'marktab';
      div.style.visibility  = 'visible';
   }
   else {
      but.className  = 'normtab';
      div.style.visibility  = 'hidden';
   }
}
function ShowDiv(id) 
{
   dbg.switch(0);
   dbg.print("ShowDiv:" + id);
   SetTab("dat", id);
   SetTab("chat", id);
   SetTab("info", id);
   SetTab("login", id);
}




// Controls
// [login]
//    _spielIdL_ _spielId_     _AktivL_  
//    _spielerL_ _spieler_
//    _anmelden_   _starte_
//
// [brett]                             [brettdlg]
//    _brett_row_col_  .1..15.            _aktzug_
//    .1..15.                             _zuege_
//                                        _worte_
//
// [bank]                  [funktionbar]
//    _bank_0_ .._6_          _starte_  _undo_  _tausche_  _fertig_





// event-functionen zuordnen
var handled = 0;
function mitspielerNfunc()  {
   handled = 1;
}
function mitspieler() {
   if (handled == 1)  {
      handled = 0;
   }
   else {
      this.parentElement.querySelector(".mitspielerNested").classList.toggle("mitspielerActive");
      this.classList.toggle("mitspielerOpen_sign");
   }
}

function setfuncs() {
   let b = _ctrl('_anmelden_');
   b.addEventListener('click', myAnmeldeFunc);
   b = _ctrl('_starte_');
   b.addEventListener('click', myStarteFunc);
   b = _ctrl('_multi_');
   b.addEventListener('click', myMultiFunc);


   let toggler = document.getElementsByClassName("mitspielerClose_sign");   
   for (var i = 0; i < toggler.length; i++) {
      //toggler[i].addEventListener("click", function() {
      //   this.parentElement.querySelector(".mitspielerNested").classList.toggle("mitspielerActive");
      //   this.classList.toggle("mitspielerOpen_sign");
      //});
      toggler[i].addEventListener("click", mitspieler);
   }
   let a = document.getElementById('_mitspielerAdr1_');
   if (a)  {
        a.addEventListener("click", mitspielerNfunc);
        a = document.getElementById('_mitspielerAdr2_');
        a.addEventListener("click", mitspielerNfunc);
        a = document.getElementById('_mitspielerAdr3_');
        a.addEventListener("click", mitspielerNfunc);
    }
}

//sicherheitsabfrage bei vorzeitigem verlassen
window.onbeforeunload = function(event) {
   event.returnValue = "so long - scrab never dies";
};
 
//window.addEventListener('beforeunload', function (e) {
//   dbg.switch(1);
//   dbg.print("beforeunload");
//   e.preventDefault(); 
//   e.returnValue = '1';
//});

// aufraeumen auf dem server
//window.pagehide = function (e) {
//   ajEnd();
//};

function deldata() {
   ajEnd();
}
window.addEventListener('pagehide', deldata);

//window.unload = function(e) {
//   ajEnd();
//};
window.addEventListener('unload', deldata);


// start der page
window.onload = function () {
    setfuncs();
    setdlgfuncs();
    console.log('Dokument geladen');
    statusO.status_anmeldedlg (true);  
    statusO.status_brettdlg (false);
    statusO.status_funktionbar(false,false,false,false);
    let val  = _ctrl("_spielIdCopy_").innerHTML;
    if (val == "-")
        dlgO.ShowDlg(txtHelloEinladend, "scrab - multiuser - online","big");
    if (val == "+")
        dlgO.ShowDlg(txtHelloEingeladen, "scrab - multiuser - online","big");
   ajMulti("holestored",0,0,"");
}


/////////////////////////////////////////////////////////// Button-Funktionen
//-fkt durch clicks auf -brett  -bank 
function myBankFunc(x)
{
   dbg.switch(1);
   dbg.print(`myBankFunc: ${x}`);
   dbg.switch(0);

   if (act.TauscheAktiv == 1) 
      myBankFuncTausche(x);
   else 
      myBankFuncSetze(x);
}
function myBankFuncSetze(x)
{
   dbg.switch(0);
   dbg.print(`myBankFuncSetze:${x},${act.SelBankFld}`);
   dbg.switch(0);

   //ordnen der Bank
   if (act.SelBankFld != "")
   {
      dbg.print("-:" + act.SelBankFld);
      let fname    = `_bank_${x}_`;
      let fnameI   = `_bank_${x}_i`;   
      let neuBuch  =  _ctrl(fnameI).name;
      let neuX     = x;

      let altBuch  = _ctrl(act.SelBankFld+'i').name;
      let altX     = act.SelBankFld.substr(6,1);

      bankO.set_bankbuchstabe(altBuch,neuX);
      bankO.set_bankbuchstabe(neuBuch,altX);
      _ctrl(act.SelBankFld).style.backgroundColor = act.SelBrettBgColor;
      act.SelBankFld = "";
      //SelBankBgColor = "";
      act.SelectBst = "";

      dbg.print(`--:${act.SelBankFld},${act.SelectBst}`);
   }   
   else  
   {
      let fname    = `_bank_${x}_`;
      let fnameI   = `_bank_${x}_i`;   
      act.SelBankFld = fname;
      let f  = _ctrl(fname);
      let fI = _ctrl(fnameI);
      act.SelectBst = fI.name;
      if (act.SelectBst == "") 
         return;

      act.SelBrettBgColor= f.style.backgroundColor;
      f.style.backgroundColor=MarkBgColor;

      bankO.set_bankbuchstabe(act.SelectBst, x, 1);

      statusO.set_cursor("crosshair");
      statusO.status_funktionbar(false,(Zug.idx>0),(Zug.idx==0),true);
   }
}
function myBankFuncTausche(x)
{
   if (act.Aktiv != 1)
      return;

   //_ctrl("tab1").style.cursor = "crosshair";

   let fname    = `_bank_${x}_`;
   let fnameI   = `_bank_${x}_i`;   
   let f  = _ctrl(fname);
   let fI = _ctrl(fnameI);

   let bst = fI.name;
   if (bst == "") 
        return;

   //schon selektiert - dann deselektieren
   if (f && f.style.backgroundColor == MarkBgColor) {
      f.style.backgroundColor = act.SelBrettBgColor;
   }
   //neu selektieren
   else {
      act.SelBrettBgColor= f.style.backgroundColor;
      f.style.backgroundColor=MarkBgColor;
   }
   statusO.status_funktionbar(false,false,false,true);
}


function myBrettFunc(x,y)
{
   dbg.switch(0);
   dbg.print(`myBrettFunc:${x},${y}; ${act.Aktiv},${act.SelectBst};`  +
               brettO.get_buchstabeBrett(x,y) + ";");
   dbg.switch(0);

   if (act.Aktiv != 1)
      return;

   if (act.TauscheAktiv == 1)
      return;

   if (act.SelectBst == "") 
      return;

   if (act.BeimLegen == 1)
      return;

   //brett field
   let old =  brettO.get_buchstabeBrett(x,y);
   if (old !=  ".")
      return;
   let oldClassName =  brettO.set_buchstabeBrett(act.SelectBst, x, y, true);

   //bank field
   let f = 0;
   let fI = 0;
   if (act.SelBankFld != "")  {
      f  = _ctrl(act.SelBankFld);
      fI = _ctrl(act.SelBankFld+'i');
   }
   if (f && fI) {
      f.style.backgroundColor = act.SelBrettBgColor;
      f.className = "leerebank";
      let bi = act.SelBankFld.substr(6,1);
      //alert("myBrettFunc bank: " + bi);
      bankO.set_bankbuchstabe(".", bi);
   }

   //aktZug
   if (Zug.idx > Zug.MaxZug)
      alert ("zu viele Zuege");
   let aktZug = _ctrl("_aktzug_").innerHTML;
   aktZug = aktZug + `(${act.SelectBst} ${x},${y})`; 
   _ctrl("_aktzug_").innerHTML = aktZug;
   Zug.arr[Zug.idx][0] = x;
   Zug.arr[Zug.idx][1] = y;
   Zug.arr[Zug.idx][2] = act.SelectBst;
   Zug.arr[Zug.idx][3] = oldClassName;
   Zug.idx++;

   spiel.Steingesetzt = 1;

   statusO.set_cursor("pointer");

   //buchstaben legen -> an andere
   ajLegeBuchstabe(x,y,act.SelectBst);
  
    //keine act.SelectBst 
    act.SelectBst = "";
    act.SelBankFld = "";

    statusO.status_funktionbar(false,(Zug.idx>0),(Zug.idx==0),true);
}



//-fkt ausgel�st durch die 'button'-ctrls
function myAnmeldeFunc() 
{
   if (zustand != Zustd.vor_anmeldung)
      return;

   if (_ctrl("_mitspielerAdr1_")) {
      myAnmeldeFunc_loginII();
   }
   else  {
      myAnmeldeFunc_login();
   }
}
  
function myAnmeldeFunc_login() 
{
   if (zustand != Zustd.vor_anmeldung)
      return;

   //let butcl = _ctrl("_anmelden_").className;
   //if (butcl == "likebutdis") 
   //   return;

   spiel.SpielId = _ctrl("_spielId_").value;
   spiel.Spieler = _ctrl("_spieler_").value;
   let vielepkte = (_ctrl("_vielePkte_").checked) ? '1' : '0';
   let softend   = (_ctrl("_softEnd_").checked) ? '1' : '0';
   let mitveto   = (_ctrl("_mitveto_").checked) ? '1' : '0';

   dbg.switch(1);
   dbg.print(`myAnmeldeFunc_login:${vielepkte},${softend},${mitveto};`);
   dbg.switch(0);


   //kontrolle der eingaben
   let meldung = "I";
   let a = (spiel.SpielId.length <  2);
   let b = spiel.SpielId.search(/^[a-zA-Z0-9]+$/) == -1;
   let c = (spiel.Spieler.length < 2);     
   let d = spiel.Spieler.search(/^[a-zA-Z0-9]+$/) == -1;
   if (a || b) {
      if (a)
         meldung += "SpielId: >" + spiel.SpielId + "< \n" +
                    "- jeweils mindestens 2 Ziffern.";
      if (b)
         if (!a) 
            meldung +=  "SpielId: >" + spiel.SpielId + "< \n" +
                        "- nur Buchstaben+Zahlen \n" +
                        "- keine Sonderzeichen und Umlaute.";
         else            
            meldung +=  "\n- nur Buchstaben+Zahlen \n" +
                        "- keine Sonderzeichen und Umlaute.";
   }
   if (c || d) {
      if (c)
         meldung +=  "\nSpieler: >" + spiel.Spieler + "< \n" +
                     "- jeweils mindestens 2 Ziffern.";
      if (d)
         if (!c) 
            meldung +=  "\nSpieler: >" + spiel.Spieler + "< \n" +
                        "- nur Buchstaben+Zahlen \n" +
                        "- keine Sonderzeichen und Umlaute.";
         else            
            meldung +=  "\n- nur Buchstaben+Zahlen \n" +
                        "- keine Sonderzeichen und Umlaute.";
   }
   dbg.switch(0);
   if (meldung.length > 2) {
      alert (meldung);
      return;
   }

   statusO.status_anmeldedlg (false);  

   //_ctrl("_aktzug_").innerHTML = "neu";
   ajAnmeldeFunc(spiel.SpielId, spiel.Spieler, vielepkte, softend, mitveto);

   //_ctrl("dlg").close();
}

function myAnmeldeFunc_loginII() 
{
   spiel.SpielId       = Math.floor(Math.random() * 1000); 
   spiel.Spieler       = _ctrl("_spieler_").value;

   let adr = _ctrl("_mitspielerAdr1_").value;
   if (adr.length > 0)  {
      adr = adr.replace(/ /g, "");
      _ctrl("_mitspielerAdr1_").value = adr;
   }
   spiel.MitSpielerAdr[0] = adr;

   adr = _ctrl("_mitspielerAdr2_").value;
   if (adr.length > 0)  {
      adr = adr.replace(/ /g, "");
      _ctrl("_mitspielerAdr2_").value = adr;
   }
   spiel.MitSpielerAdr[1] = adr;

   adr = _ctrl("_mitspielerAdr3_").value;
   if (adr.length > 0)  {
      adr = adr.replace(/ /g, "");
      _ctrl("_mitspielerAdr3_").value = adr;
   }
   spiel.MitSpielerAdr[2] = adr;

   let vielepkte = (_ctrl("_vielePkte_").checked) ? '1' : '0';
   let softend   = (_ctrl("_softEnd_").checked) ? '1' : '0';
   let mitveto   = (_ctrl("_mitveto_").checked) ? '1' : '0';

   dbg.switch(0);
   dbg.print(`myAnmeldeFunc_loginII:${vielepkte},${softend},${mitveto};`);
   dbg.switch(0);


   //kontrolle der eingaben
   let meldung = "II";
   for (let i = 0; i < 3; i = i +1) {
      let len = spiel.MitSpielerAdr[i].length;
      let a   = (spiel.MitSpielerAdr[i].length <  8);
      let b1  = spiel.MitSpielerAdr[i].indexOf('@');
      let b2  = spiel.MitSpielerAdr[i].lastIndexOf('@');
      let b3  = spiel.MitSpielerAdr[i].lastIndexOf('\.');
      dbg.switch(1);
      dbg.print(`myAnmeldeFunc_loginII len:${len} a:${a} b1:${b1} b2:${b2} b3:${b3};`);
      dbg.switch(0);
         let b = 1;
      if (i > 0  && len == 0)  {
         a = 0;
         b = 0;
      }
      else  {     
         if (b1 > -1  &&
            b1 == b2   &&
            b3 > (b2 + 1) &&
            b3 <   spiel.MitSpielerAdr[i].length) {
            b = 0;
         }
      }
      if (a || b) {
         if (a)
            meldung += i + ". MitSpielerAdr: >" + spiel.MitSpielerAdr + "< \n" +
                     "- nicht sinnvoll.";
         if (b)
            if (!a)
               meldung +=  i + ". MitSpielerAdr: >" + spiel.MitSpielerAdr + "< \n" +
                           "- keine EMail Adresse.";
            else
               meldung +=  "- keine EMail Adresse.";
      }
   }
   
   let c = (spiel.Spieler.length < 2);     
   let d = spiel.Spieler.search(/^[a-zA-Z0-9]+$/) == -1;
   if (c || d) {
      if (c)
         meldung +=  "\nSpieler: >" + spiel.Spieler + "< \n" +
                     "- jeweils mindestens 2 Ziffern.";
      if (d)
         if (!c) 
            meldung +=  "\nSpieler: >" + spiel.Spieler + "< \n" +
                        "- nur Buchstaben+Zahlen \n" +
                        "- keine Sonderzeichen und Umlaute.";
         else            
            meldung +=  "\n- nur Buchstaben+Zahlen \n" +
                        "- keine Sonderzeichen und Umlaute.";
   }
   dbg.switch(0);
   if (meldung.length > 2) {
      alert (meldung);
      return;
   }

   statusO.status_anmeldedlg (false);  

   //_ctrl("_aktzug_").innerHTML = "neu";
   ajAnmeldeFunc(spiel.SpielId, spiel.Spieler, 
                  spiel.MitSpielerAdr[0],spiel.MitSpielerAdr[1],spiel.MitSpielerAdr[2], 
                  vielepkte, softend, mitveto);

   //_ctrl("dlg").close();
}



function myStarteFunc() 
{
   if (zustand == Zustd.spielen)
      return;
   //if (Aktiv == 1)
   //   return;
   //alert("myStarteFunc");
   //if (SpielId.lenght > 0  && Spieler.lenght > 0)
      ajStartenFunc(1);
}

function myUndoFunc()
{
   dbg.switch(0);
   dbg.print("myUndoFunc");
   dbg.switch(0);

   if (act.Aktiv != 1)
      return;

   if (Zug.idx <= 0) 
      return;

   if (act.BeimLegen == 1)
      return;

   Zug.idx--;
   let x = Zug.arr[Zug.idx][0];
   let y = Zug.arr[Zug.idx][1];
   let b = Zug.arr[Zug.idx][2];
   let c = Zug.arr[Zug.idx][3];

   //table field
   let fname   = `_brett_${x}_${y}_`;
   let ele = _ctrl(fname);
   if (ele) {
      brettO.set_buchstabeBrett(".", x, y, false);
      ele.className = c;
   }

   //bank
   for (let i = 0; i < 7; i++)
   {
      let bankv = bankO.get_bankbuchstabe(i);
      if (bankv == ".") {
         bankv = b;
         bankO.set_bankbuchstabe(bankv, i);
         i = 8;
      }
   }   

   //aktZug
   let aktZug = _ctrl("_aktzug_").innerHTML;
   let i = aktZug.lastIndexOf ("(");
   //alert (aktZug + "," + i);
   if (i >= 0) {
      aktZug = aktZug.substr(0, i);
   }
   _ctrl("_aktzug_").innerHTML = aktZug;   
   
   ajLegeBuchstabe(x,y, "-", c);
   statusO.status_funktionbar(false,(Zug.idx > 0), (Zug.idx == 0), true, false);   
}

function myTauscheFunc()
{
   dbg.switch(0);
   dbg.print("myTauscheFunc");
   dbg.switch(0);

   if (act.Aktiv != 1)
      return;
   if (spiel.Steingesetzt == 1)
      return;

   act.TauscheAktiv = 1;
   statusO.status_funktionbar(false,(Zug.idx>0),(Zug.idx==0),false);
}

function myFertigFunc()
{
   dbg.switch(0);
   dbg.print("myFertigFunc:" + Zug.idx);
   dbg.switch(0);

   if (act.Aktiv != 1)
      return;

   if (act.TauscheAktiv == 1)  {
      myFertigFuncTausche();
   }
   else if (Zug.idx == 0)   // ohne Zug oder Tausch - weiter
   {
      ajAktivierenFunc(0,1);
      return;
   }   
   else{
      myFertigFuncSetze();
   }
} 
function myFertigFuncSetze()
{
   dbg.switch(0);
   dbg.print(`myFertigFuncSetze Aktiv:${act.Aktiv}`);
   dbg.switch(0);

   statusO.status_funktionbar(false,(Zug.idx>0),(Zug.idx==0),false);

   if (zugControlO.control_zug() == 0)  {
      statusO.status_funktionbar(false,true,(Zug.idx>0),(Zug.idx==0),false);
      return;
   }

   spiel.VetoWarteLoops = 0;
   if (spiel.VetoOption)
      ajVetoDateiSchreiben("c");
   else
      myFertigFuncSetzeContinue();
}

function myFertigFuncSetzeBreak(text)
{
   dbg.switch(0);
   dbg.print(`myFertigFuncSetzeBreak Aktiv:${act.Aktiv},${text}`);
   dbg.switch(0);

   //veto wurde eingelegt
   dlgO.ShowDlg(text);
   statusO.status_funktionbar(false,true,false,true,false);
}


function myFertigFuncSetzeContinue()
{
   dbg.switch(0);
   dbg.print(`myFertigFuncSetzeContinue Aktiv:${act.Aktiv}`);
   dbg.switch(0);

   //zuege
   let aktZug    = _ctrl("_aktzug_").innerHTML;
   let zuege     = _ctrl("_zuege_").innerHTML; 
   let neuerZug  = "";

   //alert(aktZug + "," + zuege)
   if (aktZug.length == 0)
      return;

   let lines = 0;
   for (let i =0 ; (i+4) < zuege.length; i=i+1) {
        if (zuege[i] == "<" &&  
            zuege[i+1] == "b" && zuege[i+2] == "r" && 
            zuege[i+3] == "/" && zuege[i+4] == ">")   
            lines = lines + 1;
   }
   lines = lines + 1;
   neuerZug = `lines [${spiel.Spieler}]${aktZug}`;

   let zuege2 = zuege +  
                 neuerZug + "<br/>";

   //_ctrl("_zuege_").innerHTML = zuege2;
   //_ctrl("_aktZug_").innerHTML  = "";

   //schreibe zuege
   act.SchreibeZugAktiv=1;
   ajSchreibeZug(neuerZug);
    
   //bank
   ajFuelleBank();

   //#ajAktivierenFunc(0);
   statusO.status_funktionbar(false,(Zug.idx>0),(Zug.idx==0),false);
}
function myFertigFuncTausche()
{
   if (act.Aktiv != 1)
      return;

   statusO.status_funktionbar(false,(Zug.idx>0),(Zug.idx==0),false);

   let bsts = '';   
   for (let x = 0; x < 7; x = x +1) {
      let fname    = `_bank_${x}_`;
      let fnameI   = `_bank_${x}_i`;
      let f  = _ctrl(fname); 
      let fI = _ctrl(fnameI); 

      if (f.style.backgroundColor == MarkBgColor) {
         bsts = bsts + "," + fI.name;
         f.style.backgroundColor = act.SelBrettBgColor;
         bankO.set_bankbuchstabe(".", x);
      };
   }
   dbg.switch(0);
   dbg.print("myFertigFuncTausche:" + bsts);
   dbg.switch(0);

   //gebe buchstaben zur�ck
   ajTauscheBuchstaben(bsts);
    
   //erst sp�ter
   //-ajFuelleBank();
   //-ajAktivierenFunc(0);
   //nachdem die Buchstaben wieder im Beutel sind.
   
   act.TauscheAktiv = 0;
}


function myVetoFunc() 
{
   if (!spiel.VetoOption)
      return;

   dbg.switch(0);
   dbg.print("myVetoFunc");
   dbg.switch(0);

   //passiv - schreibt das Veto
   ajVetoDateiSchreiben("y");
   statusO.status_funktionbar();
}

//laden/speichern eines spiels
function myMultiFunc()
{
   let txt = _ctrl("_multi_").innerText;
   if (txt == "Speichern") {
      act.DlgType = "speichern";
      dlgO.ShowDlg("Passwort zur Speicherung (mind. 4 Buchstaben).", 
              "Speicherung des Spiels", 
              "normal", "1");
   }
   if (txt == "Laden") {
      act.DlgType = "laden";
      dlgO.ShowDlg(txtLadenDlg, "Laden eines gespeicherten Spiels", "normal", "1");
   }
}


/////////////////////////////////////////////////////////// multifunktionale-Funktionen
//- setzt das spieler feld
function setze_spieler (result)
{
   let sp1 = _ctrl("_spieler1_");
   let sp2 = _ctrl("_spieler2_");
   let sp3 = _ctrl("_spieler3_");
   let sp4 = _ctrl("_spieler4_");
   let sp  = [sp1, sp2, sp3, sp4];
   for (let i = 0; i < 4; i = i +1) {
      sp[i].innerHTML = ".";
      sp[i].className = "spielerinaktiv";
   }

   act.Aktiv    = 0;
   spiel.Steingesetzt = 0;

   let keinSpielerAktiv = true;

   dbg.switch(0);
   dbg.print("setze_spieler:" + result);
   //result  <aktiv>,<spieler>,<geld>,0,<aktiv>,<spieler>,<geld>,0,.. 
   if (result.length < 2) {
   }
   else {
      //let spieler = _ctrl("_spieler_").value;
      let feld = result.split(",");
      //alert("setze_spieler:" + result + "," + feld.length);
      for (let i=0, si=0; 
          (i+3) < feld.length && si < 4; 
          i=i+4, si=si+1) 
      {
         sp[si].innerHTML = feld[i+1] + "," + feld[i+2];
         if (feld[i] == 0)  {
            sp[si].className = "spielerinaktiv";
         }
         else {
            keinSpielerAktiv = false;
            if (feld[i+1] == spiel.Spieler)  {
               sp[si].className = "meinspieleraktiv";
               //statusO.status_funktionbar(false,false,false,true);
               act.Aktiv = 1;
               if (Zug.idx > 0 && bankO.bank_belegung() == "-")
                  ajAktivierenFunc(0,1);
               Zug.idx = 0;
            }
            else {
               sp[si].className = "spieleraktiv";
            }
         }
      }
   }     
   if (act.Aktiv == 1)  {
      statusO.status_funktionbar(false,(Zug.idx>0),(Zug.idx==0),true);
   }
   else if (keinSpielerAktiv == true) {
      statusO.status_funktionbar(true,false,false,false);
   }
   else {
      statusO.status_funktionbar(false,false,false,false);
   }
}

//- versorgt die anderen spieler mit einem gelegten buchstaben/undo eines buchstaben
function setze_gelegt (result, onlydisplay=false)
{
   dbg.switch(0);
   dbg.print("setze_gelegt:" + result);
   if (  result == undefined  ||
         result == "-"  ||
         result.length == 0     )
      return;

   let aktionen = result.split("+");

   //aktionen:  $aktionsnr, $spieler, $x, $y, $buchstabe, $clname
   for (let i = 0; i < aktionen.length; i = i +1) {
      if (aktionen[i].length > 0) {
         let feld = aktionen[i].split(",");
         dbg.print("setze_gelegt:" + i + ")" + 
               feld[0] + "," + feld[2]+ "," + feld[3] + "," + feld[4]);
         
         if (act.Aktiv == 1)
            continue;

         spiel.AktionsNr = parseInt(feld[0]);

         if (feld[4] == "-")  {   //undo
            brettO.setundo_buchstabeBrett(feld[2],feld[3], feld[5]);
         }   
         else   {
            if (onlydisplay == true)
               brettO.set_buchstabeBrett(feld[4],feld[2],feld[3],false);
            else
               brettO.set_buchstabeBrett(feld[4],feld[2],feld[3],true);
         }
      }
   }
}

//- veto
function control_veto(vetos) 
{
   if (!act.Aktiv)
      return;

   if (!spiel.VetoOption)
      return;

   dbg.switch(0);
   dbg.print("control_veto:" + act.Aktiv + "-" + vetos);

   let vetoEingelegt = 0;
   let vetoWartend   = 0;
   let vetoSpieler   = "";

   let feld = vetos.split("+");
   for (let i=0; i < feld.length; i=i+1) 
   {
      dbg.print("-feld:" + feld[i]);
      if (feld[i] && feld[i].length > 5) {
         let feld2 = feld[i].split(",");
         dbg.print("-feld2:" + feld2[0] + "," + feld2[1] + "," + feld2[2]);
         if (feld2[0] == '1')  { //aktiv - selber
         }  
         else {
            if (feld2[2] == 'n')  {
            }
            if (feld2[2] == 'y')  {
               vetoEingelegt = 1;
               vetoSpieler = feld2[1];
            }
            if (feld2[2] == '0')  {
               vetoWartend = 1;
            }
         }       
      }
   }

   dbg.print("-vetoEingelegt,wartend:" + vetoEingelegt + "," + vetoWartend);

   if (vetoEingelegt == 1) {
      //Veto anzeigen - kein 'Fertig'  - veto.datei l�schen
      ajVetoDateiSchreiben("d");
      myFertigFuncSetzeBreak(vetoSpieler + " legt Veto ein!");
      dbg.switch(0);
      return 0;
   }
   else if (vetoWartend == 1) {
      spiel.VetoWarteLoops += 1;

      if (spiel.VetoWarteLoops > spiel.VetoWarteLoopsLIMIT)  {
         //genug gewartet
         ajVetoDateiSchreiben("d");
         myFertigFuncSetzeContinue();   
      }
      else  {
         //einfach weiter warten
      }
      dbg.switch(0);
      return 0;
   }
   else {
      //'Fertig' ausf�hren - veto.datei l�schen      
      ajVetoDateiSchreiben("d");
      myFertigFuncSetzeContinue();
   }
   dbg.switch(0);
}

// neue zeuge ->brett   ->zuegelist
function verarbeite_neue_zuege(resulta)
{
   let fld = resulta.split("+");
   dbg.switch(1);
   dbg.print("verarbeite_neue_zuege");
   dbg.print("-res:" + resulta);

   for (let j = 0; j < fld.length ; j += 1) {
      if (fld[j].length > 0) {
         //steine aufs brett   
         let feld = fld[j].split(",");
         for (let i = 2; (i+3) < feld.length; i += 3) {
            brettO.set_buchstabeBrett (feld[i], feld[i+1], feld[i+2]); 
         }   

         //zuege list fenster
         let zuege     = _ctrl("_zuege_").innerHTML; 
         let neuerzug  = display_zuege(fld[j]);

         dbg.print("-zuege:" + zuege);
         dbg.print("-neuerzug:" + neuerzug);
         let zuege2 = zuege + neuerzug;
         _ctrl("_zuege_").innerHTML = zuege2;

         _ctrl("_aktzug_").innerHTML = "";
      }
   }
   dbg.switch(0);
}

function verarbeite_neue_worte(resultb)
{
   //worte list fenster
   let worte     = _ctrl("_worte_").innerHTML; 
   let neueworte = display_worte(resultb);

   let worte2 = worte +  neueworte;

   _ctrl("_worte_").innerHTML = worte2;
   
}

function verarbeite_neue_bankbuchstaben(result)
{
   let res = result.replace(/,/g, "");

   dbg.switch(0);
   dbg.print("-res:" + res);

   let j = 0;
   for (let i = 0; i < 7  &&  j < res.length; i++)
   {
      let bankv = bankO.get_bankbuchstabe(i);
      if (bankv == ".") {
         bankv = res[j];
         bankO.set_bankbuchstabe(bankv,i);
         j = j + 1;
      }
   }   
}

function format_zug_to_transfer  (zug)
{
   let nz = zug.replace(/  /g, "");
   nz = nz.replace(/ /g, ",");
   nz = nz.replace(/\[/g, ",");
   nz = nz.replace(/\]/g, "");
   nz = nz.replace(/\(/g, ",");
   nz = nz.replace(/\)/g, "");
   nz = nz.replace(/\,\,/g, ",");
   return nz;
}
function display_zug  (transferzug)
{
   if (transferzug.length < 8)
      return "";

   let feld = transferzug.split(",");
   let idx = feld[0];
   let spieler = feld[1];
   let buchxy = "";
   for (let i = 2; (i+3) < feld.length; i = i + 3) {
      buchxy += `(${feld[i]} ${feld[i+1]},${feld[i+2]}) `; 
   }   
   let ret = `${idx} [${spieler}] ${buchxy}`;

   return ret;
}
function display_zuege (transferzuege)
{
   if (transferzuege.length < 4)
      return "";

   dbg.switch(1);
   dbg.print("display_zuege: " + transferzuege);
   let felder = transferzuege.split("+");
   dbg.print("-felder len: " + felder.length);

   let ret = '';

   for (let j = 0; j < felder.length; j += 1) {
      if (felder[j].length > 0) {
         ret += felder[j] + "<br/>";
      }
   }
   dbg.print("-ret:" + ret);
   dbg.switch(0);
   return ret;
}
function display_worte (transferworte)
{
   if (transferworte.length < 4)
      return "";

   dbg.switch(0);
   dbg.print("display_worte: "+ transferworte);
   let felder = transferworte.split("+");
   dbg.print("-felder len: "+ felder.length);

   let ret = '';

   for (let j = 0; j < felder.length; j = j + 1) {
      if (felder[j].length > 0) {
         let feld = felder[j].split(",");
         let idx = feld[0];
         let spieler = feld[1];
         let worte = "";
         for (let i = 2; i < feld.length; i = i + 1) {
            worte = worte + " " + feld[i]; 
         }   
         ret += `${idx} [${spieler}] ${worte}<br/>`;
         spiel.WortZeilenNr = idx;      
      }
   }
   dbg.switch(0);
   return ret;
}

//stored
function clear_stored_sellist() {
   let sellist = _ctrl("_stored_")
   let i, L = sellist.options.length - 1;
   for(i = L; i >= 0; i--) {
         sellist.remove(i);
   }
}


function add_stored_sellist(item)  
{
   let sellist = _ctrl("_stored_")
   let option = document.createElement("option");
   option.text = item;
   sellist.add(option);
}
function get_stored_select()  
{
   let selidx     = _ctrl('_stored_').selectedIndex;
   let seloptions = _ctrl('_stored_').options;
   let seloption  = seloptions[selidx].text;
   return seloption;
}


//////////////////////// ajax funcs - interaktion mit dem -> webserver
//Ajax mit closure
function AjaxProc()
{
   let thisObj     = this;
   this.req        = null;
   this.calledProc = function() { 
      if (thisObj.req.readyState == 4) 
      {
         if (thisObj.req.status == 200) 
         {
            let result =  thisObj.req.responseText;
            //alert(result);
            thisObj.userProc(result); 
            thisObj.req = 0;
         }
      }
   }
   this.callProc   = function(url) {
      // branch for native XMLHttpRequest object
      if (window.XMLHttpRequest) 
      {
         thisObj.req = new XMLHttpRequest();
         thisObj.req.onreadystatechange = thisObj.calledProc;
         thisObj.req.open("GET", url, true);
         thisObj.req.send(null);
      } 
      // branch for IE/Windows ActiveX version
      else if (window.ActiveXObject) 
      {
         thisObj.req = new ActiveXObject("Microsoft.XMLHTTP");
         if (thisObj.req) 
         {
            thisObj.req.onreadystatechange = thisObj.calledProc;
            thisObj.req.open("GET", url, true);
            thisObj.req.send();
         }
      }
   }
   this.userProc   = null;
}

//-einzelne Ajax-Fkt
//-- Anmeldedten -> WebServer
var AjAnmelden = 0;
function ajAnmeldeFunc(spielId, spieler, mitspielerAdr1, mitspielerAdr2, mitspielerAdr3,vielepkte, softend,mitveto)
{  //spielId + "," + spieler);
   let dt   = new Date();
   let secs = dt.getTime();

   let neu = "1";
   dbg.switch(1);
   dbg.print("jaAnmeldeFunc:" + spielId + "," + spieler + "," + 
               mitspielerAdr1 + " " + mitspielerAdr2 + " " + mitspielerAdr3 + " " + 
               vielepkte + softend);   
   dbg.switch(0);
   let url = BASEURL + "/s3Anmelden.cgi?" +
      "spielId=" + spielId + 
      "&amp;spieler=" + spieler + 
      "&amp;mitspieleradr1=" + mitspielerAdr1 + 
      "&amp;mitspieleradr2=" + mitspielerAdr2 + 
      "&amp;mitspieleradr3=" + mitspielerAdr3 + 
      "&amp;vielepkte=" + vielepkte + 
      "&amp;softend=" + softend + 
      "&amp;mitveto=" + mitveto + 
      "&amp;neu=" + neu + 
      "&amp;time=" + secs;

   AjAnmelden = new AjaxProc();
   AjAnmelden.userProc = processAnmelden;
   AjAnmelden.callProc(url);
}
function processAnmelden(result)
{
   dbg.switch(1);
   dbg.print("processAnmelden:" + result);   
   dbg.switch(0);

   if (result == "-") {
      return;
   }
   if (result == "-1")   {
      dlgO.ShowDlg("Der Name wird schon benutzt!<br/>Einen anderen Namen verwenden.", "Fehler", "normal", 0);
      statusO.status_anmeldedlg (true);  
      return;
   }
   if (result == "-2") {
      dlgO.ShowDlg("SpielId wird schon benutzt!<br/>Eine andere SpielId verwenden.", "Fehler", "normal", 0);
      statusO.status_anmeldedlg (true);  
      return;
   }
   
   //anmelde form
   //_ctrl("_spielId_").className = "spielIddis";
   _ctrl("_spieler_").className = "spielerdis";
   //_ctrl("_spielId_").readOnly = true;    
   _ctrl("_spieler_").readOnly = true;    
   //_ctrl("_neu_").readOnly = true;    
   statusO.myButton("_anmelden_", false);
   statusO.myButton("_multi_", false);

   setze_spieler(result);
   zustand = Zustd.angemeldet;

   let spielid = _ctrl("_spielId_").value;
   _ctrl("_spielIdCopy_").innerHTML = "(" + spielid + ")";

   KontrolleSpieler();  // starte Loop
}


//-- mit 'Starten' wird der Process eingeleitet,
//   die SpielId zu kontrollieren
var AjStarten = 0;
function ajStartenFunc(aktivieren)
{  
   let dt   = new Date();
   let secs = dt.getTime();

   let url = BASEURL + "/s3Starten.cgi?" +
      "spielId=" + spiel.SpielId + 
      "&amp;spieler=" + spiel.Spieler + 
      "&amp;time=" + secs;

   AjStarten = new AjaxProc();
   AjStarten.userProc = processStarten;
   AjStarten.callProc(url);
}
function processStarten(result)
{
   if (result.length == "-") 
      return;

   //neue spielId
   if (result.substr(0,2) == "n,") {
      let list = result.split(",");
      _ctrl("_spielId_").value = list[3];
   }
   else  {
      setze_spieler(result);   
   }
   zustand = Zustd.spiel_fertig;
   act.SchreibeZugAktiv=0;
}



//-- ein Spieler beginnt
var AjAktivieren = 0;
function ajAktivierenFunc(aktivieren, nurGeschoben=0)
{  
   let dt   = new Date();
   let secs = dt.getTime();

   let url = BASEURL + "/s3Aktivieren.cgi?" +
      "spielId=" + spiel.SpielId + 
      "&amp;spieler=" + spiel.Spieler + 
      "&amp;aktivieren=" + aktivieren + 
      "&amp;geschoben=" + nurGeschoben + 
      "&amp;time=" + secs;

   AjAktivieren = new AjaxProc();
   AjAktivieren.userProc = processAktivieren;
   AjAktivieren.callProc(url);
}
function processAktivieren(result)
{
   if (result.length == "-") 
      return;

   //neue spielId
   if (result.substr(0,2) == "n,") {
      let list = result.split(",");
      _ctrl("_spielId_").value = list[2];
   }
   else  {
      setze_spieler(result);   
   }
   act.SchreibeZugAktiv=0;
}


//-- VorKontrolle der Spieler
//   Spieler sind angemeldet - SpielId nur vorl�ufig
// -> nur Spieler darstellen
var AjVorKontrolleSpieler = 0;
function ajVorKontrolleSpieler()
{ 
   let dt   = new Date();
   let secs = dt.getTime();

   let url = BASEURL + "/s3VorZustandSpieler.cgi?" +
      "spielId=" + spiel.SpielId + 
      "&amp;time=" + secs;

   AjVorKontrolleSpieler = new AjaxProc();
   AjVorKontrolleSpieler.userProc = processVorKontrolleSpieler;
   AjVorKontrolleSpieler.callProc(url);
}

function processVorKontrolleSpieler(result)
{
   if (result.length == "-") 
      return;
   if (result == lastzustand.AktiveSpieler)
      return;

   dbg.switch(0);
   dbg.print("processVorKontrolleSpieler:" + result);
   dbg.print("-Last Spieler:" + lastzustand.AktiveSpieler);

   let fr = result.split(",");
   for (let i = 0; i < fr.length ; i = i +1) {
      dbg.print("-result fr " + i + fr[i]);
   }

   if (fr.length > 3  &&  fr[3] == "+") {
      dbg.print("-Normalfall Id Kontrolle abgeschlossen");
      zustand = Zustd.spiel_fertig; 
      dbg.switch(0);
      return;
   }
   //zustand = Zustd.spiel_fertig; 
   
   if (lastzustand.AktiveSpieler != result) {
      setze_spieler(result);   
   }
   lastzustand.AktiveSpieler = result;
   dbg.switch(0);
}



//-- Kontrolle der Spieler
//   - wer ist aktiv
//   - wechsel des aktiven Spielers
//   - immer der letzter Zug
var AjKontrolleSpieler = 0;
function ajKontrolleSpieler()
{  
   let neu = 0;
   let dt   = new Date();
   let secs = dt.getTime();

   let url = BASEURL + "/s3ZustandSpieler.cgi?" +
      "spielId=" + spiel.SpielId + 
      "&amp;spieler=" + spiel.Spieler + 
      "&amp;aktionsnr=" + spiel.AktionsNr + 
      "&amp;time=" + secs;

   AjKontrolleSpieler = new AjaxProc();
   AjKontrolleSpieler.userProc = processKontrolleSpieler;
   AjKontrolleSpieler.callProc(url);
}

function processKontrolleSpieler(result)
{
   if (result.length == "-") 
      return;
   if (result.length == "-#-") 
      return;
   if (result == lastzustand.AktiveSpieler)
      return;

   let resfld = result.split("#");
   dbg.switch(1);
   dbg.print(`processKontrolleSpieler#0:${resfld[0]} #1:${resfld[1]} #2:${resfld[2]} #3:${resfld[3]}`);
   dbg.print(`-Last Spieler:${lastzustand.AktiveSpieler},Legen:${lastzustand.Legen}`);
   dbg.switch(0);

   //veto ist im gange
   let vetoAktiv = 0; 
   if (resfld[2] && resfld[2].length > 5) {
         if (act.Aktiv)
         statusO.status_funktionbar(0,0,0,0,0);
      else
         statusO.status_funktionbar(0,0,0,0,1);
      control_veto(resfld[2]);
      vetoAktiv = 1;
      //return;
   }

   if (vetoAktiv == 0  &&  resfld[0].substr(0,2) == "n,") {
      let fr = resfld[0].split(",");
      dbg.print("-Sonderfall neue Id:" + fr[2]);
      spiel.SpielId =  fr[2];    
      _ctrl("_spielId_").value    = spiel.SpielId;
      _ctrl("_aktzug_").innerHTML = "";        
      statusO.status_brettdlg (true);
      return;
   }
   if (vetoAktiv == 0 && zustand == Zustd.spiel_fertig)  {
      dbg.print("-Normalfall");
      ajFuelleBank();
      zustand = Zustd.spielen;
      statusO.status_brettdlg (true);
      statusO.status_multi(true, "Speichern");
      return;
   }        

   dbg.print(`-${lastzustand.AktiveSpieler} ? ${resfld[0]}`);
   if (lastzustand.AktiveSpieler != resfld[0]) {
      setze_spieler(resfld[0]);   
      ajLeseLetztenZug();
      //statusO.status_funktionbar (false,false,true,true);
   }
   lastzustand.AktiveSpieler = resfld[0];

   if (lastzustand.Legen != resfld[1]) {
      setze_gelegt(resfld[1]);   
   }
   lastzustand.Legen = resfld[1];

   if (resfld[3].search("veto") >= 0) {
      spiel.VetoOption = 1;
      _ctrl("_mitveto_").checked = true;
   }
   if (resfld[3].search("vp") >= 0) 
      _ctrl("_vielePkte_").checked = true;
   if (resfld[3].search("se") >= 0) 
      _ctrl("_softEnd_").checked = true;
   _ctrl("_spielIdCopy_").innerHTML = "(" + resfld[3] + ")";
   dbg.switch(0);
}

//-- holen der Steine aus dem gemeinsamen Beutel
var AjFuelleBank = 0;
function ajFuelleBank() 
{
   let dt   = new Date();
   let secs = dt.getTime();

   let bankbeleg  = bankO.bank_belegung();
   let anzahl = 0;
   for (let i = 0; i < 7; i++)
   {
      let bankv = bankO.get_bankbuchstabe(i);
      if (bankv == ".") 
         anzahl++;
   }
   dbg.switch(0);
   dbg.print(`ajFuelleBank:${spiel.SpielId},${spiel.Spieler},${bankbeleg},${anzahl}`);
   dbg.switch(0);
   let url = BASEURL + "/s3FuelleBank.cgi?" +
      "spielId=" + spiel.SpielId + 
      "&amp;spieler=" + spiel.Spieler + 
      "&amp;bank=" + bankbeleg + 
      "&amp;anzahl=" + anzahl + 
		"&amp;time=" + secs;

   AjFuelleBank = new AjaxProc();
   AjFuelleBank.userProc = processFuelleBank;
   AjFuelleBank.callProc(url);
}
function processFuelleBank(result)
{
   dbg.switch(0);
   dbg.print("processFuelleBank:" + result);
   dbg.switch(0);
   
   if (result.length == 0) 
      return;

   if (result == "-") 
      return;

   verarbeite_neue_bankbuchstaben(result);
   dbg.switch(0);
}   


//-- Schreibt Veto.datei
//   anlegen vom aktiven spieler                   aktion:c
//   passiv spieler - legt veto ein oder nicht     aktion:y  aktion:n
//   l�scht die veto.datei - nach 'Fertig' == OK   aktion:d
var AjVetoDatei = 0;
function ajVetoDateiSchreiben(aktion)
{  
   if (!spiel.VetoOption)
      return;

   let dt   = new Date();
   let secs = dt.getTime();

   dbg.switch(0);
   dbg.print(`ajVetoDateiSchreiben:${spiel.SpielId},${spiel.Spieler},${aktion}`);
   dbg.switch(0);

   let url = BASEURL + "/s3VetoDatei.cgi?" +
      "spielId=" + spiel.SpielId + 
      "&amp;spieler=" + spiel.Spieler +
      "&amp;aktion=" + aktion +
      "&amp;time=" + secs;

   AjVetoDatei = new AjaxProc();
   AjVetoDatei.userProc = processVetoDateiSchreiben;
   AjVetoDatei.callProc(url);
}

function processVetoDateiSchreiben(result)
{
}




//-- Schreiben des neuen Zugs
var AjSchreibeZug = 0;
function ajSchreibeZug(neuerzug) 
{
   let dt   = new Date();
   let secs = dt.getTime();

   let transzug = format_zug_to_transfer(neuerzug);

   let url = BASEURL + "/s3SchreibeZug.cgi?" +
		 "transzug=" + transzug + 
		 "&amp;spieler=" + spiel.Spieler + 
		 "&amp;spielId=" + spiel.SpielId + 
		 "&amp;time=" + secs;

   AjSchreibeZug = new AjaxProc();
   AjSchreibeZug.userProc = processSchreibeZug;
   AjSchreibeZug.callProc(url);
}
   
function processSchreibeZug(result)
{
   ajAktivierenFunc(0);
}   

//-- lesen des letzten Zugs und darstellen auf dem Brett
//   wichtig beim Spielerwechsel
var AjLeseZug = 0;
function ajLeseLetztenZug() 
{
   let dt   = new Date();
   let secs = dt.getTime();

   dbg.switch(0);
   dbg.print(`ajLeseLetztenZug:${spiel.SpielId},${spiel.WortZeilenNr}`);
   dbg.switch(0);
   

   let url = BASEURL + "/s3LeseZug.cgi?" +
		 "spielId=" + spiel.SpielId + 
		 "&amp;wortzeilennr=" + spiel.WortZeilenNr + 
		 "&amp;time=" + secs;

   AjLeseZug = new AjaxProc();
   AjLeseZug.userProc = processLeseZug;
   AjLeseZug.callProc(url);
}
   
function processLeseZug(result)
{
   if (result.length < 8) 
      return;

   let resFld = result.split("#");
   let resulta = resFld[0];
   let resultb = resFld[1];

   dbg.switch(1);
   dbg.print("processLeseZug:" + result + "," + resulta + "," + resultb);   
   dbg.switch(0);

   if (lastzustand.LeseZug == result)
      return;

   if (resulta.length > 0)  {
      dbg.print("-:" + resulta);   
      verarbeite_neue_zuege(resulta);
   }

   if (resultb.length > 0)  {
      dbg.print("-:" + resultb);   
      verarbeite_neue_worte(resultb);
   }

   lastzustand.LeseZug = result;
   dbg.switch(0);
}   


//-- der gelegte Buchstabe wird gespeichert
var AjLege = 0;
function ajLegeBuchstabe(x,y,buchstabe,clname="") 
{
   act.BeimLegen = 1;
   let dt   = new Date();
   let secs = dt.getTime();

   spiel.AktionsNr = parseInt(spiel.AktionsNr) + 1;

   dbg.switch(0);
   dbg.print(`ajLegeBuchstabe:${x},${y},${buchstabe},${clname},${spiel.Spieler},${spiel.SpielId}`);
   dbg.switch(0);
   let url = BASEURL + "/s3SchreibeLegeBuchstabe.cgi?" +
      "x=" + x + 
      "&amp;y=" + y + 
      "&amp;buchstabe=" + buchstabe + 
      "&amp;aktionsnr=" + spiel.AktionsNr + 
      "&amp;clname=" + clname + 
      "&amp;spieler=" + spiel.Spieler + 
      "&amp;spielId=" + spiel.SpielId + 
		"&amp;time=" + secs;

   AjLege = new AjaxProc();
   AjLege.userProc = processLegeBuchstabe;
   AjLege.callProc(url);
}
   
function processLegeBuchstabe(result)
{
   act.BeimLegen = 0;
}   


//-- der gelegte Buchstabe wird gespeichert
var AjTauscheBuchstb = 0;
function ajTauscheBuchstaben(bsts) 
{
   let dt   = new Date();
   let secs = dt.getTime();

   dbg.print(`ajTauscheBuchstaben:${bsts},${spiel.Spieler},${spiel.SpielId}`);
   let url = BASEURL + "/s3TauscheBuchstaben.cgi?" +
      "bsts=" + bsts + 
      "&amp;spieler=" + spiel.Spieler + 
      "&amp;spielId=" + spiel.SpielId + 
		"&amp;time=" + secs;

   AjTauscheBuchstb = new AjaxProc();
   AjTauscheBuchstb.userProc = processTauscheBuchstaben;
   AjTauscheBuchstb.callProc(url);
}
   
function processTauscheBuchstaben(result)
{
   //bank
   ajFuelleBank();
   ajAktivierenFunc(0);
}   


//-- Speichern/Ladender gelegte Buchstabe wird gespeichert
var AjMulti = 0;
function ajMulti(mode, spielId, spieler, passwd, storedName="") 
{
   let dt   = new Date();
   let secs = dt.getTime();

   dbg.print("ajMulti:" + mode);
   let url = BASEURL + "/s3Multi.cgi?" +
      "mode=" + mode + 
      "&amp;spielId=" + spielId + 
      "&amp;spieler=" + spieler + 
      "&amp;passwd=" + passwd + 
      "&amp;storedName=" + storedName + 
		"&amp;time=" + secs;

   AjMulti = new AjaxProc();
   AjMulti.userProc = processMulti;
   AjMulti.callProc(url);
}
   
function processMulti(result)
{
   let resFld = result.split("#");
   let resulta = resFld[0];

   dbg.switch(1);
   dbg.print("processMulti:" + result);


   if (resulta == "speichern") {
      if (resFld[1] == "-") {
         dlgO.ShowDlg("Speichern hat nicht geklappt!", "Fehler","normal",0);
      }
      else  {
         dlgO.ShowDlg("Speichern des Spiels als:<br/>" + resFld[1], "Information","normal",0);
         ajMulti("holestored",0,0,"");
      }
   }

   if (resulta == "holestored") {
      let select = "";
      if (resFld[1] == "-") {
         select = "-";
      }
      else {
         let items = resFld[1].split("+");
         clear_stored_sellist();  
         for (let j = 0; j < items.length; j = j + 1) {
            if (items[j].length > 0) {
               add_stored_sellist(items[j]);
            }            
         }
         let txt = _ctrl("_multi_").innerText;
         if (txt == "-")
	         statusO.status_multi(true, "Laden");
      }
   }

   if (resulta == "laden") {
      if (resFld[1] == "PWD+,SP+") {
         spiel.Spieler = _ctrl('_spieler_').value;
         spiel.SpielId = resFld[2];
         ajMulti("loadall", spiel.SpielId, spiel.Spieler, "", "");
         statusO.status_anmeldedlg(false);
         statusO.status_multi(true, "Speichern");
      }
      else {
         let fld = resFld[1].split(",");
         let text = "";
         if (fld[0] == "PWD-")   
            text += "Passwort:nicht ok<br/>";
         if (fld[1] == "SP-")    
            text += "Spieler:nicht ok<br/>";
         dlgO.ShowDlg("Laden fehlgeschlagen! <br/>" + text, "Fehler", "normal");
      }
   }

   if (resulta == "loadall") {
         //"$bank#$zuege#$worte#$aktionen";
         verarbeite_neue_bankbuchstaben(resFld[1]);
         verarbeite_neue_zuege(resFld[2]);
         verarbeite_neue_worte(resFld[3]);
         setze_gelegt(resFld[4], true);
         
         zustand       = Zustd.laden_warten;
         KontrolleSpieler();  // starte Loop
   }
   if (resulta == "allloaded") {
      if (resFld[1].search("-") == -1) {
         zustand       = Zustd.spielen;
      }
   }
   dbg.switch(0);
}   


// End to server
var AjEnd = 0;
function ajEnd() 
{
   let dt   = new Date();
   let secs = dt.getTime();

   dbg.switch(1);
   dbg.print("ajEnd:-");

   let url = BASEURL + "/s3End.cgi?" +
      "spielId=" + spiel.SpielId + 
		"&amp;time=" + secs;

   AjEnd = new AjaxProc();
   AjEnd.userProc = processEnd;
   AjEnd.callProc(url);

   dbg.switch(0);
}
   
function processEnd(result)
{
}

/////////////////////////////////////////////////////////// Main Loop, 
//  l�uft st�ndig um Spieler und Buchstabenlegungen zu kontrollieren
function KontrolleSpieler () {
   //dbg.print("KontrolleSpieler");

   if (zustand == Zustd.angemeldet)  {
      ajVorKontrolleSpieler();
   }
   else if ((zustand == Zustd.spiel_fertig || zustand == Zustd.spielen) &&
            (act.SchreibeZugAktiv == 0) ) {
      ajKontrolleSpieler();
   }
   else if (zustand == Zustd.laden_warten)  {
      ajMulti("allloaded",spiel.SpielId, spiel.Spieler,"","");
   }
   window.setTimeout("KontrolleSpieler()", 2500); 
}
