function func_descriptions --description "$USER - Generates csv output of function,description"
  # TODO - make this faster for users by searching in func dir
  if test (count $argv) -gt 0
    for option in $argv
      switch "$option"
          case -u --udf
            for func in (functions)
              set -l desc (functions $func | grep -o 'description .*' | head -n1 | grep "$USER" | cut -d' ' -f2- | string trim | cut -c -80 | sed 's/,/;/g')
              if not test -z $desc
                echo $func,$desc
              else
                echo $func,No description provided...
              end
            end
          case \*
              printf "error: Unknown option %s\n" $option
      end
    end
  else
    for func in (functions -a)
      set -l desc (functions $func | grep -o 'description .*' | head -n1 | cut -d' ' -f2- | string trim | cut -c -80 | sed 's/,/;/g')
      if not test -z $desc
        echo $func,$desc
      else
        echo $func,No description provided...
      end
    end
  end
end

