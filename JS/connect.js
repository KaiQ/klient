function post(out, str)
{
   out.value += '\n' + str;
   out.scrollTop = out.scrollHeight;
}


function connect(selec, out, field)
{
   var opt = document.createElement('option');
   opt.text = field[1];
   selec.add(opt);
   post(out, field[1] + " has connected");
}


function addUser(selec, out, field)
{
   var i;
   for(i=0; y<selec.length; i++)
      if (selec.options[i].text == field[2])
         selec.options[i].text = split[1];
   post(out, "<" + field[2] + "> changed name to <" + field[1] + ">");
}

function disconnect(selec, out, field)
{
   var i;
   for(i=0; i<select.length; i++)
      if(selec.optins[i].text == field[1])
         selec.options[i] = null;
   post(out, field[1]+ " has disconnected");
}


function error(out, txt, field)
{
   post(out, field.join(' '));
   ws.close(4001, "Error");
}
