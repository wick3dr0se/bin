#!/usr/bin/env bash
jq -rc '
  if type=="array" and (.[0]? | type=="object") then
    (.[0] | keys_unsorted) as $keys |
    ("array:" + ($keys|join(","))),
    (map([.[$keys[]] | if type=="object" or type=="array" then tojson else tostring end] | join(",")) | .[])
  elif type=="object" then
    # Helper function still needed for recursion
    def flatten_compact(path):
      if (to_entries | map(.value | type == "object" or type == "array") | any | not) then
        [(path | join(".")), (to_entries | map(.key) | join(",")), (to_entries | map(.value | tostring) | join(","))]
      else
        to_entries[] | 
        (.key as $k | .value as $v |
          if $v | type == "object" then
            $v | flatten_compact(path + [$k])
          elif $v | type == "array" then
            [(path + [$k] | join(".")), ($v | tojson)]
          else
            [(path + [$k] | join(".")), ($v | tostring)]
          end
        )
      end;
    
    to_entries[] |
      if (.value | type=="array") and (.value[0]? | type=="object") then
        (.value) as $arr |
        ($arr[0] | keys_unsorted) as $keys |
        (.key + ":" + ($keys|join(","))),
        ($arr | map([.[$keys[]] | if type=="object" or type=="array" then tojson else tostring end] | join(",")) | .[])
      elif (.value | type=="object") then
        (.key as $k | .value | flatten_compact([$k]) | 
          if length == 3 then
            .[0] + ":" + .[1],
            .[2]
          elif length == 2 then
            .[0] + ":" + .[1]
          else
            .[]
          end
        )
      else
        .key + ":" + (.value | tostring)
      end
  else
    tostring
  end
' "$@"