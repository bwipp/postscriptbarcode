;;;
;;; Barcode generator for AIT tapes
;;;
;;;
;;; Copyright (C) 2005 by Greg Menke, gregm-news@toadmail.com
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License
;;; as published by the Free Software Foundation; either version 2
;;; of the License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;;;
;;; http://www.gnu.org/licenses/gpl.html
;;;
;;;
;;;
;;; Uses the Pure Postscript Barcode Generator:
;;;   http://bwipp.terryburton.co.uk
;;;
;;;
;;;
;;; This script can be run by most any Common Lisp implementation.
;;; Unless you have one installed already, CLISP is generally the
;;; most broadly available and quickest to install.  CLISP is available
;;; an binary and source forms at 
;;;
;;; http://clisp.cons.org/
;;;
;;;
;;; To run the script using CLISP, invoke the following in the same
;;; directory where the Pure Postscript files were extracted.
;;;
;;; clisp -q ait-tape.lisp | lp
;;;
;;; This assumes 'lp' has a default printer that accepts postscript,
;;; modify as required to direct the output properly.
;;;


(defstruct pagedef 
  (pane-rows) 
  (pane-cols) 
  (pane-width)
  (pane-height)
  (pane-inside-horizontal)
  (pane-inside-vertical)
  (left-pane-offset)
  (top-pane-offset)
  (pane-divider-width)
  (pane-divider-height))


;;;
;;; postscript points are 1/72"
;;;
(defparameter %DPI%	72)


(defun make-barcode-coordinates (pdef)
  (let* ((bc-coords             nil) 
	 (bc-width		(* %WIDTH-PER-CODE%  %DPI%))
	 (bc-height		(* %HEIGHT-PER-CODE% %DPI%))

	 (pane-width		(* (pagedef-pane-width pdef)  %DPI%))
	 (pane-height		(* (pagedef-pane-height pdef) %DPI%))

	 (pane-inside-hor	(* (pagedef-pane-inside-horizontal pdef) %DPI%))
	 (pane-inside-vert      (* (pagedef-pane-inside-vertical pdef)   %DPI%))

	 (pane-offset-x		(* (pagedef-left-pane-offset pdef) %DPI%))
	 (pane-offset-y		(* (pagedef-top-pane-offset pdef)  %DPI%))
	   
	 (pane-divider-width	(* (pagedef-pane-divider-width pdef)  %DPI%))
	 (pane-divider-height	(* (pagedef-pane-divider-height pdef) %DPI%)) )
				
				
    (let ((bcodes-per-pane-horiz	(floor (/ pane-width  (+ bc-width  (* pane-inside-hor 2)))) )
	  (bcodes-per-pane-vert		(floor (/ pane-height (+ bc-height (* pane-inside-vert 2)))) ) )


      (loop for pcol from 0 below (pagedef-pane-cols pdef)
	    for basex = (+ pane-offset-x (* pcol pane-width) (* pcol pane-divider-width))
	    do

	    (loop for prow from 0 below (pagedef-pane-rows pdef)
		  for basey = (+ pane-offset-y (* prow pane-height) (* prow pane-divider-height))
		  do

		  (loop for bcol from 0 below bcodes-per-pane-horiz
			for barcodex = (+ basex (* bcol bc-width) pane-inside-hor)
			do
			(loop for brow from 0 below bcodes-per-pane-vert
			      for barcodey = (+ basey (* brow bc-height) pane-inside-vert bc-height)
			      do

			      (push (list (floor barcodex) (floor barcodey)) 
				    bc-coords) )))) )

    (coerce (reverse bc-coords) 'vector) ))










(defun print-strings ( slist )
  "Print each postscript string to standard-output, terminating with newlines"
    (loop for e in slist
	  do
	  (cond ((typep e 'cons)
		 (print-strings e))
		 
		(t
		 (format *standard-output* "~A~%" e)) ) ))








(defun bcode (bcode pagedef startval endval &optional (opts ""))
  "Create the barcode postscript strings, then print them"

  (let* ((prolog-strings	'("%!PS-Adobe-2.0"))

	 (template-strings	(with-open-file (str "barcode.ps" 
						     :direction :input 
						     :if-does-not-exist :error)
				   ;; skip file text till we hit BEGIN TEMPLATE
				   (loop for l = (read-line str nil nil)
					 while (and l 
						    (not (search "% --BEGIN TEMPLATE--" l))) )
				   ;; now inside template
				   (loop for l = (read-line str nil nil)
					 while (and l 
						    (not (search "% --END TEMPLATE--" l)))
					 collect l)) )


	 (content-opts		(concatenate 'string 
					     opts
					     (format nil " height=~D " %BOPT-HEIGHT%)) )


	 (content-strings	(loop with bc-coords = (make-barcode-coordinates pagedef)

				      for i from startval upto endval
				      for j from 0 below (length bc-coords)

				      collect (list "gsave"

						    (destructuring-bind (x y) (svref bc-coords j)
						       (format nil "~D ~D translate" x y))

						    (format nil 
							    "0 0 moveto (~A) (~A) ~A barcode" 
							    (format nil "~6,'0D" i)
							    content-opts 
							    bcode)

						    "grestore")) )

	 (epilog-strings        '("showpage")) )
    ;;
    ;; now accumulate the strings and print them in order
    ;;
    (print-strings (append prolog-strings
			   template-strings
			   content-strings
			   epilog-strings)) ))






;;;
;;; Parameters in inches
;;;

(defparameter %WIDTH-PER-CODE%		2.250 )
(defparameter %HEIGHT-PER-CODE%		0.375 )
(defparameter %BOPT-HEIGHT%		0.24 )




;;;
;;; Page definitions, in inches
;;;
(defparameter %avery-6873%    (make-pagedef :pane-rows  4              :pane-cols 2
					    :pane-width 3.75           :pane-height 2.00
					    :pane-inside-horizontal 0.062
					    :pane-inside-vertical   0.062
					    :left-pane-offset 0.375    :top-pane-offset 1.125
					    :pane-divider-width 0.250  :pane-divider-height 0.250))



;;;
;;; Adjust parameters of this call to select the barcode format,
;;; text numbers and text options
;;;

(bcode "code39" %avery-6873% 10 40 "includetext includecheck")
    
;;; eof
