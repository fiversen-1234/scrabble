//spiel3controlfuncs.js
// - nur die controlfuncs für das setzen
import {Zug, ZugI, MaxZug} from './spiel3.js';


//-- neues Spiel
//   erstes Wort geht durch die mitte ?
function durch_die_mitte()
{
   var mitte=0;
   var i = 0;
   for (i = 0; i<ZugI; i=i+1) {
      if (8==Zug[i][0]  &&  8==Zug[i][1]) {
            mitte = 1;
         } 
   }
   return mitte;
}

//-- hat das feld einen buchstaben und 
//  ist nicht im aktuellen zug
function ist_feld_alt(x,y)
{
   var b = get_buchstabeBrett(x,y);
   //dbg("ist_feld_alt:" + x + "," + y + " b:" + b);
   if (b == ".") {
      //dbg("- kein buchstabe");
      return false;
   }
   else {
      var i = 0;
      for (i = 0; i<ZugI; i=i+1) {
         if (x==Zug[i][0]  &&  y==Zug[i][1]) {
               //dbg("--Zug i:" + i);
               return false;   
            } 
      }
   }
   return true; 
}

function control_zug ()
{
   var i   = 0;
   var str = "";
   for (i = 0; i<ZugI; i=i+1) {
      str = str + i + ")" + Zug[i][0] + "," + Zug[i][1] + "-" + Zug[i][2] + " ";
   }
   dbg_switch(0);
   dbg("--------------control_zug:" + ZugI);
   dbg("-" + str);

   // neues Spiel
   // - nur test auf mitte
   var neuesspiel = neues_spiel();
   var mitte = (neuesspiel) ? durch_die_mitte(): 0;
   dbg("-neues Spiel: " + neuesspiel + " mitte:" + mitte);

   if (neuesspiel==1 && mitte==0)  {
      ShowDlg("Fehler: erster Zug nicht durch die Mitte!")
      return 0;
   }

   // eine richtung ?
   var minX = 100;
   var maxX = -1;
   var minY = 100;
   var maxY = -1;
   for (i = 0; i<ZugI; i=i+1) {
      if (Zug[i][0] > maxX)  maxX = Zug[i][0];   
      if (Zug[i][0] < minX)  minX = Zug[i][0];
      if (Zug[i][1] > maxY)  maxY = Zug[i][1];   
      if (Zug[i][1] < minY)  minY = Zug[i][1];
   }
   var einerichtung = 0;
   if (minX == maxX)
      einerichtung = 1;
   if (minY == maxY)
      einerichtung = 1;
   dbg("- min max X:" + minX + "," + maxX  + "  Y:" +  minY + "," + maxY + 
         " einerichtung:" + einerichtung);

   if (einerichtung == 0)  {
      ShowDlg("Fehler: neuen Zug nicht nur an einem Wort!");
      return 0;
   }
   // zusammenhaengend ?
   var zusammen = 1;
   if (minX == maxX) {
      var x = minX;
      var y = minY;
      for (; y < maxY; y = y +1)  {    // von anfang bis ende
         if (get_buchstabeBrett(x,y) == ".") 
            zusammen = 0;
      }
   }   
   if (minY == maxY) {
      var x = minX;
      var y = minY;
      for (; x < maxX; x = x +1)  {    // von anfang bis ende
         if (get_buchstabeBrett(x,y) == ".") 
            zusammen = 0;
      }
   }   
   dbg("- zusammen:" + zusammen);
   if (zusammen==0)  {
      ShowDlg("Fehler: kein zusammenhaengendes Wort!");
      return 0;
   }

   if (neuesspiel==1)  //beim neuen spiel - nur zusammenhalt ?
      return 1;   

   // am wortgerüst
   //    ein buchstabe des zuges
   //    muss ein nachbarn des alten Gerüsts haben 
   var alt = 0;
   for (i = 0; i<ZugI; i=i+1) {
      if (minX == maxX) // wort in x-richtung
      {
         dbg("-alt in x-richtung: min,max x:" + minX + "," + maxX);
         var uX = 0;
         var uY = 0;
         // wort-gerade und parallele davon
         //     ?????
         //     xxxxx
         //     ?????
         for (uX=minX-1; 
               uX<=(minX +1) && alt==0; 
               uX=uX+1) {
            for (uY = minY; uY<=maxY && alt==0; uY=uY+1)  {    // von anfang bis ende
               dbg("-x/y-alt:." + uX + "," + uY);                  
               if (uX>0 && uX<16 && ist_feld_alt(uX, uY)) {
                  dbg("-x/y-alt:.! " + uX + "," + uY);                  
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
            dbg("-x/y-alt:.." + uX + "," + uY);                  
            if (uY>0 && ist_feld_alt(uX, uY)) {
               dbg("-x/y-alt:..! " + uX + "," + uY);                  
               alt = 1;
            }
         }
         if (alt == 0) {
            uX = minX;
            uY = maxY+1;
            dbg("-x/y-alt:..." + uX + "," + uY);                  
            if (uY<16 && ist_feld_alt(uX, uY)) {
               dbg("-x/y-alt:...! " + uX + "," + uY);                  
               alt = 1;
            }
         }
      }
      if (minY == maxY) {     // wort in y-richtung
         dbg("-alt in y-richtung: min,max y:" + minY + "," + maxY);
         var uX = 0;
         var uY = 0;
         for (uY=minY-1; 
            uY<=(minY +1) && alt==0; 
            uY=uY+1) {
            for (uX = minX; uX<=maxX && alt==0; uX=uX+1)  {    // von anfang bis ende
               dbg("-x/y-alt:." + uX + "," + uY);                  
               if (uY>0 && uY<16 && ist_feld_alt(uX, uY)) {
                  dbg("-y-alt:.! " + uX + "," + uY);                  
                  alt = 1;
               }
            }
         }
         if (alt == 0) {
            uX = minX-1;
            uY = minY;
            dbg("-x/y-alt:.." + uX + "," + uY);                  
            if (uX>0 && ist_feld_alt(uX, uY)) {
               dbg("-x/y-alt:..! " + uX + "," + uY);                  
               alt = 1;
            }
         }
         if (alt == 0) {
            uX = maxX+1;
            uY = maxY;
            dbg("-x/y-alt:..." + uX + "," + uY);                  
            if (uX<16 && ist_feld_alt(uX, uY)) {
               dbg("-x/y-alt:...! " + uX + "," + uY);                  
               alt = 1;
            }
         }
     }
   }
   dbg("- alt:" + alt);
   dbg_switch(0);

   if (alt == 0) {
      ShowDlg("Fehler: nicht am bestehenden Wortgeruest!");
      return 0;
   }

   return alt;
}
