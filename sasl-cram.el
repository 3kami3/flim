;;; sasl-cram.el --- CRAM-MD5 module for the SASL client framework

;; Copyright (C) 2000 Daiki Ueno

;; Author: Kenichi OKADA <okada@opaopa.org>
;;	Daiki Ueno <ueno@unixuser.org>
;; Keywords: SASL, CRAM-MD5

;; This file is part of FLIM (Faithful Library about Internet Message).

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

(require 'sasl)
(require 'hmac-md5)

(defvar sasl-cram-md5-authenticator nil)

(defconst sasl-cram-md5-continuations
  '(ignore				;no initial response
    sasl-cram-md5-response))

(unless (get 'sasl-cram 'sasl-authenticator)
  (put 'sasl-cram 'sasl-authenticator
       (sasl-make-authenticator "CRAM-MD5" sasl-cram-md5-continuations)))

(defun sasl-cram-md5-response (principal challenge)
  (let ((passphrase
	 (sasl-read-passphrase
	  (format "CRAM-MD5 passphrase for %s: "
		  (sasl-principal-name-internal principal)))))
    (unwind-protect
	(concat (sasl-principal-name-internal principal) " "
		(encode-hex-string
		 (hmac-md5 (nth 1 challenge) passphrase)))
      (fillarray passphrase 0))))

(provide 'sasl-cram)

;;; sasl-cram.el ends here