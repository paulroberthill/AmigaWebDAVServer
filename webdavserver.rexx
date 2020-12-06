/**************************************/
/* ARexx Web Server - Version 2.0     */
/* By Casey Halverson (1996)          */
/* Modified by Roger Clark (2004)     */
/* WEBDAV support by Paul Hill (2020) */
/**************************************/

/* 
TODO: 
- uploads
- deletes

USAGE:

Windows:
NET USE F: http://amiga

*/

SIGNAL ON ERROR 
SIGNAL ON FAILURE 
SIGNAL ON SYNTAX 

OPTIONS RESULTS
IF ~SHOW('L','rexxsupport.library') THEN addlib('rexxsupport.library',0,-30,0)

buffersize = 32768*1600		/* Increase this as high as you can! */
deffile = ""
logfile = "dav:webdavserver.log"
CRLF = "0D0A"x

CALL SetStatus
code = 200
depth = -1

volumes = SHOWLIST('V',,'|')'|'
/*CALL Log("===============================")*/

Call Open(In,"Console:","R")
  hostip = "0.0.0.0" ; agent = "Unknown" ; referer = "--"
  DO UNTIL EOF(In)
    data = ReadLn(In)
/*CALL Log(data)*/
    IF LENGTH(data) = 1 THEN leave
    IF INDEX(data,"GET") THEN parse var data method file protocol
    IF INDEX(data,"OPTIONS") THEN parse var data method file protocol
    IF INDEX(data,"PROPFIND") THEN parse var data method file protocol
    IF INDEX(data,"DELETE") THEN parse var data method file protocol
    IF INDEX(data,"Host:") THEN parse var data blah hostip
    IF INDEX(data,"User-Agent:") THEN parse var data blah agent
    IF INDEX(data,"Referer:") THEN parse var data blah referer
    IF INDEX(data,"Depth:") THEN DO
		parse var data blah depth
		depth = LEFT(STRIP(depth), LENGTH(depth)-2)
	END
  end
Call Close(In)

IF RIGHT(file,1)="/" THEN file = file||deffile
IF RIGHT(referer,1)="/" THEN referer = referer||deffile
IF INDEX(file,"//")~=0 | index(file,":") ~= 0 THEN code = 400

if lastpos(".",file) > 0 THEN do
	ext=upper(substr(file,lastpos(".",file),length(file)))
	call SetMime
end
else do
	ext=""
	mime="application/octet-stream"
end

IF method="OPTIONS" THEN DO
	SAY "HTTP/1.1 200 OK"
	SAY "Date: "||date()||" "||time()
	SAY "Server: ARexxWebServer/2.0"
	SAY "MicrosoftSharePointTeamServices: 12.0.2.6361"
	SAY "X-Powered-By: ASP.NET"
	SAY "MS-Author-Via: MS-FP/4.0,DAV"
	SAY "DAV: 1,2"
	SAY "Accept-Ranges: none"
	/*SAY "Allow: GET, OPTIONS, PROPFIND"*/
	SAY "Allow: GET, POST, OPTIONS, HEAD, MKCOL, PUT, PROPFIND, PROPPATCH, DELETE, MOVE, COPY, GETLIB, LOCK, UNLOCK"
	SAY "Cache-Control: private"
	SAY "Content-Length: 0"
	SAY "X-MSDAVEXT: 1"
	SAY "Public-Extension: http://schemas.fourthcoffee.com/repl-2"
	SAY ""
END

IF method="DELETE" THEN DO
/*
	SAY 'HTTP/1.1 404 Not Found'
	SAY "Server: ARexxWebServer/2.0"
	SAY "Date: "||date()||" "||time()
	SAY 'Content-Type: text/xml; charset="utf-8"'
	SAY ""
*/

	folder = ""
	volume = ""
	CALL GetFolder()
	
/*	CALL Log("[DELETE]" volume||folder)*/

	/* Is this a file or a folder? */
	stat = STATEF(volume||folder)
	IF LEFT(stat, 4) = "FILE" THEN DO
/*		CALL Log("[DELETE] FILE")*/
		ADDRESS COMMAND 'DELETE ' volume||folder
	END
	ELSE DO
/*		CALL Log("[DELETE] FOLDER")*/
		ADDRESS COMMAND 'DELETE ' volume||folder 'ALL'
	END




END

