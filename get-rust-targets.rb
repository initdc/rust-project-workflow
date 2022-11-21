def get_rustc_targets
  cmd = "rustc --print target-list"
  IO.popen(cmd) do |r|
      lines = r.readlines
      return nil if lines.empty?

      targets = []
      for line in lines
          target = line.delete_suffix "\n"
          targets.push target
      end
      return targets
  end
rescue
  return nil        
end

def get_rustup_targets
  cmd = "rustup target list"
  IO.popen(cmd) do |r|
      lines = r.readlines
      return nil if lines.empty?

      targets = []
      for line in lines
          target = line.delete_suffix("\n").delete_suffix(" (installed)")
          targets.push target
      end
      return targets
  end
rescue
  return nil        
end

if __FILE__ == $0
  pp get_rustc_targets
  pp get_rustup_targets
end
