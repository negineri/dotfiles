;;; packages.el --- org-roam layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2024 Sylvain Benner & Contributors
;;
;; Author: Shin Oura <negineri@shiden.local>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `org-roam-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `org-roam/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `org-roam/pre-init-PACKAGE' and/or
;;   `org-roam/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst org-roam-packages
  '(
    (org-roam :location
              (recipe :fetcher github :repo "org-roam/org-roam"))
    (org-roam-bibtex :location
                     (recipe :fetcher github :repo "org-roam/org-roam-bibtex"))))

(defun org-roam/init-org-roam ()
  (use-package org-roam
    :defer t
    :hook (after-init . org-roam-mode)
    :custom
    (org-roam-directory "~/org-roam") ;; please change it to your path
    :config
    (progn
      (spacemacs/declare-prefix "aor" "org-roam")
      (spacemacs/declare-prefix "aord" "org-roam-dailies")
      (spacemacs/declare-prefix "aort" "org-roam-tags")
      (spacemacs/set-leader-keys
        "aordy" 'org-roam-dailies-goto-yesterday
        "aordt" 'org-roam-dailies-goto-today
        "aordT" 'org-roam-dailies-goto-tomorrow
        "aordd" 'org-roam-dailies-goto-date
        "aorf" 'org-roam-node-find
        "aorc" 'org-roam-capture
        "aorg" 'org-roam-graph
        "aori" 'org-roam-node-insert
        "aorl" 'org-roam-buffer-toggle
        "aorta" 'org-roam-tag-add
        ;; "aortd" 'org-roam-tag-delete
        "aortr" 'org-roam-tag-remove
        "aora" 'org-roam-alias-add)

      (spacemacs/declare-prefix-for-mode 'org-mode "mr" "org-roam")
      (spacemacs/declare-prefix-for-mode 'org-mode "mrd" "org-roam-dailies")
      (spacemacs/declare-prefix-for-mode 'org-mode "mrt" "org-roam-tags")
    (setq org-roam-mode-sections
          (list #'org-roam-backlinks-insert-section
                #'org-roam-reflinks-insert-section
                ))
    (setq org-roam-file-extensions '("org"))
    (org-roam-setup)
    (setq org-roam-node-display-template "${file}")

    ;; templates
    (setq org-roam-capture-templates
          '(("d" "default" plain
              "%?"
              :if-new (file+head "${slug}.org" "#+title: ${title}\n\n")
              :unnarrowed t)
            ("t" "task" plain
              "* 概要\n\n%?\n* 作業"
              :if-new (file+head "task.%<%Y.%m.%d>.${slug}.org" "#+title: ${title}\n\n")
              :unnarrowed t)
            ("m" "meeting" plain
              "* 書記\n\n%?"
              :if-new (file+head "meet.%<%Y.%m.%d>.${slug}.org" "#+title: ${title} - Meeting\n\n")
              :unnarrowed t)
            ("s" "Scratch note" plain
              "%?"
              :if-new (file+head "scratch.%<%Y.%m.%d.%M%S%3N>.org" "#+title: ${title} - Scratch\n\n")
              :unnarrowed t)))
    (setq org-roam-dailies-directory "")
    (setq org-roam-dailies-capture-templates
          '(("d" "default" plain
              "* tasks\n\n- %?\n* log"
              :if-new (file+head "daily.journal.%<%Y.%m.%d>.org" "#+title: %<%Y-%m-%d> - Journal\n\n")
              :unnarrowed t))))
))

(defun org-roam/init-org-roam-bibtex ()
  (use-package org-roam-bibtex
    :after org-roam
    :config
    (setq orb-roam-ref-format "org-cite")
    :bind (:map org-mode-map
                (("C-c n a" . orb-note-actions)))))
