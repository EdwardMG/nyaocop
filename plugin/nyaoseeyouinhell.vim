let g:rubocop_json_lines = "{}"
let g:rubopop = 0

fu! Echo(msg)
  echo a:msg
endfu

fu! Append(msg)
  let g:rubocop_json_lines = a:msg
endfu

fu! ProcessResults()
ruby << PROCESS
require 'json'

Ev.sign_define "cop", { text: "F", texthl: "RedText", linehl: "RedText" }
Ev.sign_unplace "cops"

messages = []

i = 1
JSON.parse(Var["g:rubocop_json_lines"])["files"].each do |f|
  f["offenses"].each_with_index do |o|
    unless o["correctable"]
      messages << "L#{o["location"]["start_line"]} #{o["message"]}"
      # "severity": "convention",
      # "message": "Style/Documentation: Missing top-level documentation comment for `class Blah`.",
      # "cop_name": "Style/Documentation",
      # "corrected": false,
      # "correctable": false,


      lnum = o["location"]["start_line"]
      # "location": {
      #   "start_line": 1,
      #   "start_column": 1,
      #   "last_line": 1,
      #   "last_column": 10,
      #   "length": 10,
      #   "line": 1,
      #   "column": 1
      # }

      Ev.sign_place(
        i, 'cops', "cop", Ev.bufnr,
        {lnum: lnum, priority: 99}
      )
      puts o.inspect
    end

    i += 1
  end
end

Ev.popup_close(Var["g:rubopop"]) if Var["g:rubopop"] > 0

if messages.length > 0
  Var["g:rubopop"] = Ev.popup_create(
    messages,
    { title:       'Cops',
     'padding':   [1,1,1,1],
     'line':      1,
     'col':       Var["&columns"],
     'pos':       'topright',
     'scrollbar': 1
    }
  )
end
PROCESS
:silent edit!
endfu

fu! RubocopStyle()
  " .. expand('%')
  call job_start(
  \   'rubocop --server --format json --config .rubocop.yml -A ',
  \   {
  \     'out_cb': {ch, msg -> Append(msg)},
  \     'close_cb': {ch -> ProcessResults()},
  \     'err_cb': {ch, msg -> Echo(msg)}
  \   }
  \ )
endfu

augroup nyaoseeyouinhell
  autocmd!
  au BufWritePost *.rb silent call RubocopStyle()
augroup END
