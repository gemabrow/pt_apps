(defun c:endview ()
                   

   (setvar "osmode" 0)
   (setvar "cmdecho" 0)
   (setq sf 8)   ;SET SCALE MULTIPLE
   (setq cover 1.5) ;SET CONCRETE COVER FOR ANCHORS
   (setq rebcov 2.0) ;SET CONCRETE COVER FOR REBAR AT COLUMNS
   (setq minopen 2.5) ;SET WIDTH OF MIN. OPEN FOR ANCHOR IN REBAR
   (setq anchout 3) ;DEFAULT DIST ANCHOR CAN LIE OUTSIDE BEAM SIDE
   (command "-LAYER" "T" "ENDVIEW" "ON" "ENDVIEW" "")
   (setvar "CLAYER" "ENDVIEW")
   (setq ss (ssadd)) ;SET SS TO NULL SELECTION SET 
   (setq bardial '(("3" 0.375)("4" 0.5)("5" 0.625)("6" 0.75)("7" 0.875)("8" 1.0)("9" 1.128)("10" 1.27)("11" 1.41)
                  ("12" 1.50)("14" 1.693)("18" 2.257)))  ;REBAR DIAMETER ASSOCIATION LIST  
   (input)
   (drawbeam)   
   (if (/= colshape nil)
       (drawbar)
   )
   (drawanch)
   (dimanch)
   (command "scale" ss "" ll sf)
)

