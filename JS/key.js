function keyEnter(event, func, args)
{
   // Test for "enter" key
   if(event.keyCode == 13) {
      func.apply(null,args);
      document.getElementById('input').value = '';
   }
}
