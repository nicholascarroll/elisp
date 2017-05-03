(tool-bar-mode -1)
;; PACKAGE MANAGEMENT
(require 'package)
(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives
	     '("org" . "http://orgmode.org/elpa/") t)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(add-to-list 'load-path "~/.emacs.d/misc")
(package-initialize)

;; ORG MODE SETTINGS
(eval-after-load "org"
  '(require 'ox-md nil t))
(add-hook `org-mode-hook 'turn-on-visual-line-mode)

;; Org-babel active languages
(org-babel-do-load-languages
 'org-babel-load-languages
 '((python . t))) 
(setq org-confirm-babel-evaluate nil)   ;don't confirm code block evals in org

(global-set-key (kbd "C-c o") 'org-mode)

;; BIBLE MODE
(global-set-key (kbd "C-c b") 'bible-mode)
(setq diatheke-bible "WEB") 
(require 'bible)

(prefer-coding-system 'utf-8)

;; HIDESHOW MODE SETTINGS
(require 'hideshow)
(defun my-hs-minor-mode-keys ()
  "my keys for `hs-minor-mode'."
  (interactive)
    (local-set-key (kbd "C-c <right>") 'hs-show-block)
    (local-set-key (kbd "C-c <left>")  'hs-hide-block)
    (local-set-key (kbd "C-c <up>")    'hs-hide-all)
    (local-set-key (kbd "C-c <down>")  'hs-show-all)
  )
(add-hook 'hs-minor-mode-hook 'my-hs-minor-mode-keys)
(add-hook 'c-mode-common-hook 'hs-minor-mode)
(add-hook 'python-mode-hook 'hs-minor-mode)

;; Hideshow Settings For NXML Mode
(require 'sgml-mode)
(require 'nxml-mode)
 (add-to-list 'hs-special-modes-alist
                  '(nxml-mode
 		 "<!--\\|<[^/>]*[^/]>"
 		 "-->\\|</[^/>]*[^/]>"

		 "<!--"
 		 sgml-skip-tag-forward
 		 nil))
(add-hook 'nxml-mode-hook 'hs-minor-mode)

;; LAUNCH INTO THE WAK ASS ZEAL SYSTEM MAINLY COS PYSIDE 1 GOT NO DOCSTRINGS
(require 'zeal-at-point)
(global-set-key (kbd "<f2>") 'zeal-at-point)
(add-to-list 'zeal-at-point-mode-alist '(python-mode . ("python" "pyside")))
(add-to-list 'zeal-at-point-mode-alist '(c++-mode . ("cpp" "qt")))

;; MIDNIGHT CODER MODE
(defun night-mode ()
  (interactive)
  (save-excursion
    (load-theme 'wombat)))
(global-set-key (kbd "C-c w") 'night-mode)

;; TRANSPARENT BACKGROUND TOGGLE
 (defun toggle-transparency ()
   (interactive)
   (let ((alpha (frame-parameter nil 'alpha)))
     (set-frame-parameter
      nil 'alpha
      (if (eql (cond ((numberp alpha) alpha)
                     ((numberp (cdr alpha)) (cdr alpha))
                     ;; Also handle undocumented (<active> <inactive>) form.
                     ((numberp (cadr alpha)) (cadr alpha)))
               100)
          '(80 . 50) '(100 . 100)))))
(global-set-key (kbd "C-c t") 'toggle-transparency)

;; FOUNTAIN MODE SETTINGS
(add-to-list 'auto-mode-alist '("\\.fountain$" . fountain-mode))
(global-set-key (kbd "C-C s") 'google-translate-at-point) 
(global-set-key (kbd "C-C e") 'google-translate-at-point-reverse) 

;; RECENT FILES MENU
(require 'recentf)
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

;; SHADOW LAST CHANGE TO EVERY FILE IN A COMPLETE SHADOW FILESYSTEM
(defun my-backup-file-name (fpath)
  "Return a new file path of a given file path.
If the new path's directories does not exist, create them."
  (let* (
        (backupRootDir "~/.emacs.d/emacs-backup/")
        (filePath (replace-regexp-in-string "[A-Za-z]:" "" fpath )) ; remove Windows driver letter in path, for example, “C:”
        (backupFilePath (replace-regexp-in-string "//" "/" (concat backupRootDir filePath "~") ))
        )
    (make-directory (file-name-directory backupFilePath) (file-name-directory backupFilePath))
    backupFilePath))

(setq make-backup-file-name-function 'my-backup-file-name)

;; JEDI SETTINGS
(defvar jedi:goto-stack '())
(defun jedi:jump-to-definition ()
  (interactive)
  (add-to-list 'jedi:goto-stack
               (list (buffer-name) (point)))
  (jedi:goto-definition))
(defun jedi:jump-back ()
  (interactive)
  (let ((p (pop jedi:goto-stack)))
    (if p (progn
            (switch-to-buffer (nth 0 p))
            (goto-char (nth 1 p))))))

(defun jedi-keybindings ()
  (local-set-key (kbd "M-.") 'jedi:jump-to-definition)
  (local-set-key (kbd "M-,") 'jedi:jump-back)
  (local-set-key (kbd "C-c d") 'jedi:show-doc)
  ;;(local-set-key (kbd "C-tab") 'jedi:complete)
  )
(add-hook 'python-mode-hook 'jedi-keybindings)

;; COMPANY MODE SETTINGS
(require 'company)
(global-set-key (kbd "<C-tab>") 'company-complete)
(setq company-require-match nil)

;; COMPANY-JEDI
(add-hook 'python-mode-hook 'company-mode)
(push 'company-jedi company-backends)

;; FLYCHECK FOR RTAGS
(defun setup-flycheck-rtags ()
  (interactive)
  (flycheck-select-checker 'rtags)
  (setq-local flycheck-highlighting-mode nil)
  (setq-local flycheck-check-syntax-automatically nil))

;; COMPANY-RTAGS
(when (require 'rtags nil :noerror)
  (define-key c-mode-base-map (kbd "M-.")
    (function rtags-find-symbol-at-point))
  (define-key c-mode-base-map (kbd "M-,")
    (function rtags-location-stack-back))
  (rtags-enable-standard-keybindings) 
  (setq rtags-autostart-diagnostics t)
  (setq rtags-completions-enabled t)
  (rtags-start-process-unless-running)
  ;;(setq company-dabbrev-downcase nil) ;uncomment if getting case problems
  (add-hook 'c++-mode-hook 'company-mode)
  (push 'company-rtags company-backends)
  ;; flycheck-rtags shows clang warnings inline
  (require 'flycheck-rtags)
  (add-hook 'c++-mode-hook #'setup-flycheck-rtags))

;; MAGIT 
(global-set-key (kbd "C-c g") 'magit-status)

;; FILL COLUMN INDICATOR FOR PYTHON
(require 'fill-column-indicator)
(add-hook 'python-mode-hook 'fci-mode)
(setq fci-rule-column 80)
;;workaround for bug between company mode and fill-column-indicator
(defvar-local company-fci-mode-on-p nil)
(defun company-turn-off-fci (&rest ignore)
  (when (boundp 'fci-mode)
    (setq company-fci-mode-on-p fci-mode)
    (when fci-mode (fci-mode -1))))
(defun company-maybe-turn-on-fci (&rest ignore)
  (when company-fci-mode-on-p (fci-mode 1)))
(add-hook 'company-completion-started-hook 'company-turn-off-fci)
(add-hook 'company-completion-finished-hook 'company-maybe-turn-on-fci)
(add-hook 'company-completion-cancelled-hook 'company-maybe-turn-on-fci)


;   ____  _     ____  _____  ____  _       
;  /   _\/ \ /\/ ___\/__ __\/  _ \/ \__/|  
;  |  /  | | |||    \  / \  | / \|| |\/||  
;  |  \__| \_/|\___ |  | |  | \_/|| |  ||  
;  \____/\____/\____/  \_/  \____/\_/  \|  
;                                          
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ac-auto-start nil)
 '(column-number-mode t)
 '(company-idle-delay nil)
 '(cua-mode t nil (cua-base))
 '(fountain-export-use-title-as-filename nil)
 '(fringe-mode 0 nil (fringe))
 '(google-translate-default-source-language "en")
 '(google-translate-default-target-language "es")
 '(inhibit-startup-screen t)
 '(initial-scratch-message nil)
 '(org-export-with-sub-superscripts nil)
 '(org-modules
   (quote
    (org-bbdb org-bibtex org-docview org-gnus org-info org-irc org-mhe org-rmail org-w3m)))
 '(python-shell-interpreter "ipython")
 '(python-shell-interpreter-args "--simple-prompt -i")
 '(word-wrap t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(persistent-scratch-setup-default)

(put 'downcase-region 'disabled nil)
