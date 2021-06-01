(require 'org)

(global-set-key (kbd "C-x a") 'org-agenda)
(global-set-key (kbd "C-c C-x j") #'org-clock-jump-to-current-clock)

(setq org-directory "~/org/org")
(setq org-agenda-files (list "~/org/org/"))
(setq org-default-notes-file (concat org-directory "/capture.org"))

(setq org-export-backends '(md))

(defun rc/org-increment-move-counter ()
  (interactive)

  (defun default (x d)
    (if x x d))

  (let* ((point (point))
         (move-counter-name "MOVE_COUNTER")
         (move-counter-value (-> (org-entry-get point move-counter-name)
                                 (default "0")
                                 (string-to-number)
                                 (1+))))
    (org-entry-put point move-counter-name
                   (number-to-string move-counter-value)))
  nil)

(defun rc/org-get-heading-name ()
  (nth 4 (org-heading-components)))

(defun rc/org-kill-heading-name-save ()
  (interactive)
  (let ((heading-name (rc/org-get-heading-name)))
    (kill-new heading-name)
    (message "Kill \"%s\"" heading-name)))

(global-set-key (kbd "C-x p w") 'rc/org-kill-heading-name-save)

(setq org-agenda-custom-commands
      '(("u" "Unscheduled" tags "+personal-SCHEDULED={.+}-DEADLINE={.+}/!+TODO"
         ((org-agenda-sorting-strategy '(priority-down))))
        ("p" "Personal" ((agenda "" ((org-agenda-tag-filter-preset (list "+personal"))))))
        ("w" "Work" ((agenda "" ((org-agenda-tag-filter-preset (list "+work"))))))
        ))

;;; org-cliplink

(rc/require 'org-cliplink)

(global-set-key (kbd "C-x p i") 'org-cliplink)

(defun rc/cliplink-task ()
  (interactive)
  (org-cliplink-retrieve-title
   (substring-no-properties (current-kill 0))
   '(lambda (url title)
      (insert (if title
                  (concat "* TODO " title
                          "\n  [[" url "][" title "]]")
                (concat "* TODO " url
                        "\n  [[" url "]]"))))))
(global-set-key (kbd "C-x p t") 'rc/cliplink-task)

;;; org-capture
(require 'org-protocol)

(defun find-journal-tree-func ()
  (defun find-subtree (format level)
    (let ((name (format-time-string format)))
      (if (re-search-forward
           (format org-complex-heading-regexp-format (regexp-quote name))
           nil t)
          (goto-char (point-at-bol))
        (goto-char (point-max))
        (or (bolp) (insert "\n"))
        (insert level " " name "\n")
        (beginning-of-line 0))
      ))
  (goto-char (point-min))
  (find-subtree "%Y" "*")
  (find-subtree "%Y-%m" "**")
  (find-subtree "%Y-%m-%d" "***")
  (org-end-of-subtree))

(setq org-capture-templates
      '(("w" "Capture task" entry (file+headline "~/org/org/tasks.org" "Inbox")
         "** TODO %?\n  SCHEDULED: %t\n")
		
        ("K" "Cliplink capture task" entry (file+headline "~/org/org/tasks.org" "Inbox")
         "* TODO %(org-cliplink-capture) \n  SCHEDULED: %t\n" :empty-lines 1)

        ("n" "Note" entry (file+function "~/org/org/notes.org" find-journal-tree-func)
         "* %U - %?\n  %i\n" :kill-buffer t :empty-lines 0)
		
	("p" "Protocol" entry (file+headline "~/org/org/tasks.org" "Inbox")
         "* %^{Title}\nSource: %u, %c\n #+BEGIN_QUOTE\n%i\n#+END_QUOTE\n\n\n%?")
		
	("L" "Protocol Link" entry (file+headline "~/org/org/tasks.org" "Inbox")
         "* %? [[%:link][%:description]] \nCaptured On: %U")))

(setq org-protocol-default-template-key "n")
(define-key global-map "\C-cc" 'org-capture)

;;; org-journal
(require 'org-journal)
(setq org-journal-dir "~/org/org/journal/")
(setq org-journal-date-format "%A, %d %B %Y")
(setq org-journal-file-format "%Y-%m-%d.org")
(defun org-journal-save-entry-and-exit()
  "Simple convenience function.
  Saves the buffer of the current day's entry and kills the window
  Similar to org-capture like behavior"
  (interactive)
  (save-buffer)
  (kill-buffer-and-window))

(defun get-journal-file-today ()
  "Gets filename for today's journal entry."
  (let ((daily-name (format-time-string org-journal-file-format)))
    (expand-file-name (concat org-journal-dir daily-name))))

(defun journal-file-today ()
  "Creates and load a journal file based on today's date."
  (interactive)
  (find-file (get-journal-file-today)))

(defun get-journal-file-yesterday ()
  "Gets filename for yesterday's journal entry."
  (let* ((yesterday (time-subtract (current-time) (days-to-time 1)))
         (daily-name (format-time-string org-journal-file-format yesterday)))
    (expand-file-name (concat org-journal-dir daily-name))))

(defun journal-file-yesterday ()
  "Creates and load a file based on yesterday's date."
  (interactive)
  (find-file (get-journal-file-yesterday)))

(define-key org-journal-mode-map (kbd "C-x C-s") 'org-journal-save-entry-and-exit)
(define-key global-map (kbd "C-c t") 'journal-file-today)
(define-key global-map (kbd "C-c y") 'journal-file-yesterday)

;;;org-roam
(require 'org-roam)
(setq org-roam-capture-templates
	  '(("d" "default" plain (function org-roam--capture-get-point)
		 "%?"
		 :file-name "${slug}"
		 :head "#+TITLE: ${title}#+ROAM_ALIAS:\n#+ROAM_TAGS: private "
		 :unnarrowed t)))

(setq org-roam-capture-ref-templates
	  '(("r" "ref" plain (function org-roam--capture-get-point)
		 "%?"
		 :file-name "ref-${slug}"
		 :head "#+TITLE: ${title}\n#+ROAM_ALIAS:\n#+ROAM_KEY: ${ref} \n#+ROAM_TAGS: ${ref} "
		 :unnarrowed t)))

(setq org-roam-directory "~/org/roam")
(setq org-roam-db-location "~/org-roam.db")
(add-hook 'after-init-hook 'org-roam-mode)
(setq org-roam-db-update-method 'immediate)
(define-key global-map (kbd "C-c r") 'org-roam-capture)
(define-key global-map (kbd "C-c C-r i") 'org-roam-insert)
(define-key global-map (kbd "C-c C-r f") 'org-roam-find-file)
(define-key global-map (kbd "C-c C-r r") 'org-roam-buffer-toggle-display)
(define-key global-map (kbd "C-c C-r b") 'org-roam-switch-to-buffer)
(define-key global-map (kbd "C-c C-r d") 'org-roam-find-directory)

(require 'org-protocol)
(require 'org-roam-protocol)
