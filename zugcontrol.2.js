//  zugcontrol.2.js
//

/////////////////////////////////////////////////////////// Kontrolle der neuen Buchstaben

function ZugControl() {    
}

//-- Spiel neu 
//   kein Spieler hat einen Punkt
ZugControl.prototype.neues_spiel = function()
{
   let s1 = _ctrl("_spieler1_").innerHTML;                  
   let s2 = _ctrl("_spieler2_").innerHTML;                  
   let s3 = _ctrl("_spieler3_").innerHTML;                  
   let s4 = _ctrl("_spieler4_").innerHTML;                  
   let neu = 1;
   dbg.print("neues_spiel:" + s1 + "##" + s2 + "##" + s3 + "##" + s4 + "##");
   dbg.print("--:" + s1.length + "##" + s2.length + "##" + s3.length + "##" + s4.length + "##");
   dbg.print("--:" + s1.search(",0") + "##" + s2.search(",0") + "##" + s3.search(",0") + "##" + s4.search(",0") + "##");
   if (s1 != ".")
      if (s1.search(",0") == -1)  neu = 0;
   if (s2 != ".")
      if (s2.search(",0") == -1)  neu = 0; 
   if (s3 != ".")
      if (s3.search(",0") == -1)  neu = 0; 
   if (s4 != ".")
      if (s4.search(",0") == -1)  neu = 0; 
   return neu;
}

//-- neues Spiel
//   erstes Wort geht durch die mitte ?
ZugControl.prototype.durch_die_mitte = function()
{
   let mitte=0;
   let i = 0;
   for (i = 0; i<Zug.idx; i=i+1) {
      if (8==Zug.arr[i][0]  &&  8==Zug.arr[i][1]) {
            mitte = 1;
         } 
   }
   return mitte;
}

//-- hat das feld einen buchstaben und 
//  ist nicht im aktuellen zug
ZugControl.prototype.ist_feld_alt = function(x,y)
{
   let b = brettO.get_buchstabeBrett(x,y);
   //dbg.print("ist_feld_alt:" + x + "," + y + " b:" + b);
   if (b == ".") {
      //dbg.print("- kein buchstabe");
      return false;
   }
   else {
      let i = 0;
      for (i = 0; i<Zug.idx; i=i+1) {
         if (x==Zug.arr[i][0]  &&  y==Zug.arr[i][1]) {
               //dbg.print("--Zug i:" + i);
               return false;   
            } 
      }
   }
   return true; 
}