IF method="PROPFIND" THEN DO
	volume = ""
	folder = ""

	IF file="/" THEN DO
		/* Special case: show volume names */
		showvols = 1
		files = volumes
		folder = ""
		volume = ""
	END
	ELSE DO
		showvols = 0		
		folder = ""
		volume = ""

		CALL GetFolder()

		/* Is this a file or a folder? */
		/* FIXME: doesn't work if a space in the path */
		stat = STATEF(volume||folder)
		IF LEFT(stat, 4) = "FILE" THEN DO
			files = folder'|'
			folder = ""
		END
		ELSE DO
			files = SHOWDIR(volume||folder,'ALL','|')'|'
		END
	END
	
	IF volume="" & showvol=1 THEN DO
		SAY 'HTTP/1.1 404 Not Found'
		SAY "Server: ARexxWebServer/2.0"
		SAY "Date: "||date()||" "||time()
		SAY 'Content-Type: text/xml; charset="utf-8"'
		SAY ""
	END
	ELSE DO
		SAY 'HTTP/1.1 207 Multi-Status'
		SAY "Server: ARexxWebServer/2.0"
		SAY "Date: "||date()||" "||time()
		SAY 'Content-Type: text/xml; charset="utf-8"'
		/*SAY 'Content-Length: ' || LENGTH(reply)*/
		SAY ""
		SAY '<?xml version="1.0" encoding="utf-8" ?>'
	END
	
	filecount = 0 /* WIP */

	SAY '<D:multistatus xmlns:D="DAV:" xmlns:Z="urn:schemas-microsoft-com:">'
	SAY '  <D:response>'
	SAY '    <D:href>http://'||hostip||'/</D:href>'
	SAY '    <D:propstat>'
	SAY '      <D:prop>'
	SAY '        <D:creationdate>2020-01-01T00:00:00.000Z</D:creationdate>'
	SAY '        <D:displayname>temp</D:displayname>'
	SAY '        <D:getlastmodified>Mon, 01 Jan 2020 00:00:00 GMT</D:getlastmodified>'
	SAY '        <D:resourcetype>'
	SAY '          <D:collection />'
	SAY '        </D:resourcetype>'
	SAY '        <D:lockdiscovery />'
	SAY '        <D:supportedlock>'
	SAY '          <D:lockentry>'
	SAY '            <D:lockscope>'
	SAY '              <D:exclusive />'
	SAY '            </D:lockscope>'
	SAY '            <D:locktype>'
	SAY '              <D:write />'
	SAY '            </D:locktype>'
	SAY '          </D:lockentry>'
	SAY '          <D:lockentry>'
	SAY '            <D:lockscope>'
	SAY '              <D:shared />'
	SAY '            </D:lockscope>'
	SAY '            <D:locktype>'
	SAY '              <D:write />'
	SAY '            </D:locktype>'
	SAY '          </D:lockentry>'
	SAY '        </D:supportedlock>'
	SAY '        <D:childcount>'||filecount||'</D:childcount>'
	SAY '        <D:isfolder>1</D:isfolder>'
	SAY '        <D:ishidden>0</D:ishidden>'
	SAY '        <D:isstructureddocument>0</D:isstructureddocument>'
	SAY '        <D:hassubs>0</D:hassubs>'
	SAY '        <D:nosubs>0</D:nosubs>'
	SAY '        <D:objectcount>'||filecount||'</D:objectcount>'
	SAY '        <D:reserved>0</D:reserved>'
	SAY '        <D:visiblecount>'||filecount||'</D:visiblecount>'
	SAY '        <Z:Win32CreationTime>Mon, 01 Jan 2020 00:00:00 GMT</Z:Win32CreationTime>'
	SAY '        <Z:Win32LastAccessTime>Mon, 01 Jan 2020 00:00:00 GMT</Z:Win32LastAccessTime>'
	SAY '        <Z:Win32LastModifiedTime>Mon, 01 Jan 2020 00:00:00 GMT</Z:Win32LastModifiedTime>'
	SAY '        <Z:Win32FileAttributes>00000010</Z:Win32FileAttributes>'
	SAY '      </D:prop>'
	SAY '      <D:status>HTTP/1.1 200 OK</D:status>'
	SAY '    </D:propstat>'
	SAY '  </D:response>'

	IF depth=1 THEN DO	/* FIXME: don't like this check */
		IF showvols = 1 THEN DO
			/* Show volumes. We need to fake date/times */
			type = "DIR"
				
			date1 = DATE('STANDARD')
			date2 = DATE('NORMAL')
			weekday = "Fri"
			year = RIGHT(date2, 4)
			month = SUBSTR(date2, 4, 3)
			day = LEFT(date2, 2)
			nmonth = SUBSTR(date1, 5, 2)
			time = TIME()
			hours = SUBSTR(time, 1, 2)
			mins  = SUBSTR(time, 4, 2)
			secs  = SUBSTR(time, 7, 2)
			datetime = weekday||', '||day||' '||month||' '||year||' '||hours||':'||mins||':'||secs||' GMT'			
		END

		DO UNTIL INDEX(files,'|')==0
			PARSE VAR files fn'|'files

			webfn = fn
			IF POS(" ", fn) > 0 THEN DO		
				/* space to %20  */
				p = POS(" ", webfn)
				DO WHILE p > 0
					webfn = LEFT(webfn, p - 1)||"%20"||SUBSTR(webfn, p + 1)
					p = POS(" ", webfn)
				END
			END

			IF showvols = 0 THEN DO
				state = STATEF(volume||folder||fn)	  /* dh0:xx */

				IF state = "" THEN DO
					type = "ERR"
				END
					ELSE DO
					PARSE VAR state type length blocks protection days minutes ticks comment

					date1 = DATE('STANDARD',days)    /* 20011120 */
					date2 = DATE('NORMAL',days)	/* 01 Nov 2020*/
					weekday = LEFT(DATE('WEEKDAY',days), 3)	/* Friday */
					year = RIGHT(date2, 4)
					month = SUBSTR(date2, 4, 3)
					day = LEFT(date2, 2)
					nmonth = SUBSTR(date1, 5, 2)

					hours = RIGHT("0" || TRUNC(minutes/60), 2)
					mins  = RIGHT("0" || minutes//60, 2)
					secs  = RIGHT("0" || TRUNC(ticks/50), 2)
					
					datetime = weekday||', '||day||' '||month||' '||year||' '||hours||':'||mins||':'||secs||' GMT'
				END
			END

			IF type="DIR" & fn ~= "" THEN DO
/*CALL LOG("# PROPFIND [DIR]: webfn=" webfn)*/
				SAY '  <D:response>'
				SAY '    <D:href>http://'||hostip||'/'||webfn||'</D:href>'
				SAY '    <D:propstat>'
				SAY '      <D:prop>'
				SAY '        <D:creationdate>'||year||'-'||nmonth||'-'||day||'T'||hours||':'||mins||':'||secs||'.007Z</D:creationdate>'
				SAY '        <D:displayname>'||webfn||'</D:displayname>'
				SAY '        <D:getlastmodified>'||datetime||'</D:getlastmodified>'
				SAY '        <D:resourcetype>'
				SAY '          <D:collection />'
				SAY '        </D:resourcetype>'
				SAY '        <D:lockdiscovery />'
				SAY '        <D:supportedlock>'
				SAY '          <D:lockentry>'
				SAY '            <D:lockscope>'
				SAY '              <D:exclusive />'
				SAY '            </D:lockscope>'
				SAY '            <D:locktype>'
				SAY '              <D:write />'
				SAY '            </D:locktype>'
				SAY '          </D:lockentry>'
				SAY '          <D:lockentry>'
				SAY '            <D:lockscope>'
				SAY '              <D:shared />'
				SAY '            </D:lockscope>'
				SAY '            <D:locktype>'
				SAY '              <D:write />'
				SAY '            </D:locktype>'
				SAY '          </D:lockentry>'
				SAY '        </D:supportedlock>'
				SAY '        <D:childcount>0</D:childcount>'
				SAY '        <D:isfolder>1</D:isfolder>'
				SAY '        <D:ishidden>0</D:ishidden>'
				SAY '        <D:isstructureddocument>0</D:isstructureddocument>'
				SAY '        <D:hassubs>0</D:hassubs>'
				SAY '        <D:nosubs>0</D:nosubs>'
				SAY '        <D:objectcount>0</D:objectcount>'
				SAY '        <D:reserved>0</D:reserved>'
				SAY '        <D:visiblecount>0</D:visiblecount>'
				SAY '        <Z:Win32CreationTime>'||datetime||'</Z:Win32CreationTime>'
				SAY '        <Z:Win32LastAccessTime>'||datetime||'</Z:Win32LastAccessTime>'
				SAY '        <Z:Win32LastModifiedTime>'||datetime||'</Z:Win32LastModifiedTime>'
				SAY '        <Z:Win32FileAttributes>00000010</Z:Win32FileAttributes>'
				SAY '      </D:prop>'
				SAY '      <D:status>HTTP/1.1 200 OK</D:status>'
				SAY '    </D:propstat>'
				SAY '  </D:response>'
			END
			IF type="FILE" THEN DO
/*CALL LOG("# PROPFIND [FILE]: webfn=" webfn)*/
				SAY '  <D:response>'
				SAY '    <D:href>http://'||hostip||'/'||webfn'</D:href>'
				SAY '    <D:propstat>'
				SAY '      <D:prop>'
				SAY '        <D:creationdate>'||year||'-'||nmonth||'-'||day||'T'||hours||':'||mins||':'||secs||'.007Z</D:creationdate>'
				SAY '        <D:displayname>'||webfn||'</D:displayname>'
				SAY '        <D:getcontentlength>'||length||'</D:getcontentlength>'
				SAY '        <D:getcontenttype>application/octet-stream</D:getcontenttype>'
				SAY '        <D:getlastmodified>'||datetime||'</D:getlastmodified>'
				SAY '        <D:resourcetype />'
				SAY '        <D:lockdiscovery />'
				SAY '        <D:supportedlock>'
				SAY '          <D:lockentry>'
				SAY '            <D:lockscope>'
				SAY '              <D:exclusive />'
				SAY '            </D:lockscope>'
				SAY '            <D:locktype>'
				SAY '              <D:write />'
				SAY '            </D:locktype>'
				SAY '          </D:lockentry>'
				SAY '          <D:lockentry>'
				SAY '            <D:lockscope>'
				SAY '              <D:shared />'
				SAY '            </D:lockscope>'
				SAY '            <D:locktype>'
				SAY '              <D:write />'
				SAY '            </D:locktype>'
				SAY '          </D:lockentry>'
				SAY '        </D:supportedlock>'
				SAY '        <D:ishidden>0</D:ishidden>'
				SAY '        <Z:Win32CreationTime>'||datetime||'</Z:Win32CreationTime>'
				SAY '        <Z:Win32LastAccessTime>'||datetime||'</Z:Win32LastAccessTime>'
				SAY '        <Z:Win32LastModifiedTime>'||datetime||'</Z:Win32LastModifiedTime>'
				SAY '        <Z:Win32FileAttributes>00000020</Z:Win32FileAttributes>'
				SAY '      </D:prop>'
				SAY '      <D:status>HTTP/1.1 200 OK</D:status>'
				SAY '    </D:propstat>'
				SAY '  </D:response>'
			END
		END
	END
	SAY '</D:multistatus>'
END

IF method="GET" THEN do
	folder = ""
	volume = ""
	CALL GetFolder()

	IF ~EXISTS(volume||folder) THEN DO
		code = 404
	END
	ELSE DO
		code = 200
	END
	
	IF RIGHT(folder, 1) = "/" THEN DO
		code = 404
	END

	SAY "HTTP/1.1 "code||" "||status.code
	SAY "Server: ARexxWebServer/2.0"
	SAY "Date: "||date()||" "||time()
	SAY "Accept-ranges: bytes"
	SAY "Content-length: "||subword(statef(volume||folder),2,1)
	SAY "Content-type: "||mime
	SAY ""

	IF code = 200 THEN DO
	  call open(in,volume||folder,'r')
	  call open(out,'Console:','w')
/*CALL LOG("start" volume||folder TIME())*/
	  do until eof(in)
		a=readch(in,buffersize)
		call writech(out,a)
	  end
/*CALL LOG("end" volume||folder TIME())*/
	  call close(in)
	  call close(out)
	END
END
EXIT

SetMime:
Select
  when ext=".ARC"    THEN mime="application/octet-stream"
  when ext=".ARJ"    THEN mime="application/octet-stream"
  when ext=".DMS"    THEN mime="application/octet-stream"
  when ext=".EXE"    THEN mime="application/octet-stream"
  when ext=".LHA"    THEN mime="application/octet-stream"
  when ext=".LZH"    THEN mime="application/octet-stream"
  when ext=".LZX"    THEN mime="application/octet-stream"
  when ext=".ZIP"    THEN mime="application/octet-stream"
  when ext=".ZOO"    THEN mime="application/octet-stream"
  when ext=".PDF"    THEN mime="application/pdf"
  when ext=".PS"     THEN mime="application/postscript"
  when ext=".SWF"    THEN mime="applicaiton/x-shockwave-flash"
  when ext=".MP2"    THEN mime="audio/mpeg2"
  when ext=".MP3"    THEN mime="audio/mpeg3"
  when ext=".GSM"    THEN mime="audio/x-gsm"
  when ext=".GSD"    THEN mime="audio/x-gsm"
  when ext=".MID"    THEN mime="audio/x-midi"
  when ext=".MIDI"   THEN mime="audio/x-midi"
  when ext=".RAM"    THEN mime="audio/x-realaudio"
  when ext=".RM"     THEN mime="audio/x-realaudio"
  when ext=".WAV"    THEN mime="audio/x-wav"
  when ext=".GIF"    THEN mime="image/gif"
  when ext=".JPG"    THEN mime="image/jpeg"
  when ext=".JPEG"   THEN mime="image/jpeg"
  when ext=".JPE"    THEN mime="image/jpeg"
  when ext=".JP2"    THEN mime="image/jpeg"
  when ext=".PNG"    THEN mime="image/png"
  when ext=".HTML"   THEN mime="text/html"
  when ext=".HTM"    THEN mime="text/html"
  when ext=".HML"    THEN mime="text/html"
  when ext=".DOC"    THEN mime="text/plain"
  when ext=".README" THEN mime="text/plain"
  when ext=".TXT"    THEN mime="text/plain"
  when ext=".GUIDE"  THEN mime="text/x-amigaguide"
  when ext=".AVI"    THEN mime="video/msvideo"
  when ext=".WMV"    THEN mime="video/msvideo"
  when ext=".MOV"    THEN mime="video/quicktime"
  when ext=".QT"     THEN mime="video/quicktime"
  when ext=".MPEG"   THEN mime="video/mpeg"
  when ext=".MPG"    THEN mime="video/mpeg"

  otherwise mime="text/html"
end
return

SetStatus:
  status.200 = "OK"
  status.201 = "Created"
  status.202 = "Accepted"
  status.203 = "Partial Information"
  status.204 = "No Response"
  status.301 = "Moved"
  status.302 = "Found"
  status.303 = "Method"
  status.304 = "Not Modified"
  status.400 = "Bad Request"
  status.401 = "Unauthorized"
  status.402 = "Payment Required"
  status.403 = "Forbidden"
  status.404 = "Not Found!"
  status.500 = "Internal Error"
  status.501 = "Not Implemented"
  status.502 = "Service Temporarilty Overloaded"
  status.503 = "Gateway Timeout"
return


Log:
parse arg filename
if logfile~="" THEN do
  if exists(logfile) THEN call open(log,logfile,"a")
  else call open(log,logfile,"w")
/* call writeln(log,date() time() method filename code hostip agent referer) */
    call writeln(log,filename)
  call close(log)
end
return

/*
Converts a URL to a valid Amiga volume / folder
*/
GetFolder:
	/* Special cases */
	IF file = "/AutoRun.inf" | file = "/Desktop.ini" THEN DO
		SAY 'HTTP/1.1 404 Not Found'
		SAY "Server: ARexxWebServer/2.0"
		SAY "Date: "||date()||" "||time()
		SAY 'Content-Type: text/xml; charset="utf-8"'
		SAY ""
		RETURN
	END
	
	/* %20 to space */
	p = POS("%20", file)
	DO WHILE p > 0
		file = LEFT(file, p - 1)||" "||SUBSTR(file, p + 3)
		p = POS("%20", file)
	END
	
	file2 = SUBSTR(file, 2)
	pos = POS("/", file2)

	IF pos=0 THEN DO
		/* /dh0 => dh0: */
		volume = file2
		folder = ""
	END
	ELSE DO
		/* /dh0/xxx => dh0:xxx */
		volume = LEFT(file2, pos-1)
		folder = SUBSTR(file2, pos+1)
	END

	IF volume = "" THEN DO
		volume = "SYS:"
		folder = "index.html"
	END
	ELSE DO
		/* Check volume is valid */
		volpos = POS(UPPER(volume)||"|", volumes)
		IF volpos > 0 THEN DO
			volume = volume':'	
			state = STATEF(volume||folder)
			IF folder ~= "" THEN DO
				IF LEFT(state, 3) = "DIR" THEN folder=folder'/'
			END
		END
		ELSE DO
			CALL LOG("ERROR: Invalid volume" volume)
			CALL LOG(file2)
			folder = ""
			volume = ""
		END
	END
	
/*
	CALL LOG("GetFolder: volume=" volume)
	CALL LOG("GetFolder: folder=" folder)
*/

RETURN
