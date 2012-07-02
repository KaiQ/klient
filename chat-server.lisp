; loading the clws websocket server implementation
(ql:quickload "clws")

; loading the clws.asdf packet from github repo ... optional
;(asdf:operate 'asdf:load-op 'clws)

(defpackage #:chat
  (:use :cl :clws))

(in-package #:chat)

;;;; chat server
;;;; -----------
(setf *debug-on-server-errors*   nil
      *debug-on-resource-errors* nil)

; defining chat class
;   adding clients list to save connected clients
;   accessable per (clients <chat-reource-object>)
(defclass chat-resource (ws-resource)
  ((clients :initform () :accessor clients)))

(register-global-resource
 "/chat"
 (make-instance 'chat-resource)
 (ws::origin-prefix "http://127.0.0.1" "http://localhost" "null"))


;;; defining handler methods to chat-resource class

; onAccept method
(defmethod resource-accept-connection ((res chat-resource) resource-name headers client)
  (declare (ignore headers resource-name))
  (format t "~%got[2] connection on chat server from ~s : ~s" (client-host client) (client-port client))
  t)

; onConnect method
(defmethod resource-client-connected ((res chat-resource) client)
  (format t "~%got connection on chat server from ~s : ~s" (client-host client) (client-port client))
  t)


; onDisconnect method
(defmethod resource-client-disconnected ((res chat-resource) client)
  (let ((name (cdr (assoc client (clients res)))))
      (setf (clients res) (remove client (clients res) :key #'car))
      (if name 
         (write-to-clients-text (mapcar #'car (clients res)) (concatenate 'string "DIS " name))))
  (format t "~%Client disconnected from resource ~A: ~A" res client))


; onMessage method
(defmethod resource-received-text ((res chat-resource) client message)
  (format t "~%got frame ~s from client ~s" message client)
  (when (string= message "error")
    (error "~2%got \"error\" message~2%"))
  (let ((mode (subseq message 0 (min 3 (length message))))
        (txt (subseq message (min 4 (length message)))))
    (cond 
         ; if <txt> is empty, do nothing
         ((string= "" txt) t)
         ; if mode = TXT, write to all clients
         ((string= "TXT" mode) (write-to-clients-text 
                                    (mapcar #'car (clients res))
                                    (concatenate 'string 
                                       "TXT "
                                       (cdr (assoc client (clients res))) 
                                       " " 
                                       txt)))
         ; if mode = USR, check if name exists... 
         ; if exists 
         ;    write to client "already exists"
         ; else
         ;    write to all clients "USR <newName> <oldName>
         ;    save new name in clients list
         ((string= "USR" mode) (cond 
                                  ((member txt (clients res) :key #'cdr :test #'string=)
                                       (write-to-client-text client "TXT This name already exists"))
                                  ((member client (clients res) :key #'car)
                                    (progn 
                                       (write-to-clients-text 
                                          (mapcar #'car (clients res)) 
                                          (concatenate 'string 
                                             message 
                                             " " 
                                             (cdr (assoc client (clients res)))))
                                       (setf (cdr (assoc client (clients res))) txt)))
                                  (t (resource-received-text res client (concatenate 'string "CON " txt)))))
         ; if mode = CON, check if name exists....
         ; if exists
         ;    write ERROR to connecting client
         ; else
         ;    write to all clients "CON <usr>"
         ;    add client to list clients in class
         ;    write to connecting client "CON <usr>" for every connected client even connecting client itself
         ((string= "CON" mode) (if 
                                  (member txt (clients res) :key #'cdr :test #'string=)
                                  (write-to-client-text client "ERR Dieser Name ist bereits vergeben")
                                  (progn
                                    (write-to-clients-text 
                                       (mapcar #'car (clients res)) 
                                       message)
                                    (push `(,client . ,txt) (clients res))
                                    (mapc 
                                       #'(lambda (X) (write-to-client-text client 
                                          (concatenate 'string 
                                             "CON " 
                                             (cdr X)))) 
                                       (clients res)))))
         ; else, do nothing
         (t t))))



;;; server start

; start server listening to port
(bordeaux-threads:make-thread
          (lambda ()
            (ws:run-server 12345))
          :name "server")


; start event listener
(bordeaux-threads:make-thread
 (lambda ()
   (ws:run-resource-listener (ws:find-global-resource "/chat")))
 :name "resource listener for /chat")

