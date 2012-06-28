function keyEnter(event, func, args)
{
   if(event.keyCode == 13) {
      func.apply(null,args);
      document.getElementById('input').value = '';
   }
}
