;; bible.el --- A minor mode using the diatheke command-line Bible tool
;; Copyright 2015 Nicholas Carroll
;; http://casanico.com

;; -------------------------------------------------------------------
;; VERSION HISTORY
;; -------------------------------------------------------------------
;; Ver    Date       Author      Description
;; ----   ---------  ----------  ----------------------------------------
;;  0.1   19-APR-16  N. Carroll  Copied from github.com/JasonFruit/diatheke.el
;;  0.2   20-APR-16  N. Carroll  Added bible-view
;;
;; -------------------------------------------------------------------
;; LICENSE
;; -------------------------------------------------------------------
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3 of
;; the License, or (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301 USA

;; -------------------------------------------------------------------
;; INSTALLATION AND USE 
;; -------------------------------------------------------------------
;; To use this minor mode, you must have Diatheke properly installed
;; and on your PATH; you must also have installed at least one bible
;; ('module').  Diatheke can be retrieved from:
;; http://www.crosswire.org/wiki/Frontends:Diatheke
;;
;; To install bible.el, save this file somewhere in your Emacs load
;; path and put the following in your .emacs:
;;
;;   (require 'bible)
;;   (setq diatheke-bible "WEB") ; replace WEB with your favourite bible module
;;
;; To toggle bible-mode, which is initially off, do:
;;
;;   M-x bible-mode

(defun bible-extract-bibles (lst)
  "Extract a list of installed bible modules from diatheke output."
  (if (not lst) '()
    (let ((first-parts (split-string (car lst) " : ")))
      (if (= (length first-parts) 2)
	  (cons (car first-parts) (bible-extract-bibles (cdr lst)))
	(bible-extract-bibles (cdr lst))))))

(defun bible-get-bible-list ()
  "Return a list of installed bible modules."
  (with-temp-message "Retrieving bible list . . . "
    (let ((lines (split-string
		  (shell-command-to-string
		   "diatheke -b system -k modulelist")
		  "\n")))
      (bible-extract-bibles lines))))

(defun bible-set-bible ()
  "Set the active bible module from an autocompletion list."
  (interactive)
  (let ((bibles (bible-get-bible-list)))
    (setq diatheke-bible
	  (minibuffer-with-setup-hook 'minibuffer-complete
	    (completing-read "Bible: "
			     bibles nil t))))
  (force-mode-line-update))

(defun selected-region()
  "The text highlighted or marked."
  (buffer-substring (region-beginning)  (region-end)))

(defun bible-view ()
  "Pop a temp buffer with a passage."
  (interactive)
    (if (< (length (selected-region)) 50)
	(bible-show (read-string " Passage: " (selected-region)))
    (bible-show (read-string "Passage: "))))

(defun bible-insert ()
  "Insert a passage at point."
  (interactive)
  (if (< (length (selected-region)) 50)
      (shell-command (concat "diatheke -b " diatheke-bible " -k '" (read-string "Passage: " (selected-region)) "'") 1)
  (shell-command (concat "diatheke -b " diatheke-bible " -k '" (read-string "Passage: ") "'") 1)))

(defun bible-show (key)
  "Pop a temp buffer with the passage."
      (with-output-to-temp-buffer "*bible*"
    (print (shell-command-to-string
	   (concat "diatheke -b " diatheke-bible  " -k ' " key "' | sed s/^[^:]*://g")))))

(defun bible-choose-result (results)
  "Choose a search result from an autocompletion list."
  (let ((history (split-string
		  (cadr (split-string results "-- "))
		  " ; ")))
    (minibuffer-with-setup-hook 'minibuffer-complete
      (completing-read "Passage: "
		       history nil t))))

(defun bible-search (key type)
  "Do a search of the specified type for the key."
  (let ((results
	 (with-temp-message "Retrieving search results . . ."
	   (shell-command-to-string
	    (concat "diatheke -s " type " -b " diatheke-bible " -k " key)))))
    (bible-show (bible-choose-result results))))

(defun bible-multiword-search (key)
  "Do a multiword search."
  (interactive "sSearch terms: ")
  (bible-search key "multiword"))

(defun bible-phrase-search ()
  "Do a phrase search."
  (interactive)
    (if (< (length (selected-region)) 50)
	(bible-search (read-string "Phrase: " (selected-region)) "phrase")
	(bible-search (read-string "Phrase: ") "phrase")))

(defun bible-regex-search (key)
  "Do a search by regular expression."
  (interactive "sRegex: ")
  (bible-search key "regex"))

(provide 'bible)
(define-minor-mode bible-mode
  "Toggle bible-mode.

     With no argument, this command toggles the mode.  Non-null
     prefix argument turns on the mode.  Null prefix argument
     turns off the mode.
     
     When bible-mode is enabled, several keybindings are made
     to insert bible passages by several kinds of search and by
     reference.

     Also, the variable diatheke-bible is set to the name of the
     alphabetically first diatheke module."
  
  ;; The initial value:
  :init-value nil
 ;; In case diatheke-bible was not set in .emacs TODO 
 ;; :after-hook
 ;; (if (eq (diatheke-bible) nil)
 ;;     (bible-set-bible))
  ;; The indicator for the mode line:
  :lighter " Bible"
  ;; The minor mode bindings:
   :keymap
 '(("\C-\c\C-b" . bible-set-bible)
   ("\C-\c\C-i" . bible-insert)
   ("\C-\c\C-v" . bible-view)
   ("\C-\c\C-m" . bible-multiword-search)
   ("\C-\c\C-p" . bible-phrase-search)
   ("\C-\c\C-r" . bible-regex-search)))

 (easy-menu-define bible-mode-menu bible-mode-map
   "Menu for `bible-mode'."
   '("Bible"
     ["Set Bible Module " bible-set-bible]
     "---"
     ["View Passage" bible-view]     
     ["Insert Passage" bible-insert]
     "---"
     ["Phrase Search" bible-phrase-search]
     ["Multiword Search" bible-multiword-search]
     ["Regex Search" bible-regex-search]))
