# N.B. this file is intentionally not formatted.  
# Its `.expect` equivalent contains the expected formatting result. 

discard """
  discard that works as a multiline comment.
	Or for unparsable, broken code

     Same as with classic `nimpretty`, indentation inside should not change.
		   ...
"""

proc main() =
  discard """
    discard that works as a multiline comment.
  	Or for unparsable, broken code
  
       Same as with classic `nimpretty`, indentation inside should not change.
  		   ...
  """
  var mlStr = """
    Multiline strings should not change indentation.
    4 space indent
	Tab indent
  2 space indented

No indent, blank above.
  """

  echo(ml_str  )


main()



