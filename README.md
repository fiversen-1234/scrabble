# scrabble
online multiuser scrabble

scrab  - multiuser - online - scrabble
--------------------------------------

'scrab' is an mulituser online scrabble.
This version works with german characters set.

The players needs only an connection to the webserver, 
on which scrab runs.
Preconditions for the browser is only to display svg-grafics.


Precondtions of the webserver
directory structure like 
- 'scrab'
- 'scrab/data'
- 'scrab/dbgfiles'

The name 'scrab' is freely selectable.

The webserver needs to run  perl scripts.
It runs with perl version 5.
It needs the packages 
'CGI', 'CGI::Carp' and 'Net::SMTP' to write emails.


Installation.
-------------
Unzip the files, create the sub folders  'data' and 'dbgfiles'.<br/>

If the folder name is different from 'scrab', you have to adapt the files.
* The varible '<b>BASEURL</b>' in  'spiel3.cgi', 'spiel3.2.js'<br>
* The variable '<b>HOMEDIR</b>' in 'FScrabMulti.pm', 'FScrabSpieler.pm'.


How to play scrabble ?
----------------------
'scrabble' is played with 2 to 4 players.

The first player has to call your website,
for example https://test123/scrabble.html

In the registration dialog, the player enters his name and 
invites up to 3 other players via email.

The players receive emails with a 'link' to the Scrabble website.
With this link you can take part in the common game.
Each player registers on the website.
If everyone is logged in - one, ideally the initiator, starts the
Game.
Each player receives his stones - the game begins.

The rules of 'scrabble' see  
https://en.wikipedia.org/wiki/Scrabble ,
https://de.wikipedia.org/wiki/Scrabble  .


For problems/hints - write me an email: 
fiversen 'At sign' wedding.in-berlin.de
