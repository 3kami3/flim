(require 'closure)
(require 'ew-line)
(require 'ew-quote)
(require 'mel)

(provide 'ew-unit)

(defconst ew-anchored-encoded-word-regexp
  (concat "\\`" ew-encoded-word-regexp "\\'"))

(defconst ew-b-regexp
  (concat "\\`\\("
	  "[A-Za-z0-9+/]"
	  "[A-Za-z0-9+/]"
	  "[A-Za-z0-9+/]"
	  "[A-Za-z0-9+/]"
	  "\\)*"
	  "[A-Za-z0-9+/]"
	  "[A-Za-z0-9+/]"
	  "\\(==\\|"
	  "[A-Za-z0-9+/]"
	  "[A-Za-z0-9+/=]"
	  "\\)\\'"))

(defconst ew-q-regexp "\\`\\([^=?]\\|=[0-9A-Fa-f][0-9A-Fa-f]\\)*\\'")

(defconst ew-byte-decoder-alist
  '(("B" . ew-b-decode)
    ("Q" . ew-q-decode)))

(defconst ew-byte-checker-alist
  '(("B" . ew-b-check)
    ("Q" . ew-q-check)))

(defun ew-b-check (encoding encoded-text) (string-match ew-b-regexp encoded-text))
(defun ew-q-check (encoding encoded-text) (string-match ew-q-regexp encoded-text))

(defun ew-eword-p (str)
  (let ((len (length str)))
    (and
     (<= 3 len)
     (string= (substring str 0 2) "=?")
     (string= (substring str (- len 2) len) "?="))))

(defun ew-decode-eword (str &optional eword-filter1 eword-filter2)
  (if (string-match ew-anchored-encoded-word-regexp str)
      (let ((charset (match-string 1 str))
	    (encoding (match-string 2 str))
	    (encoded-text (match-string 3 str))
	    bdec cdec
	    bcheck
	    tmp)
	(if (and (setq bdec (ew-byte-decoder encoding))
		 (setq cdec (ew-char-decoder charset)))
	    (if (or (null (setq bcheck (ew-byte-checker encoding)))
		    (funcall bcheck encoding encoded-text))
		(progn
		  (setq tmp (closure-call cdec (funcall bdec encoded-text)))
		  (when eword-filter1 (setq tmp (closure-call eword-filter1 tmp)))
		  (setq tmp (ew-quote tmp))
		  (when eword-filter2 (setq tmp (closure-call eword-filter2 tmp)))
		  tmp)
	      (ew-quote str))
	  (ew-quote-eword charset encoding encoded-text)))
    (ew-quote str)))

(defun ew-byte-decoder (encoding)
  (cdr (assoc (upcase encoding) ew-byte-decoder-alist)))

(defun ew-byte-checker (encoding)
  (cdr (assoc (upcase encoding) ew-byte-checker-alist)))

(defalias 'ew-b-decode 'base64-decode-string)
(defalias 'ew-q-decode 'q-encoding-decode-string)

(defconst ew-charset-aliases
  '((us-ascii . iso-8859-1)
    (iso-2022-jp-2 . iso-2022-7bit-ss2)))
(defun ew-char-decoder (charset)
  (catch 'return 
    (setq charset (downcase charset))
    (let ((sym (intern charset))
	  tmp cs)
      (when (setq tmp (assq sym ew-charset-aliases))
	(setq sym (cdr tmp)))
      (setq cs (intern (concat (symbol-name sym) "-unix")))
      (when (coding-system-p cs)
	(throw 'return
	       (closure-make (lambda (str) (decode-coding-string str cs)) cs)))
      nil)))