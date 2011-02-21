;;; smart-tab.el --- Intelligent tab completion and indentation.

;; Copyright (C) 2009 Sebastien Rocca Serra,
;;                    Daniel Hackney

;; Author: Sebastien Rocca Serra <sroccaserra@gmail.com>
;;         Daniel Hackney <dan@haxney.org>
;; Maintainer: Daniel Hackney <dan@haxney.org>
;; Keywords: convenience abbrev
;; Created: 24 May 2009
;; URL: http://github.com/chrono325/smart-tab/tree/master
;; Version: 0.3
;; Features that might be required by this library:
;;
;;   `easy-mmmode'


;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; From http://www.emacswiki.org/cgi-bin/wiki/TabCompletion#toc2. There are a
;; number of available customizations on that page.
;;
;; To activate, add:
;;     (require 'smart-tab)
;;     (global-smart-tab-mode 1)
;;
;; to your .emacs file, or set `global-smart-tab-mode' to non-nil with
;; customize.

;;; Code:

(require 'easy-mmode)

(defgroup smart-tab nil
  "Options for `smart-tab-mode'.")

(defcustom smart-tab-using-hippie-expand nil
  "Use `hippie-expand' to expand text.
Use either `hippie-expand' or `dabbrev-expand' for expanding text
when we don't have to indent."
  :type '(choice
          (const :tag "hippie-expand" t)
          (const :tag "dabbrev-expand" nil))
  :group 'smart-tab)

(defcustom smart-tab-completion-functions-alist
  '((emacs-lisp-mode . lisp-complete-symbol)
    (text-mode       . dabbrev-completion))
  "A-list of major modes in which to use a mode specific completion function.
If current major mode is not found in this alist, fall back to
hippie-expand or dabbrev-expand, depending on the value of
smart-tab-using-hippie-expand"
  :type '(alist :key-type (symbol :tag "Major mode")
                :value-type (function :tag "Completion function to use in this mode"))
  :group 'smart-tab)

;;;###autoload
(defun smart-tab (&optional prefix)
  "Try to 'do the smart thing' when tab is pressed.
`smart-tab' attempts to expand the text before the point or
indent the current line or selection.

In a regular buffer, `smart-tab' will attempt to expand with
either `hippie-expand' or `dabbrev-expand', depending on the
value of `smart-tab-using-hippie-expand'. If the mark is active,
or PREFIX is \\[universal-argument], then `smart-tab' will indent
the region or the current line (if the mark is not active)."
  (interactive "P")
  (if (smart-tab-must-expand prefix)
      (smart-tab-call-completion-function)
    (smart-tab-default)))

(defun smart-tab-call-completion-function()
  "Get a completion function according to current major mode."
  (let ((completion-function
         (cdr (assq major-mode smart-tab-completion-functions-alist))))
    (if (null completion-function)
        (if smart-tab-using-hippie-expand
            (hippie-expand nil)
          (dabbrev-expand nil))
      (funcall completion-function))))

(defun smart-tab-default ()
  "Indents region if mark is active, or current line otherwise."
  (interactive)
  (if (use-region-p)
      (indent-region (region-beginning)
                     (region-end))
    (indent-for-tab-command)))

(defun smart-tab-must-expand (&optional prefix)
  "If PREFIX is \\[universal-argument] or the mark is active, do not expand.
Otherwise, uses `hippie-expand' or `dabbrev-expand' to expand the text at point.."
  (unless (or (consp prefix)
              (use-region-p))
    (looking-at "\\_>")))

;;;###autoload
(defun smart-tab-mode-on ()
  "Turn on `smart-tab-mode'."
  (smart-tab-mode 1))

(defun smart-tab-mode-off ()
  "Turn off `smart-tab-mode'."
  (smart-tab-mode -1))

;;;###autoload
(define-minor-mode smart-tab-mode
  "Enable `smart-tab' to be used in place of tab.

With no argument, this command toggles the mode.
Non-null prefix argument turns on the mode.
Null prefix argument turns off the mode."
  :lighter " Smrt"
  :group 'smart-tab
  :require 'smart-tab
  :keymap '(("\t" . smart-tab)
            ([(tab)] . smart-tab))
  (if smart-tab-mode
      (progn
        ;; Don't start `smart-tab-mode' when in the minibuffer or a read-only
        ;; buffer.
        (when (or (minibufferp)
                  buffer-read-only)
          (smart-tab-mode-off)))))

;;;###autoload
(define-globalized-minor-mode global-smart-tab-mode
  smart-tab-mode
  smart-tab-mode-on
  :group 'smart-tab)

(provide 'smart-tab)

;;; smart-tab.el ends here
