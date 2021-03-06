(defun c:chairbom ()
  (setq scalelist '(192.0   128.0    96.0    72.0
                     48.0    36.0    24.0    16.0
                     12.0     8.0  1270.0  2540.0
                   3810.0  5080.0  6350.0  7620.0
                   8890.0 10160.0 11430.0 12700.0))
  ;PROGRAM TO READ ATTRIBUTE FILE (<currentDWGdir>\CHAIRBOM.TXT)
  ;AND TO WRITE A CHAIR BILL-OF-MATERIALS BACK TO DRAWING
  (setq osmode (getvar 'osmode))
  (setq cmdecho (getvar 'cmdecho))
  (setq filedia (getvar 'filedia))
  (setvar "CMDECHO" 0)
  (setvar "FILEDIA" 0)

  ;SET OUTPUT PATH
  (setq current_dir (getvar 'Dwgprefix))
  (setq chairbom_output (strcat current_dir "\chairbom.txt"))

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
  ;(setq margin (cond ((getreal "\nEnter multiplication constant for values: ")) (1.05)))
  (setvar "OSMODE" 0)
  (printctable sp)
  (setvar "FILEDIA" filedia)
  (setvar "CMDECHO" cmdecho)
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
;;;	The cons function for slist reverses the order thus making it ascending order     	;;;
      
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
  (setq output_block "C:\\Apps\\PT_CAD\\GENERAL\\CTABLE_BLANK.dwg")
  (setq pour_num (getstring "Pour(s):"))
  (setq floor_num (getstring "Floor(s):"))
  (setq index 0)
  (setq num_types_slab_bolster 3)
  (setq max_entries_per_table 50)
  (setq modulo (rem (length slist) max_entries_per_table))
  (setq num_blank_entries (- max_entries_per_table modulo))
  (while (< index (- num_blank_entries num_types_slab_bolster))
    (setq slist (append slist (list '("-" "-"))))
    (setq index (1+ index)))
  
  (setq slist (append slist (list '("~w\" S.B." "0") '("1\" S.B." "0") '("1~4\" S.B." "0"))))
  (setq num_tables (/ (length slist) max_entries_per_table))
  (setq index 0)
  
  (command "-LAYER" "_ON" chaired_layers
                    "_T"  chaired_layers
                    "_S"  output_layer "")
  (while (< index (length slist))
    (command "-INSERT" output_block sp 1
      1 0 pour_num floor_num 
      ;TODO - find a means of iterating that is command-input-friendly
      (chair_height (+ 0 index))
      (chair_quantity (+ 0 index))
      (chair_height (+ 1 index))
      (chair_quantity (+ 1 index))
      (chair_height (+ 2 index))
      (chair_quantity (+ 2 index))
      (chair_height (+ 3 index))
      (chair_quantity (+ 3 index))
      (chair_height (+ 4 index))
      (chair_quantity (+ 4 index))
      (chair_height (+ 5 index))
      (chair_quantity (+ 5 index))
      (chair_height (+ 6 index))
      (chair_quantity (+ 6 index))
      (chair_height (+ 7 index))
      (chair_quantity (+ 7 index))
      (chair_height (+ 8 index))
      (chair_quantity (+ 8 index))
      (chair_height (+ 9 index))
      (chair_quantity (+ 9 index))
      (chair_height (+ 10 index))
      (chair_quantity (+ 10 index))
      (chair_height (+ 11 index))
      (chair_quantity (+ 11 index))
      (chair_height (+ 12 index))
      (chair_quantity (+ 12 index))
      (chair_height (+ 13 index))
      (chair_quantity (+ 13 index))
      (chair_height (+ 14 index))
      (chair_quantity (+ 14 index))
      (chair_height (+ 15 index))
      (chair_quantity (+ 15 index))
      (chair_height (+ 16 index))
      (chair_quantity (+ 16 index))
      (chair_height (+ 17 index))
      (chair_quantity (+ 17 index))
      (chair_height (+ 18 index))
      (chair_quantity (+ 18 index))
      (chair_height (+ 19 index))
      (chair_quantity (+ 19 index))
      (chair_height (+ 20 index))
      (chair_quantity (+ 20 index))
      (chair_height (+ 21 index))
      (chair_quantity (+ 21 index))
      (chair_height (+ 22 index))
      (chair_quantity (+ 22 index))
      (chair_height (+ 23 index))
      (chair_quantity (+ 23 index))
      (chair_height (+ 24 index))
      (chair_quantity (+ 24 index))
      (chair_height (+ 25 index))
      (chair_quantity (+ 25 index))
      (chair_height (+ 26 index))
      (chair_quantity (+ 26 index))
      (chair_height (+ 27 index))
      (chair_quantity (+ 27 index))
      (chair_height (+ 28 index))
      (chair_quantity (+ 28 index))
      (chair_height (+ 29 index))
      (chair_quantity (+ 29 index))
      (chair_height (+ 30 index))
      (chair_quantity (+ 30 index))
      (chair_height (+ 31 index))
      (chair_quantity (+ 31 index))
      (chair_height (+ 32 index))
      (chair_quantity (+ 32 index))
      (chair_height (+ 33 index))
      (chair_quantity (+ 33 index))
      (chair_height (+ 34 index))
      (chair_quantity (+ 34 index))
      (chair_height (+ 35 index))
      (chair_quantity (+ 35 index))
      (chair_height (+ 36 index))
      (chair_quantity (+ 36 index))
      (chair_height (+ 37 index))
      (chair_quantity (+ 37 index))
      (chair_height (+ 38 index))
      (chair_quantity (+ 38 index))
      (chair_height (+ 39 index))
      (chair_quantity (+ 39 index))
      (chair_height (+ 40 index))
      (chair_quantity (+ 40 index))
      (chair_height (+ 41 index))
      (chair_quantity (+ 41 index))
      (chair_height (+ 42 index))
      (chair_quantity (+ 42 index))
      (chair_height (+ 43 index))
      (chair_quantity (+ 43 index))
      (chair_height (+ 44 index))
      (chair_quantity (+ 44 index))
      (chair_height (+ 45 index))
      (chair_quantity (+ 45 index))
      (chair_height (+ 46 index))
      (chair_quantity (+ 46 index))
      (chair_height (+ 47 index))
      (chair_quantity (+ 47 index))
      (chair_height (+ 48 index))
      (chair_quantity (+ 48 index))
      (chair_height (+ 49 index))
      (chair_quantity (+ 49 index)))
      (setq index (+ index max_entries_per_table))))

(defun chair_height (chair_index)
  (car (nth chair_index slist)))

;;; retrieve qttable_index if valid + 5%
(defun chair_quantity (chair_index)
  (if (numberp (cadr (nth chair_index slist)))
    (fix (1+ (* (cadr
      (nth chair_index slist)) 1.05)))
    (cadr
      (nth chair_index slist))))

;;;		pBe Helper function to sort alist variable	;;;
(defun _ToDecimal (str / p  )
  (if (vl-string-position 126 str)
    (distof
      (vl-some
        '(lambda (s)
          (if (Setq p (vl-string-search (Car s) str))
            (vl-string-subst (cadr s) (Car s) str p)))
        '(("~1\""  ".625")
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