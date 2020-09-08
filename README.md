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
- CGI, CGI::Carp and Net::SMTP to write emails.


Installation.
-------------
Unzip the files, create the sub folders  'data' and 'dbgfiles'.<br/>

If the folder name is different from 'scrabDev', you have to adapt the files.
; The varible '<b>BASEURL</b>' in 
: spiel3.cgi
: spiel3.2.js<br>
; The variable '<b>HOMEDIR</b>' in 
: FScrabMulti.pm
: FScrabSpieler.pm


How to play scrabble ?
----------------------
See  
https://en.wikipedia.org/wiki/Scrabble  .
https://de.wikipedia.org/wiki/Scrabble  .


For problems/hints - write me an email: 
fiversen 'At sign' wedding.in-berlin.de
