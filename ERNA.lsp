(defun c:chairbom ()
  (setq scalelist '(192.0 128.0 96.0 72.0 48.0 36.0 24.0 16.0 12.0 8.0 1270.0 2540.0 3810.0 5080.0 6350.0 7620.0 8890.0 10160.0 11430.0 12700.0))
  ;PROGRAM TO READ ATTRIBUTE FILE (<currentDWGdir>\CHAIRBOM.TXT)
  ;AND TO WRITE A CHAIR BILL-OF-MATERIALS BACK TO DRAWING
  (setq osmode (getvar 'osmode))
  (setvar "CMDECHO" 0)
  (setvar "FILEDIA" 0)

  ;SET OUTPUT PATH
  (setq current_dir (getvar 'Dwgprefix))
  (setq chairbom_output (strcat current_dir "\chairbom.txt"))
  (setq current_dir (getvar 'Dwgprefix))

  ;EXTRACT ATTRIBUTES
  (command "attext" "" "c:\\apps\\PT_CAD\\bom\\chairtem.txt" chairbom_output)
  
  ;READ EXTRACTED ATTRIBUTES
  (setvar "FILEDIA" 1)
  (setq a (open chairbom_output "r"))
  (setq charlist 
     '("1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "~" "/" "\"" "q" "w" "e" "r" "t"))
  (setq scale (getvar "dimscale")) 
  (if (not (member scale scalelist))
     (progn
        (setq scale (getreal "Enter scale factor - 96 for 1/8\", 128 for 3/32\", 192 for 1/16\" [SCALE FACTOR X 25.4 FOR METRIC]: "))
        (setvar "dimscale" scale)))
  (command "style" "ROMANS" "ROMANS.shx,SPECIAL.shx" (/ (getvar "dimscale") 8.0) 0.9 0 "N" "N" "N")
  (setq chrhts '())
  (setq alist '())
  (listatt)
  (close a)
  (setq sp (getpoint "Pick starting point for chair schedule: "))
  (setvar "OSMODE" 0)
  (printctable sp)
  (setvar "CMDECHO" 1)
  (setvar "OSMODE" osmode))

(defun listatt ()
   (while (setq l (read-line a))  
      (setq cl (proline l 1 nil nil ""))
      (setq lastc (substr (car cl) (strlen (car cl)) 1))

;HANDLE NO QUANTITY CALLOUT IN MULT. CHAIR BLOCK
;CONSOLIDATE CALLOUTS W/ AND W/O INCH MARKS

      (if (/= lastc "\"")
          (progn
             (setq htinch (strcat (car cl) "\""))
             (setq cl (list htinch (cadr cl)))))
      (if (= (cadr cl) 0)             ;IF QUANTITY IS 0 THEN CHAIR CALLOUT QUANTITY IS TWO
          (setq cl (subst 2 0 cl)))

      (if (not (member (car cl) chrhts))
          (progn
             (setq chrhts (cons (car cl) chrhts))
             (setq alist (cons cl alist)))
          (progn 
             (setq old (assoc (car cl) alist))
             (setq new (append old (cdr cl)))
             (setq alist (subst new old alist)))))
   (setq slist '())
      
;;;				Sort alsit descending order    					;;;
;;;	The cons function for slist reverses the order thus making it ascneding order     	;;;
      
   (foreach x (vl-sort alist
                '(lambda (a b) (> (_ToDecimal (Car a)) (_ToDecimal (car b)))))
      (setq slist (cons (list (car x) (apply '+ (cdr x))) slist))))

(defun proline (l cn 2f h n / hnl cc )
   (setq cc (substr l cn 1))  
   (cond
     ((= cn (1+ (strlen l)))
       (setq hnl (list h (atoi n))))
     ((and (member cc charlist) (not 2f))
       (if (= h nil)
         (setq h cc)
         (setq h (strcat h cc)))
       (proline l (1+ cn) nil h n))
     ((= cc ",")
       (proline l (1+ cn) T h n))
     ((and (member cc charlist) 2f)
       (if (= n "")
         (setq n cc)
         (setq n (strcat n cc)))
       (proline l (1+ cn) T h n))
     (T
       (proline l (1+ cn) 2f h n)))) 

(defun printctable (sp)
  ;Prints CTABLE Block with values from listatt result
  (setq output_layer "BAND_SUP_TEXT")
  (setq chaired_layers "BAND_SUP_TEXT,UNIFORM_SUP_TEXT")
  (setq output_block "CTABLE")
  (setq pour_num (getstring "Pour(s)?"))
  (setq floor_num (getstring "Floor(s)?"))
  (setq count (length slist))
  (setq max_entries 47)
  (while (< count max_entries)
    (progn
      (setq slist (append slist (list '("-" "-"))))
      (setq count (1+ count))))
  
  (command "-LAYER" "_ON" chaired_layers
                    "_T" chaired_layers
                    "_S" output_layer "")
  (command "-INSERT" output_block sp 1
    1 0 pour_num floor_num 
    ;TODO - find a means of iterating that is command-input-friendly
    (car  (nth 0 slist))
    (cadr (nth 0 slist))
    (car  (nth 1 slist))
    (cadr (nth 1 slist))
    (car  (nth 2 slist))
    (cadr (nth 2 slist))
    (car  (nth 3 slist))
    (cadr (nth 3 slist))
    (car  (nth 4 slist))
    (cadr (nth 4 slist))
    (car  (nth 5 slist))
    (cadr (nth 5 slist))
    (car  (nth 6 slist))
    (cadr (nth 6 slist))
    (car  (nth 7 slist))
    (cadr (nth 7 slist))
    (car  (nth 8 slist))
    (cadr (nth 8 slist))
    (car  (nth 9 slist))
    (cadr (nth 9 slist))
    (car  (nth 10 slist))
    (cadr (nth 10 slist))
    (car  (nth 11 slist))
    (cadr (nth 11 slist))
    (car  (nth 12 slist))
    (cadr (nth 12 slist))
    (car  (nth 13 slist))
    (cadr (nth 13 slist))
    (car  (nth 14 slist))
    (cadr (nth 14 slist))
    (car  (nth 15 slist))
    (cadr (nth 15 slist))
    (car  (nth 16 slist))
    (cadr (nth 16 slist))
    (car  (nth 17 slist))
    (cadr (nth 17 slist))
    (car  (nth 18 slist))
    (cadr (nth 18 slist))
    (car  (nth 19 slist))
    (cadr (nth 19 slist))
    (car  (nth 20 slist))
    (cadr (nth 20 slist))
    (car  (nth 21 slist))
    (cadr (nth 21 slist))
    (car  (nth 22 slist))
    (cadr (nth 22 slist))
    (car  (nth 23 slist))
    (cadr (nth 23 slist))
    (car  (nth 24 slist))
    (cadr (nth 24 slist))
    (car  (nth 25 slist))
    (cadr (nth 25 slist))
    (car  (nth 26 slist))
    (cadr (nth 26 slist))
    (car  (nth 27 slist))
    (cadr (nth 27 slist))
    (car  (nth 28 slist))
    (cadr (nth 28 slist))
    (car  (nth 29 slist))
    (cadr (nth 29 slist))
    (car  (nth 30 slist))
    (cadr (nth 30 slist))
    (car  (nth 31 slist))
    (cadr (nth 31 slist))
    (car  (nth 32 slist))
    (cadr (nth 32 slist))
    (car  (nth 33 slist))
    (cadr (nth 33 slist))
    (car  (nth 34 slist))
    (cadr (nth 34 slist))
    (car  (nth 35 slist))
    (cadr (nth 35 slist))
    (car  (nth 36 slist))
    (cadr (nth 36 slist))
    (car  (nth 37 slist))
    (cadr (nth 37 slist))
    (car  (nth 38 slist))
    (cadr (nth 38 slist))
    (car  (nth 39 slist))
    (cadr (nth 39 slist))
    (car  (nth 40 slist))
    (cadr (nth 40 slist))
    (car  (nth 41 slist))
    (cadr (nth 41 slist))
    (car  (nth 42 slist))
    (cadr (nth 42 slist))
    (car  (nth 43 slist))
    (cadr (nth 43 slist))
    (car  (nth 44 slist))
    (cadr (nth 44 slist))
    (car  (nth 45 slist))
    (cadr (nth 45 slist))
    (car  (nth 46 slist))
    (cadr (nth 46 slist))
    0 0 0)); 3/4" SB, 1" SB, & 1-1/4" SB

;;;		pBe Helper function to sort alist variable	;;;
;;;								;;;
(defun _ToDecimal (str / p  )
  (if (vl-string-position 126 str)
    (distof (vl-some '(lambda (s)
    (if (Setq p (vl-string-search (Car s) str))
      (vl-string-subst (cadr s) (Car s) str p)))
    '(("~1\"" ".625")
      ("~2\""  ".125")
      ("~3\""  ".1875")
      ("~4\""  ".25")
      ("~5\""  ".3125")
      ("~6\""  ".375")
      ("~7\""  ".4375")
      ("~8\""  ".5")
      ("~9\""  ".5625")
      ("~0\""  ".625")
      ("~q\""  ".6875")
      ("~w\""  ".75")
      ("~r\""  ".875")
      ("~t\""  ".9375"))))
    (atoi str)))  