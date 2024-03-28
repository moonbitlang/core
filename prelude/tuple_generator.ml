let generate length =
  let indicies = List.init length (fun i -> i) in
  let types = List.init length (fun i -> Printf.sprintf "T%d" i) in
  let type_parameter =
    types |> List.map (fun t -> Printf.sprintf "%s: Eq" t) |> String.concat ", "
  in
  let tuple_type = Printf.sprintf "(%s)" (types |> String.concat ", ") in
  let signature =
    "pub fn op_equal["
    ^ type_parameter
    ^ "](self: "
    ^ tuple_type
    ^ ", other: "
    ^ tuple_type
    ^ ") -> Bool"
  in
  let body =
    indicies
    |> List.map (fun i -> Printf.sprintf "self.%d == other.%d" i i)
    |> String.concat " && "
  in
  Printf.sprintf "%s {\n  %s\n}\n" signature body
;;

let () =
  let length = int_of_string Sys.argv.(1) in
  for i = 2 to length do
    Printf.printf "%s\n" (generate i)
  done
;;
