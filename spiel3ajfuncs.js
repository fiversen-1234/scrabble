//spiel3ajfuncs.js
// - nur ajax-functionen
// - und die staendige Loop



//////////////////////// ajax funcs - interaktion mit dem -> webserver
//Ajax mit closure
function AjaxProc()
{
   var thisObj     = this;
   this.req        = null;
   this.calledProc = function() { 
      if (thisObj.req.readyState == 4) 
      {
         if (thisObj.req.status == 200) 
         {
            var result =  thisObj.req.responseText;
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
AjAnmelden = 0;
function ajAnmeldeFunc(spielId, spieler, vielepkte, softend,mitveto)
{  //spielId + "," + spieler);
   var dt   = new Date();
   var secs = dt.getTime();

   var neu = "1";
   dbg_switch(0);
   dbg("jaAnmeldeFunc:" + spielId + spieler + " " + vielepkte + softend);   
   dbg_switch(0);
   url = BASEURL + "/s3Anmelden.cgi?" +
      "spielId=" + spielId + 
      "&amp;spieler=" + spieler + 
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
   //alert(" processAnmelden:" + result);
   //enableAuto

   if (result.length == "-") 
      return;

   //anmelde form
   document.getElementById("_spielId_").className = "spielIddis";
   document.getElementById("_spieler_").className = "spielerdis";
   document.getElementById("_spielId_").readOnly = true;    
   document.getElementById("_spieler_").readOnly = true;    
   //document.getElementById("_neu_").readOnly = true;    
   status_mybutton("_anmelden_", false);

   setze_spieler(result);
   Zustand = Zustd.angemeldet;

   var spielid = document.getElementById("_spielId_").value;
   document.getElementById("_spielIdCopy_").innerHTML = "(" + spielid + ")";

   KontrolleSpieler();  // starte Loop

/*alt    //bank
   ajFuelleBank();

   //globals
   SpielId = document.getElementById("_spielId_").value;
   Spieler = document.getElementById("_spieler_").value;

   setze_spieler(result);

   KontrolleSpieler();

   status_funktionbar(true,false,false,false);
   status_brettdlg (true); 
 */
}

function control_veto(vetos) 
{
   if (!Aktiv)
      return;

   if (!VetoOption)
      return;

   dbg_switch(0);
   dbg("control_veto:" + Aktiv + "-" + vetos);

   var vetoEingelegt = 0;
   var vetoWartend   = 0;
   var vetoSpieler   = "";

   var feld = vetos.split("+");
   for (var i=0; i < feld.length; i=i+1) 
   {
      dbg("-feld:" + feld[i]);
      if (feld[i] && feld[i].length > 5) {
         var feld2 = feld[i].split(",");
         dbg("-feld2:" + feld2[0] + "," + feld2[1] + "," + feld2[2]);
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

   dbg("-vetoEingelegt,wartend:" + vetoEingelegt + "," + vetoWartend);

   if (vetoEingelegt == 1) {
      //Veto anzeigen - kein 'Fertig'  - veto.datei löschen
      ajVetoDateiSchreiben("d");
      myFertigFuncSetzeBreak(vetoSpieler + " legt Veto ein!");
      dbg_switch(0);
      return 0;
   }
   else if (vetoWartend == 1) {
      VetoWarteLoops += 1;

      if (VetoWarteLoops > VetoWarteLoopsLIMIT)  {
         //genug gewartet
         ajVetoDateiSchreiben("d");
         myFertigFuncSetzeContinue();   
      }
      else  {
         //einfach weiter warten
      }
      dbg_switch(0);
      return 0;
   }
   else {
      //'Fertig' ausführen - veto.datei löschen      
      ajVetoDateiSchreiben("d");
      myFertigFuncSetzeContinue();
   }
   dbg_switch(0);
}


//-- mit 'Starten' wird der Process eingeleitet,
//   die SpielId zu kontrollieren
AjStarten = 0;
function ajStartenFunc(aktivieren)
{  
   var dt   = new Date();
   var secs = dt.getTime();

   var spielId = document.getElementById("_spielId_").value;
   var spieler = document.getElementById("_spieler_").value;
  
   var a = spielId + "," + spieler + "," + aktivieren;
   url = BASEURL + "/s3Starten.cgi?" +
      "spielId=" + spielId + 
      "&amp;spieler=" + spieler + 
      "&amp;time=" + secs;

   AjStarten = new AjaxProc();
   AjStarten.userProc = processStarten;
   AjStarten.callProc(url);
}
function processStarten(result)
{
   //alert(" processAktivieren:" + result);
   //enableAuto

   if (result.length == "-") 
      return;

   //neue spielId
   if (result.substr(0,2) == "n,") {
      var list = result.split(",");
      document.getElementById("_spielId_").value = list[3];
   }
   else  {
      setze_spieler(result);   
   }
   Zustand = Zustd.spiel_fertig;
   SchreibeZugAktiv=0;
}



//-- ein Spieler beginnt
AjAktivieren = 0;
function ajAktivierenFunc(aktivieren, nurGeschoben=0)
{  
   var dt   = new Date();
   var secs = dt.getTime();

   var spielId = document.getElementById("_spielId_").value;
   var spieler = document.getElementById("_spieler_").value;
   //var bank = bank_belegung();
   var neu = 0;
   //if (document.getElementById("_aktzug_").innerHTML == "neu") {
   //    neu = 1;
   //}
  
   var a = spielId + "," + spieler + "," + aktivieren;
   //alert("ajAktivierenFunc:" + a);   
   url = BASEURL + "/s3Aktivieren.cgi?" +
      "spielId=" + spielId + 
      "&amp;spieler=" + spieler + 
      "&amp;aktivieren=" + aktivieren + 
      "&amp;geschoben=" + nurGeschoben + 
   //   "&amp;bank=" + bank + 
   //   "&amp;neu=" + neu +    
      "&amp;time=" + secs;

   AjAktivieren = new AjaxProc();
   AjAktivieren.userProc = processAktivieren;
   AjAktivieren.callProc(url);
}
function processAktivieren(result)
{
   //alert(" processAktivieren:" + result);
   //enableAuto

   if (result.length == "-") 
      return;

   //neue spielId
   if (result.substr(0,2) == "n,") {
      var list = result.split(",");
      document.getElementById("_spielId_").value = list[2];
   }
   else  {
      setze_spieler(result);   
   }
   SchreibeZugAktiv=0;
}


//-- VorKontrolle der Spieler
//   Spieler sind angemeldet - SpielId nur vorläufig
// -> nur Spieler darstellen
AjVorKontrolleSpieler = 0;
function ajVorKontrolleSpieler()
{  //spielId + "," + spieler);

   var spielId = document.getElementById("_spielId_").value;
   var dt   = new Date();
   var secs = dt.getTime();

   url = BASEURL + "/s3VorZustandSpieler.cgi?" +
      "spielId=" + spielId + 
      "&amp;time=" + secs;

   AjVorKontrolleSpieler = new AjaxProc();
   AjVorKontrolleSpieler.userProc = processVorKontrolleSpieler;
   AjVorKontrolleSpieler.callProc(url);
}

/*function processKontrolleSpieler(result)
{
   if (result.length == "-") 
      return;
   if (result == LastZustandSpieler)
      return;
   setze_spieler(result);   
   LastZustandSpieler = result;
   ajLeseLetztenZug();
}
*/
function processVorKontrolleSpieler(result)
{
   if (result.length == "-") 
      return;
   if (result == LastZustandSpieler)
      return;

   dbg_switch(0);
   dbg("processVorKontrolleSpieler:" + result);
   dbg("-Last Spieler:" + LastZustandSpieler);

   var fr = result.split(",");
   for (var i = 0; i < fr.length ; i = i +1) {
      dbg("-result fr " + i + fr[i]);
   }

   if (result.substr(0,2) == "n,") {
      dbg("-Sonderfall neue Id:" + fr[3]);
      document.getElementById("_spielId_").value    = fr[3];    
      Zustand = Zustd.spiel_fertig; 
      dbg_switch(0);
      return;
   }
   if (fr.length > 3  &&  fr[3] == "+") {
      dbg("-Normalfall Id Kontrolle abgeschlossen");
      Zustand = Zustd.spiel_fertig; 
      dbg_switch(0);
      return;
   }
   //Zustand = Zustd.spiel_fertig; 
   
   if (LastZustandSpieler != result) {
      setze_spieler(result);   
   }
   LastZustandSpieler = result;
   dbg_switch(0);
}



//-- Kontrolle der Spieler
//   - wer ist aktiv
//   - wechsel des aktiven Spielers
//   - immer der letzter Zug
AjKontrolleSpieler = 0;
function ajKontrolleSpieler()
{  //spielId + "," + spieler);

   var spielId = document.getElementById("_spielId_").value;
   var spieler = document.getElementById("_spieler_").value;
   var neu = 0;
   var dt   = new Date();
   var secs = dt.getTime();


   url = BASEURL + "/s3ZustandSpieler.cgi?" +
      "spielId=" + spielId + 
      "&amp;spieler=" + spieler + 
      "&amp;aktionsnr=" + AktionsNr + 
      "&amp;time=" + secs;

   AjKontrolleSpieler = new AjaxProc();
   AjKontrolleSpieler.userProc = processKontrolleSpieler;
   AjKontrolleSpieler.callProc(url);
}

/*function processKontrolleSpieler(result)
{
   if (result.length == "-") 
      return;
   if (result == LastZustandSpieler)
      return;
   setze_spieler(result);   
   LastZustandSpieler = result;
   ajLeseLetztenZug();
}
*/
function processKontrolleSpieler(result)
{
   if (result.length == "-") 
      return;
   if (result.length == "-#-") 
      return;
   if (result == LastZustandSpieler)
      return;

   var resfld = result.split("#");
   dbg_switch(0);
   dbg("processKontrolleSpieler#0:" + resfld[0] + "#1:" + resfld[1] + "#2:" + resfld[2] + "#3:" + resfld[3]);
   dbg("-Last Spieler:" + LastZustandSpieler + ",Legen:" + LastZustandLegen);
   dbg_switch(0);

   //veto ist im gange
   var vetoAktiv = 0; 
   if (resfld[2] && resfld[2].length > 5) {
         if (Aktiv)
         status_funktionbar(0,0,0,0,0);
      else
         status_funktionbar(0,0,0,0,1);
      control_veto(resfld[2]);
      vetoAktiv = 1;
      //return;
   }

   if (vetoAktiv == 0  &&  resfld[0].substr(0,2) == "n,") {
      var fr = resfld[0].split(",");
      dbg("-Sonderfall neue Id:" + fr[2]);
      document.getElementById("_spielId_").value    = fr[2];    
      document.getElementById("_aktzug_").innerHTML = "";        
      status_brettdlg (true);
      return;
   }
   if (vetoAktiv == 0 && Zustand == Zustd.spiel_fertig)  {
      dbg("-Normalfall");
      ajFuelleBank();
      Zustand = Zustd.spielen;
      status_brettdlg (true);
      return;
   }        

   dbg("-" + LastZustandSpieler + " ? " + resfld[0]);
   if (LastZustandSpieler != resfld[0]) {
      setze_spieler(resfld[0]);   
      ajLeseLetztenZug();
      //status_funktionbar (false,false,true,true);
   }
   LastZustandSpieler = resfld[0];

   if (LastZustandLegen != resfld[1]) {
      setze_gelegt(resfld[1]);   
   }
   LastZustandLegen = resfld[1];

   if (resfld[3].search("veto") >= 0) {
      VetoOption = 1;
      document.getElementById("_veto_").checked = true;
   }
   if (resfld[3].search("vp") >= 0) 
      document.getElementById("_vielePkte_").checked = true;
   if (resfld[3].search("se") >= 0) 
      document.getElementById("_softEnd_").checked = true;
   document.getElementById("_spielIdCopy_").innerHTML = "(" + resfld[3] + ")";
   dbg_switch(0);
}

//-- holen der Steine aus dem gemeinsamen Beutel
AjFuelleBank = 0;
function ajFuelleBank() 
{
   var dt   = new Date();
   var secs = dt.getTime();

   var spielId = document.getElementById("_spielId_").value;
   var spieler = document.getElementById("_spieler_").value;

   var bank  = bank_belegung();
   var anzahl = 0;
   for (var i = 0; i < 7; i++)
   {
      var bankv = get_bankbuchstabe(i);
      if (bankv == ".") 
         anzahl++;
   }
   dbg_switch(0);
   dbg("ajFuelleBank:" + spielId + "," + spieler + "," + bank + "," + anzahl);
   dbg_switch(0);
   url = BASEURL + "/s3FuelleBank.cgi?" +
      "spielId=" + spielId + 
      "&amp;spieler=" + spieler + 
      "&amp;bank=" + bank + 
      "&amp;anzahl=" + anzahl + 
		"&amp;time=" + secs;

   AjFuelleBank = new AjaxProc();
   AjFuelleBank.userProc = processFuelleBank;
   AjFuelleBank.callProc(url);
}
function processFuelleBank(result)
{
   dbg_switch(0);
   dbg("processFuelleBank:" + result);
   dbg_switch(0);
   
   if (result.length == 0) 
      return;

   if (result == "-") 
      return;

   var list = result.split(",");    
   var listN = list.length - 1;   //list ends with , - decrease

   dbg_switch(0);
   dbg("-listN:" + listN);
   var ri = 0;
   for (var i = 0; i < 7 &&  ri < listN; i++)
   {
      var bankv = get_bankbuchstabe(i);
      if (bankv == ".") {
         bankv = list[ri];
         set_bankbuchstabe(bankv,i);
         ri = ri + 1;
      }
   }   
   dbg_switch(0);
}   


//-- Schreibt Veto.datei
//   anlegen vom aktiven spieler                   aktion:c
//   passiv spieler - legt veto ein oder nicht     aktion:y  aktion:n
//   löscht die veto.datei - nach 'Fertig' == OK   aktion:d
AjVetoDatei = 0;
function ajVetoDateiSchreiben(aktion)
{  
   if (!VetoOption)
      return;

   var spielId = document.getElementById("_spielId_").value;
   var spieler = document.getElementById("_spieler_").value;
   var dt   = new Date();
   var secs = dt.getTime();

   dbg_switch(0);
   dbg("ajVetoDateiSchreiben:" + spielId + "," + spieler + "," + aktion);
   dbg_switch(0);

   url = BASEURL + "/s3VetoDatei.cgi?" +
      "spielId=" + spielId + 
      "&amp;spieler=" + spieler +
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
AjSchreibeZug = 0;
function ajSchreibeZug(neuerzug) 
{
   var dt   = new Date();
   var secs = dt.getTime();

   var spieler = document.getElementById("_spieler_").value;
   var spielId = document.getElementById("_spielId_").value;

   var transzug = transfer_zug(neuerzug);

   //transzug = "abc";
   //alert("ajSchrebeZug:" + transzug + "," + spieler + "," + spielId);   
   url = BASEURL + "/s3SchreibeZug.cgi?" +
		 "transzug=" + transzug + 
		 "&amp;spieler=" + spieler + 
		 "&amp;spielId=" + spielId + 
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
AjLeseZug = 0;
function ajLeseLetztenZug() 
{
   var dt   = new Date();
   var secs = dt.getTime();

   var spielId = document.getElementById("_spielId_").value;

   dbg_switch(0);
   dbg("ajLeseLetztenZug:" + spielId + "," + WortZeilenNr);
   dbg_switch(0);
   

   url = BASEURL + "/s3LeseZug.cgi?" +
		 "spielId=" + spielId + 
		 "&amp;wortzeilennr=" + WortZeilenNr + 
		 "&amp;time=" + secs;

   AjLeseZug = new AjaxProc();
   AjLeseZug.userProc = processLeseZug;
   AjLeseZug.callProc(url);
}
   
function processLeseZug(result)
{
   if (result.length < 8) 
      return;

   var resFld = result.split("#");
   var resulta = resFld[0];
   var resultb = resFld[1];

   dbg_switch(0);
   dbg("processLeseZug:" + result + "," + resulta + "," + resultb);   

   if (LastLeseZug == result)
      return;

   if (resulta.length > 0)  {
      dbg("-:" + resulta);   

      //steine aufs brett   
      var feld = resulta.split(",");
      for (var i = 2; (i+3) < feld.length; i = i + 3) {
         set_buchstabeBrett (feld[i], feld[i+1], feld[i+2]); 
      }   

      //zuege list fenster
      var zuege     = document.getElementById("_zuege_").innerHTML; 
      var neuerzug  = display_zug(resulta);

      var zuege2 = zuege +  
                  neuerzug + "<br/>";
      document.getElementById("_zuege_").innerHTML = zuege2;

      document.getElementById("_aktzug_").innerHTML = "";
   }

   if (resultb.length > 0)  {
      dbg("-:" + resultb);   

      //zuege list fenster
      var worte     = document.getElementById("_worte_").innerHTML; 
      var neueworte = display_worte(resultb);

      var worte2 = worte +  neueworte;

      document.getElementById("_worte_").innerHTML = worte2;
   }
   LastLeseZug = result;
   dbg_switch(0);
}   


//-- der gelegte Buchstabe wird gespeichert
AjLege = 0;
function ajLegeBuchstabe(x,y,buchstabe,clname="") 
{
   BeimLegen = 1;
   var dt   = new Date();
   var secs = dt.getTime();

   var spieler = document.getElementById("_spieler_").value;
   var spielId = document.getElementById("_spielId_").value;

   AktionsNr = parseInt(AktionsNr) + 1;
   //transzug = "abc";
   dbg_switch(0);
   dbg("ajLegeBuchstabe:" + x +"," + y + "," + buchstabe + "," + "," + clname 
        + "," + spieler + "," + spielId);
   dbg_switch(0);
   url = BASEURL + "/s3SchreibeLegeBuchstabe.cgi?" +
      "x=" + x + 
      "&amp;y=" + y + 
      "&amp;buchstabe=" + buchstabe + 
      "&amp;aktionsnr=" + AktionsNr + 
      "&amp;clname=" + clname + 
      "&amp;spieler=" + spieler + 
      "&amp;spielId=" + spielId + 
		"&amp;time=" + secs;

   AjLege = new AjaxProc();
   AjLege.userProc = processLegeBuchstabe;
   AjLege.callProc(url);
}
   
function processLegeBuchstabe(result)
{
   BeimLegen = 0;
}   


//-- der gelegte Buchstabe wird gespeichert
AjTauscheBuchstb = 0;
function ajTauscheBuchstaben(bsts) 
{
   var dt   = new Date();
   var secs = dt.getTime();

   var spieler = document.getElementById("_spieler_").value;
   var spielId = document.getElementById("_spielId_").value;

   dbg("ajTauscheBuchstaben:" + bsts + "," + spieler + "," + spielId);
   url = BASEURL + "/s3TauscheBuchstaben.cgi?" +
      "bsts=" + bsts + 
      "&amp;spieler=" + spieler + 
      "&amp;spielId=" + spielId + 
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







//- ständige Loop, um Spieler und Buchstabenlegungen zu kontrollieren
function KontrolleSpieler () {
   //dbg("KontrolleSpieler");

   if (Zustand == Zustd.angemeldet)
      ajVorKontrolleSpieler();
   else if ((Zustand == Zustd.spiel_fertig || Zustand == Zustd.spielen) &&
            (SchreibeZugAktiv == 0) )
      ajKontrolleSpieler();
   window.setTimeout("KontrolleSpieler()", 2500); 
}