(defun input ()
   (setq atl '("D" "S" "I" "U")) 
   (setq dimtop "B")
   (setq st (getreal "\nEnter slab thickness, return if none: "))
   (if (/= st nil)  ;LOCATE SLAB W/ RESPECT TO BEAM
      (progn
         (initget 1 "L l R r C c")
         (setq sj (getkword "\nEnter L[left], R[right] or C[centered] to locate slab with respect to beam: "))
      )
      (setq st 0.0)  ;SET st TO 0 IF SLAB NOT PRESENT
   )
   (setq bd (getreal "\nEnter beam depth from top of slab in inches: "))   
   (setq bw (getreal "\nEnter beam width at bottom of beam in inches: "))
   (setq tw (getreal "\nEnter beam width at top of beam in inches, return if same as bottom: "))
   (if (= tw nil) 
       (setq tw bw)
       (progn
          (initget "T t B b")
          (setq dimtop (getkword "Enter T if top beam width is at top of slab, B if at bottom of slab: "))
       )
   )
   (setq cgs (getreal "Enter the height of the cgs above beam bottom in inches: "))
   (if (> cgs (- bd (/ st 2.0)))
       (progn
           (alert "Given CGS can not be attained")
           (setq cgs (getreal "Please reenter the height of the cgs above beam bottom in inches or return to cancel program: "))
           (if (= cgs nil) (exit))
       )
   )
   (prompt "\nEnter the total number of anchors required w/ suffix to indicate type - ")
   (setq na (getstring "\n[D=deadend, S=stressend, I=intermediate or U=unspecified] eg - 8D: "))
   (setq at (strcase (substr na (strlen na) 1)))
   (while (not (member at atl))
       (prompt "\nIncorrect anchor type - Please enter the total number of anchors required w/ suffix to indicate type - ")
       (setq na (getstring "\n[D=deadend, S=stressend, I=intermediate or U=unspecified] eg - 8D: "))
       (setq at (strcase (substr na (strlen na) 1)))
   )
   (setq na (atoi (substr na 1 (1- (strlen na)))))
   
                                    ;;;;;;;   ENTER COLUMN REBAR INPUT  ;;;;;;;

   
   (initget "R r C c")
   (setq colshape (getkword "\nEnter R or C to designate rectangular or circular column, return if none: "))
   (if (/= colshape nil)
      (progn    
         (if (= (strcase colshape) "C")
             (setq colsize (getreal "Enter column diameter in decimal inches: "))
             (setq colsize (getreal "Enter size of column face at beam end in decimal inches: "))
         )
         (initget "Y y N n")
         (setq even (getkword "\nIs column vertical rebar evenly spaced? [Y or N]: "))  
         (initget "C c L l R r O o")
         (setq coljust (getkword "\nHow is column located w/ respect to beam [C=centered, L=left justified, R=right justified or O=offset]: "))
         (if (= (strcase coljust) "O")
             (setq offset (getreal "Enter amount column is offset to right of beam in decimal inches [offset to left as negative no.]: "))
         )
         (if (= (strcase even) "Y")
             (setq bars (getstring "Enter rebar quantity & size at rectangular column face or total no. of bars for circular column [eg 3#7]: "))
             (setq bars (getstring "Enter rebar quantity & size for side of column at beam end only[eg 5#7]: "))
         ) 
         (setq rn (substr bars 1 1)) ;INITIALIZE REBAR NO.
         (setq nc 2)
         (setq c (substr bars 2 1))   
         (while (/= c "#")     
            (setq rn (strcat rn c))
            (setq nc (1+ nc))
            (setq c (substr bars nc 1))
         )
         (setq rebsize (substr bars (1+ nc) (- (strlen bars) nc))) ;REBAR SIZE AS STRING
         (setq rebsize (cadr (assoc rebsize bardial))) ;LOOKUP REBAR DIA AS REAL NO. IN ASSOC. LIST
         (setq rn (atoi rn))  ;rn - NUMBER OF BARS AT COLUMN FACE OR TOTAL NO. OF BARS IN CIRC. COLUMN AS INTEGER

    
         ;;; COMMENT OUT PROMPT FOR ROTATION OF REBAR @ CIRCULAR COLUMN
         ;;; ADD LATER IF WARRENTED
         ;(if (and (= (strcase colshape) "C")(= (strcase even) "Y"))
             ;(progn
                ;(setq rebrot (getangle "\nEnter counterclockwise degrees of rotation for circular column rebar [leftmost bar at 9 o'clock = 0 is default]: "))
                ;(if (= rebrot nil)
                    (setq rebrot 0.0)
                ;)
             ;)
         ;)  
         (setq respal '())
         (if (= (strcase even) "N")
            (progn
                (setq s (getreal "\nEnter distance from left edge of column to centerline of leftmost vert. bar: "))
                (setq s (- s rebcov (/ rebsize 2)))
                (setq respal (cons s respal))          
                (setq n 1)
                (while (< n rn)
                   (setq p (strcat "\nEnter spacing from left to right between bars " (itoa n) " and " (itoa (1+ n)) ": "))   
                   (prompt p)
                   (setq s (getreal))
                   (setq respal (cons s respal))
                   (setq n (1+ n))
                )
                (setq respal (reverse respal))
             )          
         )
      )
   )      
)

(defun drawbeam ()  
        ;GENERATE 4 BEAM CORNERS  
       
   (setq ll (getpoint "Pick lower left corner of endview: "))
   (setq lr (list (+ (car ll) bw) (cadr ll)))
   (setq ul (list (car ll) (+ (cadr ll)  bd)))
   (setq ur (list (car lr) (+ (cadr lr)  bd)))
   (setq pw (/ (* 0.01 (getvar "dimscale")) sf))  ;DETERMINE POLYLINE WIDTH FOR BEAM BOUNDARIES
   (if (= (strcase dimtop) "T")  ;FIND BEAM TOP WIDTH AT BOTTOM OF SLAB
       (if (= (strcase sj) "C")
           (setq tw (- tw (* (/ (* st (/ (- tw bw) 2)) bd) 2))) ;FOR SLAB CENTERED ON BEAM
           (setq tw (- tw (/ (* st (- tw bw)) bd)))             ;FOR LEFT OR RIGHT JUSTIFIED BEAM          
       ) 
   )
        ;GENERATE SLAB ENDS IF ANY
   (if (> st 0.1)
      (progn
         (setq drop (- bd st))
         (cond ((= (strcase sj) "L")                      
             (setq sbl (list (- (car ll) (- tw bw)) (+ (cadr ll) drop))) 
             (setq sll (list (- (car sbl) 12) (cadr sbl)))
             (setq slu (list (car sll) (+ (cadr sll) st)))
             (command "pline" slu "w" pw "" ur lr ll "")
             (ssadd (entlast) ss)
             (command "pline" ll "w" pw"" sbl sll "")
             (ssadd (entlast) ss)
             (command "chprop" "L" "" "LT" "hidden" "")             
            )
            ((= (strcase sj) "R")
             (setq sbr (list (+ (car lr)(- tw bw)) (+ (cadr lr) drop))) 
             (setq srl (list (+ (car sbr) 12) (cadr sbr)))
             (setq sru (list (car srl) (+ (cadr srl) st)))
             (command "pline" sru "w" pw "" ul ll lr "")
             (ssadd (entlast) ss)
             (command "pline" lr "w" pw ""  sbr srl "")        
             (ssadd (entlast) ss)
             (command "chprop" "L" "" "LT" "hidden" "")              
            )
            ((= (strcase sj) "C")
             (setq sbl (list (- (car ll) (/ (- tw bw) 2)) (+ (cadr ll) drop))) 
             (setq sll (list (- (car sbl) 12) (cadr sbl)))
             (setq slu (list (car sll) (+ (cadr sll) st)))
             (setq sbr (list (+ (car lr)(/ (- tw bw) 2)) (+ (cadr lr) drop))) 
             (setq srl (list (+ (car sbr) 12)(cadr sbr)))
             (setq sru (list (car srl) (+ (cadr srl) st)))
             (command "pline" sll "w" pw ""  sbl ll "")
             (ssadd (entlast) ss)            
             (command "chprop" "L" "" "LT" "hidden" "") 
             (command "pline" ll "w" pw "" lr "")
             (ssadd (entlast) ss)
             (command "pline"  lr "w" pw "" sbr srl "")
             (ssadd (entlast) ss)
             (command "chprop" "L" "" "LT" "hidden" "") 
             (command "pline" slu "w" pw "" sru "")
             (ssadd (entlast) ss)             
            )
         )
      )
      (progn
         (command "pline" ul ll lr ur ul"")  ;DRAW RECTANGULAR BEAM SECTION IF NO SLAB
         (ssadd (entlast) ss)         
      )
   )
)

(defun drawbar ()  ;CREATE REBAR SPACING LIST IF NOT CREATED IN INPUT AND DRAW VERT. COLUMN REBAR
   (setq cagesize (- colsize (* 2 rebcov) rebsize))   
   (if (= (strcase even) "Y")
       (if (= (strcase colshape) "R")
           (progn
              (setq s (/ cagesize (1- rn))) ;COMPUTE BAR SPACING
              (setq n 1)
              (while (< n rn)
                 (setq respal (cons s respal))
                 (setq n (1+ n))  
              )
              (setq respal (reverse respal))
              (setq respal (cons 0.0 respal))
           )
           (progn    ;FIND SPACING BETWEEN BARS OF CIRCULAR COLUMN
                     ;INITIALIZE REBAR SPA. LIST TO OFFSET DUE TO ROTATION 
              (setq is (* (* cagesize (sin (* 0.5 rebrot))) (cos (/ (- pi rebrot) 2.0)))) ;INITIAL SPA. DUE TO ROTATION OF CAGE
              (setq respal (list is))
              (setq incang (/ (* 2 pi) rn)) ;FIND INCLUDED ANGLE BETWEEN BARS
              (setq theta (+ incang rebrot))
              (setq s (* (* cagesize (sin (* 0.5 theta))) (cos (/ (- pi theta) 2.0))))
              (setq respal (cons (- s is) respal)) ;SUBTRACT OFFSET DUE TO ROTATION FROM OFFSET TO SECOND BAR TO GIVE SPA FROM BAR 1 TO BAR 2
              (setq ps s)
              (setq n 1) 
              (while (< n (/ rn 2)) ;ITERATE THRU BARS AT COLUMN FACE TO GENERATE SPA. LIST respal
                  (setq theta (+ theta incang))
                  (setq s (* (* cagesize (sin (* 0.5 theta))) (cos (/ (- pi theta) 2.0))))
                  (setq respal (cons (- s ps) respal))
                  (setq ps s)
                  (setq n (1+ n))
              )
              (if (/= rebrot 0.0)
                  (setq respal (cdr respal))
              )
              (setq respal (reverse respal))
           )
       )
   )
   (setq s (+ rebcov (/ rebsize 2)))  ;DETERMINE STARTING POINT FOR REBAR DOUBLE LINES
   (setq y (- (cadr ll) 6.0))
   (cond  ((= (strcase coljust) "C") ;DETERMINE X FOR SP AND DRAW COLUMN
              (setq x (+ (- (car ll) (- (/ colsize 2.0) (/ bw 2.0))) s))
              (setq cl (list (- (car ll) (- (/ colsize 2.0) (/ bw 2.0))) (cadr ll))) ;DETERMINE TOP OF COLUMN LEFT
              (setq cr (list (+ (car lr) (- (/ colsize 2.0) (/ bw 2.0))) (cadr ll))) ;DETERMINE TOP OF COLUMN RIGHT              
          )
          ((= (strcase coljust) "L")
              (setq x (+ (car ll) s))
              (setq cl ll) ;DETERMINE TOP OF COLUMN LEFT
              (setq cr (list (+ (car ll) colsize) (cadr ll))) ;DETERMINE TOP OF COLUMN RIGHT             
          )
          ((= (strcase coljust) "R")
              (setq x (+ (- (car ll) (- colsize bw)) s))             
              (setq cl (list (- (car lr) colsize) (cadr ll))) ;DETERMINE TOP OF COLUMN RIGHT
              (setq cr lr) ;DETERMINE TOP OF COLUMN LEFT             
          )
          ((= (strcase coljust) "O")
              (setq x (+ (+ (- (car ll) (- (/ colsize 2.0) (/ bw 2.0))) offset) s))
              (setq cl (list (+ (- (car ll) (- (/ colsize 2.0) (/ bw 2.0))) offset) (cadr ll))) ;DETERMINE TOP OF COLUMN LEFT
              (setq cr (list (+ (car cl) colsize) (cadr ll)))
          )                 
   )
   (command "line" cl "@6<270" "")     ;DRAW TOP OF COLUMN
   (ssadd (entlast) ss)
   (command "line" cl cr "")
   (ssadd (entlast) ss)
   (command "line" cr "@6<270" "")
   (ssadd (entlast) ss)  
   (setq vertlen (+ bd 4)) ;SET VERT. LENGTH OF REBAR   
   (setq n 0)
   (setq l (length respal)) 
   (setq hatscale (* rebsize 7)) ;SET HATCH SCALE
   (while (< n l)   ; INSERT REBAR
       (setq sp (list (+ x (nth n respal)) y))
       (if (= n 0)
          (setq bar1p sp)
       )
       (setq ep (list (car sp) (+ y vertlen)))
       ;(setq rebinsl (cons (list sp ep) rebinsl))
       (command "mline" "J" "Z" "scale" rebsize sp ep "")
       (ssadd (entlast) ss)
       (command "hatch" "ansi37" hatscale 0 "L" "")
       (ssadd (entlast) ss)
       (command "chprop" "L" "" "LA" "hatch_light" "") 
       (setq x (car sp))
       (setq n (1+ n))
   )  
)

   
   
(defun drawanch ()
   (if (/= colshape nil) ;GET OFFSET LIST IF COLUMN REBAR EXISTS
      (progn    
         (setq offsetl (ainrloc respal rebsize colsize bw rebcov (- (car ll) (car cl)))) ;GET OFFSET LIST TO MISS REBAR 
         (setq tryl '())
         (setq n (1- (length offsetl))) 
         (while (>= n 0)
            (setq try (nth n offsetl))
            (if (and (> try (- anchout))(< try (+ tw anchout)))
                (setq tryl (cons try tryl))
            )
            (setq n (1- n))
         )
         (setq offsetl tryl)
         (setq nc (length offsetl)) ;IF REBAR EXISTS DETERMINE NO. OF COLUMNS
         (if (= nc 0)
             (setq nope 'T)
             (setq nope 'F)
         )
      )
      (setq bar1p '(0,0))    
   )
   (if (= nope 'T)
      (progn
         (if (= st nil)
            (cantdo)
         )
         (setq clear 'ok)
         (setq nfix na)
         (alert "OPENINGS IN COLUMN REBAR TOO SMALL TO ALLOW ANCHOR INSTALLATION - ALL ANCHORS INSTALLED IN SLAB")
      )
      (progn           
         (setq clear 'notok) ;SET FLAG TO DETERMINE ANCHORS ARE WITHIN BEAM BOUNDARIES
         (setq nfix 0) ;INITIALIZE NO. OF FIXED ANCHORS ABOVE BEAM BOTTOM
      )
   )
   (setq yfix (- bd (/ st 2))) ;HEIGHT OF FIXED ANCHORS ABOVE BEAM BOTTOM
   (setq hs 3) ;SET INITIAL HORIZONTAL SPACING TO 3"
   (setq vs 6) ;SET INITIAL VERTICAL SPACING TO 6"

   (while (/= clear 'ok) ;DETERMINE VERT SPA, HOR SPA, NO. OF FIXED ANCHORS AND DIST OF BOTTOM ROW ABOVE BEAM BOTTOM (y)
        ;(princ "\nClear = ") (princ clear)
      (setq clear 'ok)
      (if (= colshape nil)
         (progn          
            (setq nc (fix (1+ (/ (- (- bw (* 2 cover)) 2.25) hs))))  ;FIND NO. OF COLUMNS BASED ON hs & cover IF NO REBAR         
            (if (= hs 3)   ;SAVE INITIAL NO. OF COLUMNS
               (setq onc nc)
            )
         )    
      )
      (if (/= nc 0)      
         (setq nr (/ (- na nfix) (float nc)))  ;FIND NO. OF ROWS
         (setq nr 0)
      )
      (if (/= nr (fix nr))
          (progn
             (setq nri (+ (fix nr) 1)) ;FIND INTEGRAL NO. OF ROWS
             (setq nar1 (* nc (- nr (fix nr)))) ;FIND NO. OF ANCHORS IN BOTTOM ROW
          )
          (progn
             (setq nri nr)
             (if (> nr 0.0)
                (setq nar1 nc)
                (setq nar1 0)
             )
          ) 
      )      
      (setq n 1)
      (setq mult 0)
      (while (< n nri)    ;DETERMINE SPACING MULTIPLE TO DETERMINE HEIGHT ABOVE BEAM BOTTOM FOR CGS
         (setq mult (+ mult n))
         (setq n (1+ n))
      )   

           ;FIND DISTANCE FROM BOTTOM OF BEAM TO FIRST ROW OF ANCHORS
      (if (/= na nfix)
         (setq yab (/ (- (* cgs na)(* vs nc mult)(* yfix nfix)) (- na nfix)))
         (setq yab yfix)
      )
         ;(princ "\nna = ")(princ na)
         ;(princ "\ncgs = ")(princ cgs)
         ;(princ "\nvs = ")(princ vs)
         ;(princ "\nnc = ")(princ nc)
         ;(princ "\nmult = ")(princ mult)
         ;(princ "\nyfix = ")(princ yfix)
         ;(princ "\nnfix = ")(princ nfix)
         (princ "\nyab = ")(princ yab)(terpri)
      ;(if (< yab (+ cover 2.5))   ;CHECK BOTTOM CLEARANCE   ;;MOVED CHECK FOR LOW CGS TO OUTSIDE LOOP
      ;    (progn
      ;       (setq clear 'toolow)
      ;       (alert "CGS IS TOO LOW TO BE ACHIEVED USING STANDARD ANCHOR CONFIGURATION - TRY FILLING BOTTOM ROW OR RAISING CGS")
      ;       (exit)
      ;    )          
      ;)
   
      (setq ah (+ yab (* vs (1- nri)))) ;FIND HEIGHT OF TOP ROW OF ANCHORS ABOVE BOTTOM OF BEAM   
      (if (> ah (- bd (+ cover 2.5)))  ;CHECK TOP CLEARANCE
          (setq clear 'toohigh)         
      )
      (if (= colshape nil)
         (progn    ;DETERMINE HOR. SPA., VERTICAL SPA. & NO. OF FIXED ANCHRS IF REBAR IS NOT PRESENT
            (if (and (or (= clear 'toohigh)(= clear 'toolow)) (= hs 3)) ;REDUCE HORIZONTAL SPACING
                (progn
                   (setq clear 'try1)
                   (setq hs 2.5)
                )
            )  
            (if (and (or (= clear 'toohigh)(= clear 'toolow)) (= hs 2.5) (= vs 6)) ;REDUCE VERTICAL SPACING
                (progn
                   (setq clear 'try2)
                   (setq vs 5.5)
                )             
            )
            (if (and (or (= clear 'toohigh)(= clear 'toolow)) (= hs 2.5) (= vs 5.5)) ;INSTALL FIXED ANCHORS IN SLAB
                (progn
                   (if (= st nil)
                       (cantdo)
                   )
                   (setq nfix (1+ nfix))
                   (if (> nar1 0)
                      (setq nar1 (1- nar1))
                      (progn                 ;IF BOTTOM ROW IS ALL MOVED TO SLAB RESET NEXT ROW UP TO BOTTOM ROW
                         (setq nri (1- nri))
                         (if (/= nri 0.0)
                             (setq nar1 nc)
                         )
                      )
                   )
                ) 
            )
         )
         (progn  ;DETERMINE VERTICAL SPA. & NO. OF FIXED ANCHRS IF REBAR IS PRESENT
            (if (and (or (= clear 'toohigh)(= clear 'toolow))(= vs 6)) ;REDUCE VERTICAL SPACING
                (progn
                   (setq clear 'try2)
                   (setq vs 5.5)
                )             
            )
            (if (and (or (= clear 'toohigh)(= clear 'toolow))(= vs 5.5)) ;INSTALL FIXED ANCHORS IN SLAB
                (progn
                   (if (= st nil)
                      (cantdo)
                   )
                   (setq nfix (1+ nfix))
                   (setq yfix (- bd (/ st 2)))
                   (if (> nar1 0)
                      (setq nar1 (1- nar1))
                      (if (= nar1 0)                 ;IF BOTTOM ROW IS ALL MOVED TO SLAB RESET NEXT ROW UP TO BOTTOM ROW
                         (progn
                            (setq nri (1- nri))
                            (if (/= nri 0.0)
                               (setq nar1 nc)
                            )
                         )
                      )
                   )
                ) 
            )
         )
      )
   ) ;END WHILE
   (if (< yab (+ cover 2.5))   ;CHECK BOTTOM CLEARANCE
          (progn
             (setq clear 'toolow)
             (alert "CGS IS TOO LOW TO BE ACHIEVED USING STANDARD ANCHOR CONFIGURATION - TRY FILLING BOTTOM ROW OR RAISING CGS")
             (exit)
          )          
   )
   

   
   
                        ;GENERATE OFFSET LIST BASED ON hs IF NO REBAR IS PRESENT
   (if (= colshape nil)
      (progn
         (setq offsetl '())
         (setq margin (/ (- bw (* (1- nc) hs)) 2)) ;DISTANCE FROM EDGE OF BEAM TO OUTER ANCHOR INS. PT.
         (setq cc 0)
         (while (< cc nc)
            (setq offsetl (cons (+ margin (* cc hs)) offsetl))
            (setq cc (1+ cc))
         )      
         (if (= onc nc)   ;RESET hs TO 3" IF DECREASING IT DID NOT INCREASE NUMBER OF COLUMNS
             (setq hs 3)
         )
      )      
   )
        
              ;;;;;  GENERATE INSERTION POINT LIST FOR ANCHORS  ;;;;;;;;
   
   (setq ail '()) ;INITIALIZE ANCHOR INSERTION LIST
   (setq r 1)  
         ;(princ "\nyab = ")(princ yab)(terpri)
   (setq y (+ (cadr ll) yab))
   (setq n 0)
   (setq i (fix (/ nar1 0.99))) ;SET COUNTER FOR BOTTOM ROW ANCHORS
   (setq lo (length offsetl))  ;USE LENGTH OF OFFSET LIST TO DETERMINE NO. OF COLUMNS
    
       ;DO BOTTOM ROW OF ANCHORS SEPARATELY, ADJUST PLACEMENT OF FIRST ANCHOR BASED ON NO. OF ANCHORS IN FIRST ROW
   (if (not (< (abs (- (fix (/ nar1 1.9)) (/ nar1 2.0))) 0.1))    ;TEST NO. OF ANCHORS IN FIRST ROW FOR ODDNESS
       (progn
           (setq row1odd 'y)           
           (setq x (+ (car ll) (nth (/ lo 2) offsetl)))               
           (setq ail (cons (list x y) ail))
           (setq n (1+ n)) ;INCREMENT ANCHOR COUNTER
           (setq i (1- i))
       )
       (setq row1odd 'n)
   )
   (if (not (< (abs (- (fix (/ nc 1.9)) (/ nc 2.0))) 0.1))    ;TEST NO. COLUMNS FOR ODDNESS
       (setq ncodd 'y)
       (setq ncodd 'n)
   )              
   (setq oc 0) ;SET OFFSET COUNTER
   (if (and (= row1odd 'y) (= ncodd 'n))       
      (while (> i 0)  ;FIND INS. PTS. FOR PAIRS OF ANCHORS IN FIRST ROW (TO MAINTAIN SYMMETRY), ADD OUTSIDE IN
         (setq x (+ (car ll) (nth oc offsetl)))
         (setq ail (cons (list x y) ail))
         (setq n (1+ n))         
         (setq x (+ (car ll) (nth (- lo (1+ oc)) offsetl)))
         (setq ail (cons (list x y) ail))
         (setq n (1+ n))
         (setq oc (1+ oc))
         (setq i (- i 2))
      )
      (progn
         (if (= ncodd 'n)
            (setq lpos1 (/ lo 2))
            (setq lpos1 (1+ (/ lo 2)))
         )
         (while (> i 0) ;FIND INS. PTS. FOR PAIRS OF ANCHORS IN FIRST ROW (TO MAINTAIN SYMMETRY), ADD INSIDE OUT
            (setq x (+ (car ll) (nth (+ lpos1 oc) offsetl)))                 
            (setq ail (cons (list x y) ail))
            (setq n (1+ n))
            (if (= ncodd 'n)         
               (setq x (+ (car ll) (nth (- lpos1 (1+ oc)) offsetl))) ;EVEN NO. OF COLUMNS
               (setq x (+ (car ll) (nth (- lpos1 (1+ (1+ oc))) offsetl))) ;ODD NO. OF COLUMNS
            )
            (setq ail (cons (list x y) ail))
            (setq n (1+ n))
            (setq oc (1+ oc))
            (setq i (- i 2))                                
         )
      )       
   )
   (setq r 2) ;INITIALIZE ROW NO.
   (while (<= r nri)   ;FIND INSERTION POINTS FOR RECT. ARRAY OF ANCHORS
      (setq y (+ y vs))
      (setq oc 0) ;SET OFFSET COUNTER
         (while (< oc nc)               
            (setq x (+ (car ll) (nth oc offsetl)))
            (setq ail (cons (list x y) ail))
            (setq n (1+ n))
            (setq oc (1+ oc))
         )
     (setq r (1+ r))
   )
         ;(PRINC "\nBAR1P =")(PRINC BAR1P)
   (if (/= colshape nil)
      (progn
         (setq lrb (- (car bar1p) (/ rebsize 2.0) rebcov 2.5)) ;LEFT X TO MISS REBAR  ;ERROR1
         (setq rrb (+ (car bar1p) cagesize (/ rebsize 2.0) rebcov 2.5)) ;RIGHT X TO MISS REBAR
       )
    )

         ;FIND INS. PTS. FOR FIXED ANCHORS
   (if (/= nfix 0)
      (progn
         (setq nfixl 0)
         (setq nfixr 0)                                                                          
         (setq y (+ (cadr ll) (- bd (/ st 2.0))))        
         (cond ((= (strcase sj) "L")                  
                   (setq x (- (car ll) 2.5))
                   (if (and (> x lrb)(/= colshape nil))
                       (setq x lrb)
                   )
                   (setq ail (cons (list x y) ail))
                   (setq n 1)
                   (setq nfixl (1+ nfixl))
                   (while (< n nfix)
                      (setq x (- x 6))
                      (setq ail (cons (list x y) ail))
                      (setq n (1+ n))
                      (setq nfixl (1+ nfixl))
                   )
               )
              ((= (strcase sj) "R")                  
                  (setq x (+ (car lr) 2.25))
                  (if (and(< x rrb)(/= colshape nil))
                       (setq x rrb)
                   )
                  (setq ail (cons (list x y) ail))
                  (setq n 1)
                  (setq nfixr (1+ nfixr))
                  (while (< n nfix)
                     (setq x (+ x 6))
                     (setq ail (cons (list x y) ail))
                     (setq n (1+ n))
                     (setq nfixr (1+ nfixr))
                  )
               )
              ((= (strcase sj) "C")
                  (setq xl (- (car ll) 2.5 ))
                  (if (and (> xl lrb)(/= colshape nil))
                      (setq xl lrb)
                   )
                  (setq ail (cons (list xl y) ail))
                  (setq n 1)
                  (setq nfixl (1+ nfixl))
                  (if (< n nfix)
                     (progn
                        (setq xr (+ (car lr) 2.5))
                        (if (and (< xr rrb)(/= colshape nil))
                           (setq xr rrb)
                        )
                        (setq ail (cons (list xr y) ail))
                        (setq nfixr (1+ nfixr))
                        (setq n (1+ n))
                     )
                  )                         
                  (while (< n nfix)
                     (setq xl (- xl 6))
                     (setq ail (cons (list xl y) ail))
                     (setq nfixl (1+ nfixl))
                     (setq n (1+ n))
                     (if (< n nfix)
                        (progn
                           (setq xr (+ xr 6))
                           (setq ail (cons (list xr y) ail))
                           (setq nfixr (1+ nfixr))
                           (setq n (1+ n))
                        )
                     )   
                  )
               )
         )
         (if (< st (+ 2.25 (* 2 cover)))
            (progn 
               (setq slab_cov (rtos (/ (- st  2.25) 2) 4 2))
               (setq msg (strcat "Required cover can not be achieved for anchors in slab\nActual cover is " slab_cov)) 
               (alert msg)
            )
         )
      ) ;END PROGN
   ) ;END IF

                  ;INSERT ANCHORS
   
   (setq ip (car ail))
   (setq n 0)
   (setq r 0)
   (while (< n (length ail))
      (if (< n nfix)
          (setq r 90)
      )
      (command "insert" "c:/apps/PT_CAD/endview/anchor" ip "" "" r)
      (ssadd (entlast) ss)
      (setq n (1+ n))
      (setq ip (nth n ail))
      (setq r 0)      
   )      
) ;END DRAWANCH       
                                          ;;;DETERMINE ANCHOR IN REBAR LOCATION
(defun ainrloc (rsl rd cw bw rc off / marg na rll spx) ;REBAR SPACE LIST, REBAR DIA. , COLUMN WIDTH, BEAM WIDTH, REBAR COVER, HOR DIST FROM LL TO CL,
   (setq rll '())  ;INITIALIZE REBAR LOCATION LIST                                                SUM OF PREV. SPACINGS
           (setq ro (+ (- bw cw) off)) ;DETERMINE RIGHT OVERHANG OF BEAM IF ANY
           (if (> ro 0.0)
               (setq rsl (append rsl (list (- (+ ro rebcov rd) cover)))) ;ADD RIGHT OVHG SPA. TO SPA. LIST
           )
           
           (setq n 0)
           (setq l (length rsl))
           (setq sps 0.0)   ;INITIALIZE SUM OF PREVIOUS SPACINGS
           (if (< off 0.0) ;IF BEAM LL IS LEFT OF CL (BEAM OVERHANGS COLUMN ON LEFT SIDE)
              (progn
                 (setq cs (- (+ (abs off) rebcov rd (car rsl)) cover)) ;SET INITIAL CURRENT SPACING IF BEAM EXTENDS PAST COL. TO LEFT
                 (setq rsl (append (list cs) (cdr rsl))) ;REPLACE INITIAL SPACING IN REBAR SPACING LIST
                 (setq marg (- cover (/ rd 2.0))) ;DIST FROM LL TO CENTERLINE OF IMAGINARY FIRST BAR AT LEFT OVERHANG
                       ;(princ "\nmarg = ")(princ marg)
              )
              (progn
                 (setq marg (- (+ rc (/ rd 2.0) (car rsl)) off)) ;DIST FROM LL TO CENTERLINE OF FIRST BAR IF NO LEFT OVERHANG
                      ;(princ "\nmarg = ")(princ marg)
              )
           )  
                    ;(princ "\noff = ")(princ off)
                    ;(princ "\nRSL = ")(princ RSL)
           (while (< n l)
              (setq cs (nth n rsl))  ;INITIALIZE CURRENT SPACING
              (setq na 0)
              (if (>= (- cs rd)  minopen)
                 (progn             
                     (setq na1 (1+ (fix (/ (- cs rd 2.25) 3.0))))
                     (setq na2 (1+ (fix (/ (- cs rd 2.25) 2.5))))                 
                     (if (> na2 na1) ;DETERMINE NO. OF ANCHORS AND SPACING FOR A GIVEN OPENING IN REBAR
                        (progn
                           (setq na na2)
                           (setq s 2.5)
                        )
                        (progn
                           (setq na na1)
                           (setq s 3.0)
                        )
                     )
                 )
              )
              (setq centfac (/ (- (- cs rd) (* na s)) 2.0)) ;COMPUTE CENTERING FACTOR
                       ;(princ "\nCentering Factor = ")(princ centfac)
                       ;(princ "\nCS = ")(princ cs)
                       ;(princ "\nS = ")(princ s)
              (setq i 0)
                     ;(princ "\nna = ")(princ na)
              (while (and (< i na) (/= na 0))
                 (setq x (+ marg sps (* i s) (/ rd 2.0) (/ s 2.0) centfac)) ;DIST FROM LL TO ANCHOR INS. POINT
                 (setq rll (cons x rll))                   
                 (setq i (1+ i))
                         ;(princ "\nx = ")(princ x)
                         ;(princ "\nsps = ")(princ sps)                                                  
              ) ;END WHILE
              (if (or (/= n 0)(and (= n 0)(< off 0)))
                 (setq sps (+ sps cs)) ;INCREMENT SUM OF PREVIOUS SPACINGS                          
              )
              (setq n (1+ n))             
           ) ;END WHILE
           (reverse rll)
     
) ;END DEFUN      
           
(defun cantdo ()
   (alert "CGS TOO HIGH , REQUIRED ANCHORS CAN NOT BE INSTALLED - PROGRAM TERMINATED")
   (exit)
)          
             
(defun dimanch ()
   (setq ds (getvar "dimstyle"))
   (command "dim" "restore" "tick8" "dimlfac" (/ 1.0 sf))
   (setq pt1 ll)
   (setq pt2 (list (car ll) (+ (cadr ll) yab)))
   (setq vloc (list (- (car ll) (* 1.5 sf)) (cadr ll)))
   (setq n 0)
   (while (< n nr)
      (command "dim" "vert" pt1 pt2 vloc "") ;DIMENSION ANCHORS
      (setq pt1 pt2)
      (setq pt2 (list (car pt1) (+ (cadr pt2) vs)))
      (setq n (1+ n))
      (ssadd (entlast) ss)             
   )
   (setq cgspt (list (car lr) (+ (cadr lr) cgs)))
   (setq cgsloc (list (+ (car lr) (* 1.5 sf))(cadr lr)))
   (setvar "dimpost" "<> CGS")
   (command "vert" lr cgspt cgsloc "") ;DIMENSION CGS
   (setvar "dimpost" "")
   (ssadd (entlast) ss)             
   (if (> nfix 0)
      (progn
         (setq fap (car ail)) ;FIXED ANCHOR POINT
         (if (> (car fap) (car ll))
            (progn
               (setq fixdloc (list (+ (car lr)(* 2.0 sf)) (cadr lr))) ;FIXED ANCHOR DIM LOCATION
               (setq pt1 lr)
            )
            (progn
               (setq fixdloc (list (- (car ll)(* 2.0 sf)) (cadr ll)))
               (setq pt1 ll)
            )
         )
         (command "vert" pt1 fap fixdloc "")
         (ssadd (entlast) ss)
      )
   )   
   (command "restore" ds "e")

           ;;;CALL OUT BACKUP BARS
     
   (if (= colshape nil)
       (setq rn 0)
   )
   (setq nvertbu (fix(1+ (- nc rn))))  ;NO. OF VERTICAL BACK UP BARS
   (setq lvertbu (fix (- bd 3)))       ;LENGTH OF VERTICAL BACKUP BARS
   (setq nhorbu (fix(* 2 nri)))        ;NO. OF HOR. BACK UP BARS
   (setq lhorbu (fix(- bw 3)))         ;LENGTH OF HOR. BACKUP BARS
   (if (> nfixl 0)
      (setq lfixlbu (fix (1+ (* nfixl 6))))  ;LENGTH OF BACKUP BARS @ LEFT FIXED ANCHORS IF ANY
   )
   (if (> nfixr 0)   
      (setq lfixrbu (fix (1+ (* nfixr 6))))   ;LENGTH OF BACKUP BARS @ RIGHT FIXED ANCHORS IF ANY
   )
   (setq at_status (getvar "attdia"))         
   (setvar "attdia" 0)                       ;TURN OFF DIALOGUE BOX FOR ATTRIBUTES
   (setq ip (list (- (car ll) 10) (- (cadr ll) 22)))
   (if (> nvertbu 0)
      (progn
         (setq nvertbu (strcat (itoa nvertbu) " VERT"))
         (command "insert" "c:/apps/PT_CAD/rebar/backup_s.dwg" ip (/ (getvar "dimscale") sf) "" "" lvertbu nvertbu)
         (setq ip (list (+ (car ll) 12)(cadr ip)))
         (ssadd (entlast) ss)
      )
   )
   (if (> nhorbu 0)
      (progn
         (setq nhorbu (strcat (itoa nhorbu) " HOR"))
         (command "insert" "c:/apps/PT_CAD/rebar/backup_u.dwg" ip (/ (getvar "dimscale") sf) "" "" lhorbu nhorbu)
         (ssadd (entlast) ss)
      )
   )
   (if (> nfix 0)
      (progn
        (setq ip (list (- (car ll) 10)(- (cadr ll) 31)))     
         (if (/= lfixlbu lfixrbu)
            (progn
               (setq nhorbu (strcat "2" " HOR"))
               (if (> nfixl 0) ;IF FIXED ANCHORS IN SLAB AT LEFT
                  (progn           
                     (command "insert" "c:/apps/PT_CAD/rebar/backup_s.dwg" ip (/ (getvar "dimscale") sf) "" "" lfixlbu nhorbu)
                     (ssadd (entlast) ss)
                     (setq ip (list (+ (car ll) 12)(- (cadr ll) 31)))
                  )
               )
               (if (> nfixr 0) ;IF FIXED ANCHORS IN SLAB AT RIGHT
                  (progn           
                     (command "insert" "c:/apps/PT_CAD/rebar/backup_s.dwg" ip (/ (getvar "dimscale") sf) "" "" lfixrbu nhorbu)
                     (ssadd (entlast) ss)
                  ) 
               )
            )     
            (progn    ;IF FIXED ANCHORS OF EQUAL QUANTITY IN SLAB AT BOTH SIDES               
               (setq nhorbu (strcat "4" " HOR"))
               (command "insert" "c:/apps/PT_CAD/rebar/backup_s.dwg" ip (/ (getvar "dimscale") sf) "" "" lfixrbu nhorbu)
               (ssadd (entlast) ss)
            )                        
         )
      )
   )
   (setvar "attdia" at_status)   ;RESTORE ATTDIA STATUS
    
         ;;;CALL OUT BEAM SIZE
   (setq bmlabel (strcat (rtos bw 5 1) "X" (rtos bd 5 1)))                    
   (setq ip (list (+ (car ll) (/ bw 2.0)) (- (cadr ll) 8)))
   (command "text" "j" "m" ip "" bmlabel)
   (command "scale" "l" "" ip (/ 1.0 sf))
   (ssadd (entlast) ss)

           ;;;CALL OUT ANCHORS
   (setq atlass '(("D" " DEADEND") ("S" " STRESSEND") ("I" " INTERMEDIATE") ("U" "")))
   (setq ip (list (+ (car ll) (/ bw 2.0)) (- (cadr ll) 11)))
   (setq anchlab (strcat (itoa na) (cadr (assoc at atlass)) " ANCHORS"))
   (command "text" "j" "m" ip "" anchlab)
   (command "scale" "l" "" ip (/ 1.0 sf))
   (ssadd (entlast) ss)
)
 
   
   












   
   








          