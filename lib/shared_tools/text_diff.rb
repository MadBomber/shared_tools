# frozen_string_literal: true

module SharedTools
  # Line-based diff via longest-common-subsequence, used by DiffTool. Produces
  # a readable diff ('-'/'+'/' ' prefixes) with long unchanged runs elided.
  # Pure stdlib, no external dependency.
  module TextDiff
    module_function

    def unified(old_text, new_text, old_label: "old", new_label: "new", context: 3)
      a = old_text.to_s.lines
      b = new_text.to_s.lines
      ops = diff_ops(a, b)
      return "(no differences)" if ops.all? { |type, _| type == :eq }

      render(ops, old_label, new_label, context)
    end

    def diff_ops(a, b)
      n = a.size
      m = b.size
      lcs = Array.new(n + 1) { Array.new(m + 1, 0) }
      (n - 1).downto(0) do |i|
        (m - 1).downto(0) do |j|
          lcs[i][j] = a[i] == b[j] ? lcs[i + 1][j + 1] + 1 : [lcs[i + 1][j], lcs[i][j + 1]].max
        end
      end

      ops = []
      i = 0
      j = 0
      while i < n && j < m
        if a[i] == b[j]
          ops << [:eq, a[i]]
          i += 1
          j += 1
        elsif lcs[i + 1][j] >= lcs[i][j + 1]
          ops << [:del, a[i]]
          i += 1
        else
          ops << [:add, b[j]]
          j += 1
        end
      end
      ops.concat(a[i..].map { |line| [:del, line] }) if i < n
      ops.concat(b[j..].map { |line| [:add, line] }) if j < m
      ops
    end

    def render(ops, old_label, new_label, context)
      out = ["--- #{old_label}", "+++ #{new_label}"]
      i = 0
      while i < ops.size
        type, line = ops[i]
        if type == :eq
          run = []
          while i < ops.size && ops[i][0] == :eq
            run << ops[i][1]
            i += 1
          end
          emit_context(out, run, context)
        else
          out << "#{type == :del ? '-' : '+'} #{line.chomp}"
          i += 1
        end
      end
      out.join("\n")
    end

    def emit_context(out, run, context)
      if run.size > (context * 2) + 1
        run.first(context).each { |line| out << "  #{line.chomp}" }
        out << "  ⋮ (#{run.size - (context * 2)} unchanged lines)"
        run.last(context).each { |line| out << "  #{line.chomp}" }
      else
        run.each { |line| out << "  #{line.chomp}" }
      end
    end
  end
end
