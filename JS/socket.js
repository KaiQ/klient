function socket()
{
  if (typeof(ws) != "undefined")
     return;

  if ("WebSocket" in window)
  {


	  ws = new WebSocket("ws://" + 
                        document.getElementById('ip').value + 
                        ":" + 
                        document.getElementById('port').value + 
                        "/chat");


     
     ws.onerror = function(error) 
     {
		  alert("fehler");
	  };


    
     ws.onopen = function(evt)
     {
        ws.send("CON " + document.getElementById('name').value);
     };



     ws.onmessage = function(evt)
     { 
        var split = evt.data.split(" ");
        var selec = document.getElementById('select');
        var out = document.getElementById('output');

        var mapping = {
            CON: onCON,
            USR: onUSR,
            TXT: onTXT,
            DIS: onDIS,
            ERR: onERR
        };

        mapping[split[0]](selec, out, split);
     };



     ws.onclose = function(evt)
     { 
        if (typeof(ws) == "undefined")
           return;
        var i;
        while(document.getElementById('select').length > 0) 
            document.getElementById('select').remove(0);
        document.getElementById('output').value += '\ndisconnected';
        delete(ws);
     };

  }
  else
  {
     document.getElementById('output').value = 'WebSocket NOT supported by your Browser!';
  }
}
