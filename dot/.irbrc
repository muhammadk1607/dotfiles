# This gem needs to installed
require 'rainbow'

def app_prompt
  rails_klass = Rails.application.class

  app_name =
    if rails_klass.respond_to? :module_parent
      rails_klass.module_parent
    else
      rails_klass.parent
    end

  Rainbow("#{app_name.name}").blue
end

# target log path for irb history
def log_path
  rails_root = Rails.root
  "#{rails_root}/log/.irb-save-history"
end

def env_prompt
  case Rails.env
  when "development"
    Rainbow("development").green
  when "production"
    Rainbow("production").red
  else
    Rainbow("#{Rails.env}").yellow
  end
end

if defined?(Rails)
  IRB.conf[:USE_AUTOCOMPLETE] = true
  IRB.conf[:HISTORY_FILE] = FileUtils.touch(log_path).join
  IRB.conf[:PROMPT] ||= {}

  prompt = "#{app_prompt}[#{env_prompt}]:%03n "

  IRB.conf[:PROMPT][:RAILS_EMOJI] = {
    PROMPT_I: "#{prompt}\u{1F600}  >",
    PROMPT_N: "#{prompt}\u{1F609}  >",
    PROMPT_S: "#{prompt}\u{1F606}  >",
    PROMPT_C: "#{prompt}\u{1F605}  >",
    RETURN: "  => %s\n"
  }

  IRB.conf[:PROMPT_MODE] = :RAILS_EMOJI
end
