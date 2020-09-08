// dlg2.js
//

function Dlg() {
}

Dlg.prototype.ShowDlg = function (text, title="Meldung", dim="normal", inp="0")
{
   //alert(text);  //simple
   let dlgtitle  = _ctrl('_dlgtitle_');
   let dlgtext   = _ctrl('_dlgtext_');
   let dlginput  = _ctrl('_dlginput_');
   let dlg       = _ctrl('dlg');
   let butok     = _ctrl('_dlgok_');
   let butcancel = _ctrl('_dlgcancel_');

   dlgtitle.innerHTML = title;
   dlgtext.innerHTML = text;

   //let html5 = 0;
   //dlg.show();  //html5

   dlginput.style.visibility = (inp == "1") ? 'visible' : 'hidden';
   butcancel.style.visibility = (inp == "1") ? 'visible' : 'hidden';

   dlg.className = (dim == "normal") ? 'overlay' : 'overlayBig';   //normal - big
   butok.className = (dim == "normal") ? 'likebut' : 'likebutBig';
   //if (html5 == 1)  dlg.show();
}

Dlg.prototype.HideDlg = function ()
{
    let dlg = _ctrl('dlg');
    dlg.className = 'overlayHidden';   //html
    //if (html5 == 1)   dlg.close();     //html5
    act.DlgType   = "";
}

Dlg.prototype.myDlgFunc = function()
{
   let dlg = _ctrl('dlg');
   let html5 = 0;

   if (act.DlgType == "speichern") {
        let inp = _ctrl('_dlginput_');
        let passwd = inp.value;
        if (passwd.length < 4) {
            this.ShowDlg(txtSpeichernDlg, "Speicherung des Spiels", "normal", "1");
        }
        else {
            ajMulti("speichern", spiel.SpielId, spiel.Spieler, passwd);
            this.HideDlg();
        }
   }
   else if (act.DlgType == "laden") {
      let passwd     = _ctrl('_dlginput_').value;
      let spieler    = _ctrl('_spieler_').value;
      let seloption  = get_stored_select();  

      if (spieler.length > 0     &&  passwd.length > 0  &&  
          seloption.length > -1  &&  seloption.search(spieler) > -1) {
         ajMulti("laden", 0, spieler, passwd, seloption);
         this.HideDlg();
      }
      else {
         let text = "<br/>";
         if (spieler.length == 0)   text  += "Spieler - angeben!<br/>";
         if (passwd.length  == 0)   text  += "Passwort - angeben!<br/>";
         if (seloption.length == 0) text  += "gespeich.Spiel selektieren!<br/>";
         if (seloption.search(spieler) == -1)  text += "Spieler nicht im gesp.Spiel!<br/>";

         this.ShowDlg(txtLadenDlg + text, "Laden eines gespeicherten Spiels", "normal", "1");
      }
   }
   else {
      this.HideDlg();   
   } 
}

Dlg.prototype.myDlgCancel = function()
{
   this.HideDlg();   
}


var dlgO = new Dlg();

function setdlgfuncs()  {
   /*
   var b = _ctrl('_dlgok_');
   b.addEventListener('click', dlgO.myDlgFunc);
   b = _ctrl('_dlgcancel_');
   b.addEventListener('click', dlgO.myDlgCancel);
   */
}