ZugControl.prototype.control_zug = function ()
{
   let i   = 0;
   let str = "";
   for (i = 0; i<Zug.idx; i=i+1) {
      str = str + i + ")" + Zug.arr[i][0] + "," + Zug.arr[i][1] + "-" + Zug.arr[i][2] + " ";
   }
   dbg.switch(0);
   dbg.print("--------------control_zug:" + Zug.idx);
   dbg.print("-" + str);

   // neues Spiel
   // - nur test auf mitte
   let neuesspiel = this.neues_spiel();
   let mitte = (neuesspiel) ? this.durch_die_mitte(): 0;
   dbg.print("-neues Spiel: " + neuesspiel + " mitte:" + mitte);

   if (neuesspiel==1 && mitte==0)  {
      dlgO.ShowDlg("Fehler: erster Zug nicht durch die Mitte!")
      return 0;
   }

   // eine richtung ?
   let minX = 100;
   let maxX = -1;
   let minY = 100;
   let maxY = -1;
   for (i = 0; i<Zug.idx; i=i+1) {
      if (Zug.arr[i][0] > maxX)  maxX = Zug.arr[i][0];   
      if (Zug.arr[i][0] < minX)  minX = Zug.arr[i][0];
      if (Zug.arr[i][1] > maxY)  maxY = Zug.arr[i][1];   
      if (Zug.arr[i][1] < minY)  minY = Zug.arr[i][1];
   }
   let einerichtung = 0;
   if (minX == maxX)
      einerichtung = 1;
   if (minY == maxY)
      einerichtung = 1;
   dbg.print("- min max X:" + minX + "," + maxX  + "  Y:" +  minY + "," + maxY + 
         " einerichtung:" + einerichtung);

   if (einerichtung == 0)  {
      dlgO.ShowDlg("Fehler: neuen Zug nicht nur an einem Wort!");
      return 0;
   }
   // zusammenhaengend ?
   let zusammen = 1;
   if (minX == maxX) {
      let x = minX;
      let y = minY;
      for (; y < maxY; y = y +1)  {    // von anfang bis ende
         if (brettO.get_buchstabeBrett(x,y) == ".") 
            zusammen = 0;
      }
   }   
   if (minY == maxY) {
      let x = minX;
      let y = minY;
      for (; x < maxX; x = x +1)  {    // von anfang bis ende
         if (brettO.get_buchstabeBrett(x,y) == ".") 
            zusammen = 0;
      }
   }   
   dbg.print("- zusammen:" + zusammen);
   if (zusammen==0)  {
      dlgO.ShowDlg("Fehler: kein zusammenhaengendes Wort!");
      return 0;
   }

   if (neuesspiel==1)  //beim neuen spiel - nur zusammenhalt ?
      return 1;   

   // am wortgerüst
   //    ein buchstabe des zuges
   //    muss ein nachbarn des alten Gerüsts haben 
   let alt = 0;
   for (i = 0; i<Zug.idx; i=i+1) {
      if (minX == maxX) // wort in x-richtung
      {
         dbg.print("-alt in x-richtung: min,max x:" + minX + "," + maxX);
         let uX = 0;
         let uY = 0;
         // wort-gerade und parallele davon
         //     ?????
         //     xxxxx
         //     ?????
         for (uX=minX-1; 
               uX<=(minX +1) && alt==0; 
               uX=uX+1) {
            for (uY = minY; uY<=maxY && alt==0; uY=uY+1)  {    // von anfang bis ende
               dbg.print("-x/y-alt:." + uX + "," + uY);                  
               if (uX>0 && uX<16 && this.ist_feld_alt(uX, uY)) {
                  dbg.print("-x/y-alt:.! " + uX + "," + uY);                  
                  alt = 1;
               }
            }
         }
         // rand felder
         //     .....
         //    ?xxxxx?
         //     .....
         if (alt == 0) {
            uX = minX;
            uY = minY-1;
            dbg.print("-x/y-alt:.." + uX + "," + uY);                  
            if (uY>0 && this.ist_feld_alt(uX, uY)) {
               dbg.print("-x/y-alt:..! " + uX + "," + uY);                  
               alt = 1;
            }
         }
         if (alt == 0) {
            uX = minX;
            uY = maxY+1;
            dbg.print("-x/y-alt:..." + uX + "," + uY);                  
            if (uY<16 && this.ist_feld_alt(uX, uY)) {
               dbg.print("-x/y-alt:...! " + uX + "," + uY);                  
               alt = 1;
            }
         }
      }
      if (minY == maxY) {     // wort in y-richtung
         dbg.print("-alt in y-richtung: min,max y:" + minY + "," + maxY);
         let uX = 0;
         let uY = 0;
         for (uY=minY-1; 
            uY<=(minY +1) && alt==0; 
            uY=uY+1) {
            for (uX = minX; uX<=maxX && alt==0; uX=uX+1)  {    // von anfang bis ende
               dbg.print("-x/y-alt:." + uX + "," + uY);                  
               if (uY>0 && uY<16 && this.ist_feld_alt(uX, uY)) {
                  dbg.print("-y-alt:.! " + uX + "," + uY);                  
                  alt = 1;
               }
            }
         }
         if (alt == 0) {
            uX = minX-1;
            uY = minY;
            dbg.print("-x/y-alt:.." + uX + "," + uY);                  
            if (uX>0 && this.ist_feld_alt(uX, uY)) {
               dbg.print("-x/y-alt:..! " + uX + "," + uY);                  
               alt = 1;
            }
         }
         if (alt == 0) {
            uX = maxX+1;
            uY = maxY;
            dbg.print("-x/y-alt:..." + uX + "," + uY);                  
            if (uX<16 && this.ist_feld_alt(uX, uY)) {
               dbg.print("-x/y-alt:...! " + uX + "," + uY);                  
               alt = 1;
            }
         }
     }
   }
   dbg.print("- alt:" + alt);
   dbg.switch(0);

   if (alt == 0) {
      dlgO.ShowDlg("Fehler: nicht am bestehenden Wortgeruest!");
      return 0;
   }

   return alt;
}

var zugControlO = new ZugControl();