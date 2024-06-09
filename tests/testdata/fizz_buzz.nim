# N.B. this file is intentionally not formatted.  
# It's `.expect` equivalent contains the expected formatting result. 

proc main( )  =  
  ## Docstring: FizzBuzz.
  for n  in 1..100:
    if n mod 3 ==   0 and n mod 5   == 0:  
      echo "FizzBuzz"
    elif n   mod 3 == 0:
      echo "Fizz"
    elif n mod   5 == 0:
      echo "Buzz"  
    else:
      echo  n

main(  )
