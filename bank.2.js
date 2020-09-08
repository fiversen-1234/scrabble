// bank.2.js
//

function Bank() {
}


Bank.prototype.bank_belegung = function()
{
   let i;
   let ret = "";
   for (i = 0; i < 7; i++) 
   {
      let b = this.get_bankbuchstabe(i);
      if (b != ".")
         ret = ret + b;
   }
   if (ret == "")
      ret = "-";

   return ret;
}

Bank.prototype.get_bankbuchstabe = function(x)
{
   //table field
   let fname  = "_bank_" + x + "_";
   let fnameI = "_bank_" + x + "_i";
   let f     = _ctrl(fname);
   let fI    = _ctrl(fnameI);
   return fI.name;
}

Bank.prototype.set_bankbuchstabe = function(letter, x, mark=0)
{
   let fname  = "_bank_" + x + "_";
   let fnameI = "_bank_" + x + "_i";
   let f     = _ctrl(fname);
   let fI    = _ctrl(fnameI);
 
   dbg.switch(0);
   dbg.print("set_bankBuchstabe:" + fname + ", " + fnameI + ", "+ letter);
   dbg.switch(0);
   fI.src = steinO.svg_inline_img(letter, mark);
   fI.name = letter;
   let old = f.className;
   fI.title = steinO.buchstabe_wert(letter);
   return old;
}

var bankO = new Bank();