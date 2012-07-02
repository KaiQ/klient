klient
======

javascript websocket chat client
combined with 
lisp websocket chat server




### Metaprotocol [to Server]:


- TXT <name>      - chat message
- CON <name>      - new connected user
- USR <newName>   - name change



### Metaprotocol [from Server]:

- TXT <name> <txt>         - chat message
- CON <name>               - new connected user
- USR <newName> <oldName>  - name change
- DIS <name>               - name has disconnected
- ERR <txt>                - error message
