open Ulmus.Html

type 'action opt =
  | Option of bool * [ `Disabled | `Enabled ] * bool * 'action * 'action html
  | Group of string * 'action options

and 'action options = 'action opt list

let make ?(attrs = []) options =
  let mapping = Hashtbl.create 64 in
  let handler value = Hashtbl.find mapping value in
  let rec render_options i accum = function
    | [] -> (i, accum)
    | Option (selected, status, hidden, action, label) :: options ->
        let value = string_of_int i in
        let entry =
          let attrs =
            [
              A.value value;
              A.disabled
                (match status with `Disabled -> true | `Enabled -> false);
            ]
          in
          let attrs = if selected then A.selected true :: attrs else attrs in
          let attrs = if hidden then A.hidden true :: attrs else attrs in
          option ~attrs label
        in
        Hashtbl.add mapping value action;
        render_options (i + 1) (accum ^^ entry) options
    | Group (label, group_options) :: options ->
        let i, entries = render_options i empty group_options in
        let entry = optgroup ~attrs:[ A.label label ] entries in
        render_options (i + 1) (accum ^^ entry) options
  in
  let _, rendered_options = render_options 0 empty options in
  select ~attrs:(E.onchange handler :: attrs) rendered_options

let option ?(selected = false) ?(enabled = true) ?(hidden = false) ~action label
    =
  Option
    (selected, (if enabled then `Enabled else `Disabled), hidden, action, label)

let group ~label options = Group (label, options)
