fu! s:Setup()
ruby << NYAOCOP
require 'json'

module NyaoCop
  @results = "{}"
  @rubopop = 0

  def self.error(msg)   = puts msg
  def self.iter_cb(msg) = @results = msg

  def self.process_results
    Ev.sign_define "cop", { text: "F", texthl: "RedText", linehl: "RedText" }
    Ev.sign_unplace "cops"

    messages = []

    i = 1
    JSON.parse(@results)["files"]&.each do |f|
      f["offenses"]&.each do |o|
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
        end

        i += 1
      end
    end

    Ev.popup_close(@rubopop) if @rubopop > 0

    if messages.length > 0
      @rubopop = Ev.popup_create(
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
    Ex.silent 'edit!'
  end

  def self.run
    args = "--server --format json -A"
    args << " --config .rubocop.yml" if File.exist?(".rubocop.yml")
    env = (File.exist?("Gemfile") || File.exist?(".bundle")) ? "bundle exec" : ""

    Ev.job_start(
      "#{env} rubocop #{args} " + Ev.expand('%:p'),
      {
        'out_cb':   "{ch, msg -> rubyeval('NyaoCop.iter_cb Var.msg')}".lit,
        'close_cb': "{ch      -> rubyeval('NyaoCop.process_results')}".lit,
        'err_cb':   "{ch, msg -> rubyeval('NyaoCop.error Var.msg')}".lit
      }
    )
  end
end
NYAOCOP
endfu

call s:Setup()

augroup nyaoseeyouinhell
  autocmd!
  au BufWritePost *.rb silent ruby NyaoCop.run
augroup END
