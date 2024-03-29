type t =
  | JString of string
  | JBool of bool
  | JInt of int
  | JArray of t list
  | JNull
  | JObject of (string * t) list

module Printing = struct
  let pp_comma fmt () = Format.pp_print_string fmt ","

  let rec to_string = function
    | JString str -> Printf.sprintf "%S" str
    | JBool b -> Printf.sprintf "%b" b
    | JInt i -> string_of_int i
    | JArray jsons ->
       "[" ^ String.concat ", " (List.map to_string jsons) ^ "]"
    | JNull -> "null"
    | JObject obj ->
       let field_to_string (nm, json) =
         Printf.sprintf "%S: %s" nm (to_string json)
       in
       "{" ^ String.concat ", " (List.map field_to_string obj) ^ "}"

  (* FIXME: move to a Utf8_string module *)
  let json_escape fmt s =
    let s = Utf8_string.of_string_unsafe s in
    (* FIXME *)
    let b = Buffer.create (Utf8_string.byte_length s + 4) in
    let escape_char c =
      if c = Uchar.of_char '"' then Buffer.add_char b '"'
      else if c = Uchar.of_char '\\' then Buffer.add_char b '\\'
      else if c = Uchar.of_char '\n' then Buffer.add_string b "\\n"
      else if c = Uchar.of_char '\x0c' then Buffer.add_string b "\\f"
      else if c = Uchar.of_char '\t' then Buffer.add_string b "\\t"
      else if c = Uchar.of_char '\r' then Buffer.add_string b "\\r"
      else if c = Uchar.of_char '\b' then Buffer.add_string b "\\b"
      else Buffer.add_utf_8_uchar b c
    in
    Utf8_string.iter escape_char s;
    Format.pp_print_string fmt (Buffer.contents b)

  let pp_string fmt s =
    Format.fprintf fmt "\"%a\"" json_escape s
  let pp_delim =
    Format.pp_print_string

  let rec pp fmt = function
    | JString s -> pp_string fmt s
    | JBool true -> Format.pp_print_string fmt "true"
    | JBool false -> Format.pp_print_string fmt "false"
    | JInt i -> Format.pp_print_int fmt i
    (*  | Float f -> Format.pp_print_float fmt f (* FIXME: proper format *) *)
    | JNull -> Format.pp_print_string fmt "null"
    | JArray [] ->
       Format.pp_print_string fmt "[]"
    | JArray elems ->
       Format.fprintf fmt "%a@,@[<v2>  %a@]@,%a"
         pp_delim "["
         (Format.pp_print_list ~pp_sep:pp_comma pp) elems
         pp_delim "]"
    | JObject [] ->
       Format.pp_print_string fmt "{}"
    | JObject fields ->
        Format.fprintf fmt "%a@,@[<v2>  %a@]@,%a" pp_delim "{"
          (Format.pp_print_list ~pp_sep:pp_comma pp_field)
          fields pp_delim "}"

  and pp_field fmt (nm, json) = Format.fprintf fmt "%a: %a" pp_string nm pp json
end
