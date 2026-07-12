# frozen_string_literal: true

module SharedTools
  # Validates the executable name for BashTool and ProcessStartTool. The
  # actual execution path uses array-form spawning (no shell), so this guard
  # only has to ensure the program itself is on the allowlist and isn't
  # smuggling a path or shell metacharacters. Arguments are passed verbatim as
  # argv and are therefore inert — there is no shell to interpret them.
  class CommandGuard
    class Blocked < StandardError; end

    SHELL_META = /[;&|<>`$(){}\[\]*?!#~\n\r]/
    PATH_SEP = %r{[/\\]}

    def initialize(allowed)
      @allowed = Array(allowed).map(&:to_s)
    end

    # Returns the validated executable name, or raises Blocked.
    def check!(command)
      cmd = command.to_s
      raise Blocked, "no command given" if cmd.empty?

      raise Blocked, "executable name may not contain a path: #{cmd.inspect}" if cmd.match?(PATH_SEP)
      raise Blocked, "executable name may not contain shell metacharacters: #{cmd.inspect}" if cmd.match?(SHELL_META)

      unless @allowed.include?(cmd)
        raise Blocked, "command not allowed: #{cmd.inspect} " \
                       "(allowed: #{@allowed.empty? ? '(none)' : @allowed.join(', ')})"
      end

      cmd
    end
  end
end
