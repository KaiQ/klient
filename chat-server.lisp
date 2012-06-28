
(ql:quickload "clws")

;(asdf:operate 'asdf:load-op 'clws)

(defpackage #:chat
  (:use :cl :clws))

(in-package #:chat)

;;;; chat server
;;;; -----------
(setf *debug-on-server-errors*   nil
      *debug-on-resource-errors* nil)

(defclass chat-resource (ws-resource)
  ((clients :initform () :accessor clients)))

(register-global-resource
 "/chat"
 (make-instance 'chat-resource)
 (ws::origin-prefix "http://127.0.0.1" "http://localhost" "null"))


(defmethod resource-accept-connection ((res chat-resource) resource-name headers client)
  (declare (ignore headers resource-name))
  (format t "~%got[2] connection on chat server from ~s : ~s" (client-host client) (client-port client))
  t)

(defmethod resource-client-connected ((res chat-resource) client)
  (format t "~%got connection on chat server from ~s : ~s" (client-host client) (client-port client))
  t)



(defmethod resource-client-disconnected ((res chat-resource) client)
  (let ((name (cdr (assoc client (clients res)))))
      (setf (clients res) (remove client (clients res) :key #'car))
      (if name 
         (write-to-clients-text (mapcar #'car (clients res)) (concatenate 'string "DIS " name))))
  (format t "~%Client disconnected from resource ~A: ~A" res client))



(defmethod resource-received-text ((res chat-resource) client message)
  (format t "~%got frame ~s from client ~s" message client)
  (when (string= message "error")
    (error "~2%got \"error\" message~2%"))
  (let ((mode (subseq message 0 (min 3 (length message))))
        (txt (subseq message (min 4 (length message)))))
    (cond 
         ((string= "" txt) t)
         ((string= "TXT" mode) (write-to-clients-text 
                                    (mapcar #'car (clients res))
                                    (concatenate 'string 
                                       "TXT "
                                       (cdr (assoc client (clients res))) 
                                       ": " 
                                       txt)))
          ((string= "USR" mode) (cond 
                                  ((member txt (clients res) :key #'cdr :test #'string=)
                                       (write-to-client-text client "TXT Dieser Name ist bereits vergeben"))
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
          (t t))))



(defmethod resource-received-binary((res chat-resource) client message)
  (format t "~%got binary frame ~s from client ~s" (length message) client)
  (write-to-client-text client (format nil "got binary ~s" message))
  (write-to-client-binary client message))



(bordeaux-threads:make-thread
          (lambda ()
            (ws:run-server 12345))
          :name "server")


(bordeaux-threads:make-thread
 (lambda ()
   (ws:run-resource-listener (ws:find-global-resource "/chat")))
 :name "resource listener for /chat")

