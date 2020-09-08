//  status.2.js
//


function Status() {    
}

Status.prototype.set_cursor = function(art)
{
   return 0;
   var i;
   f = document.querySelectorAll("*");
   for (i = 0; i < f.length; i++) {
      f[i].style.cursor = art;
   }
   return 1;
}


//-setzen status der controls 
Status.prototype.buttonlike =  function(name, aktiv)  //status_buttonlike(name, aktiv)
{
   let ele = _ctrl(name);
   if (aktiv) {
      ele.className = "likebut";
      ele.readOnly = false;    
      ele.disabled = false;
   }
   else {
      ele.className = "likebutdis";
      ele.readOnly = true;    
      ele.disabled = true;
   }
}
Status.prototype.myButton = function (name,aktiv)  //status_mybutton(name, aktiv)
{
   let ele = _ctrl(name);
   ele.className = (aktiv) ? "mybutton" : "mybuttondis";
   ele.readOnly  = !aktiv;    
   ele.disabled  = !aktiv;
}

Status.prototype.status_multi = function (aktiv, multitxt="")
{
   this.myButton("_multi_", aktiv);
   if (multitxt.length > 0) {
      _ctrl("_multi_").innerText = multitxt;
   }
}

Status.prototype.status_anmeldedlg = function(aktiv)  
{
   dbg.switch(0); 
   dbg.print("status_anmeldedlg");

   //_ctrl("_spielId_").readOnly   = !aktiv;     
   _ctrl("_spieler_").readOnly   = !aktiv;    
   if (_ctrl("_mitspielerAdr1_")) {
      _ctrl("_mitspielerAdr1_").readOnly   = !aktiv;
      _ctrl("_mitspielerAdr2_").readOnly   = !aktiv;
      _ctrl("_mitspielerAdr3_").readOnly   = !aktiv;

      if (!aktiv)  {
         var toggler = document.getElementsByClassName("mitspielerClose_sign");
         for (var i = 0; i < toggler.length; i++) {
            toggler[i].removeEventListener("click", mitspieler);
         }
      }
   }
   _ctrl("_vielePkte_").disabled = !aktiv;    
   _ctrl("_softEnd_").disabled   = !aktiv;    
   _ctrl("_mitveto_").disabled   = !aktiv;    
   
   //_ctrl("_anmelden_").readOnly  = !aktiv;    
   this.myButton("_anmelden_", aktiv);
   if (aktiv)  {
      //_ctrl("_spielIdL_").className = 'lblaktiv';      
      _ctrl("_spielerL_").className = 'lblaktiv';    
      //_ctrl("_AktivL_").className = 'lbl';    
   }
   else  {
      //_ctrl("_spielIdL_").className = 'lbl';      
      _ctrl("_spielerL_").className = 'lbl';    
      //_ctrl("_AktivL_").className = 'lblaktiv';    
   }
   dbg.switch(0);
}


Status.prototype.status_brettdlg = function(aktiv)  
{
   if (aktiv == true) {
      _ctrl("_aktzuglbl_").className = "listlbl";
      _ctrl("_aktzug_").className    = "aktzug";
      _ctrl("_zuege_").className     = "scrolldiv";

      _ctrl("_wortelbl_").className  = "listlbl";
      _ctrl("_worte_").className     = "scrolldiv";
   }
   else  {
      _ctrl("_aktzuglbl_").className = "listlbldis";
      _ctrl("_aktzug_").className    = "aktzugdis";
      _ctrl("_zuege_").className     = "scrolldivdis";

      _ctrl("_wortelbl_").className  = "listlbldis";
      _ctrl("_worte_").className     = "scrolldivdis";
   }
}

Status.prototype.status_funktionbar = function (starte=false,undo=false,tausche=false,fertig=false,veto=false) 
{
   dbg.switch(0);
   dbg.print("status_funktionsbar:" + starte + "," + undo + ","+ tausche + "," + fertig + "," + veto + " - Zug.idx:" + Zug.idx);
   dbg.switch(0);
   this.myButton("_starte_", starte);   
   this.myButton("_undo_", undo);   
   this.myButton("_tausche_", tausche);   
   this.myButton("_fertig_", fertig);
   if (spiel.VetoOption)   
      this.myButton("_veto_", veto);   
   else
      this.myButton("_veto_", false);   
}

Status.prototype.setControlStatus = function()
{
}

var statusO = new Status();