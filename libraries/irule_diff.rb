require 'set'

# Diff 2 hashes to show the added, changed, and removed keys
class IRuleDiff
  class << self
    def diff_hashes(target, current)
      target_keys = Set.new target.keys
      current_keys = Set.new current.keys
      added = target_keys - current_keys
      removed = current_keys - target_keys
      changed = target.keys.select { |k| !current[k].nil? && target[k] != current[k] }
      [added, changed, removed, target]
    end

    def diff(target, current_hash)
      current_ordered = current_hash.sort_by { |_, val| val }.map(&:first)
      return [[], [], [], {}] if target == current_ordered
      used_priorities = current_hash.values.map(&:to_i)
      min = used_priorities.min || 0
      target_hash = target.each_with_object({}) do |t, out|
        current_priority = current_hash[t].nil? ? nil : current_hash[t].to_i
        if current_priority.is_a?(Integer) && current_priority > min
          min = current_priority
          out[t] = current_priority.to_s
          used_priorities << current_priority
        else
          new_priority = next_priority(min, current_priority, used_priorities)
          used_priorities << new_priority
          min = new_priority
          out[t] = new_priority.to_s
        end
      end
      diff_hashes target_hash, current_hash
    end

    def next_priority(min, current_priority, used_priorities)
      i = min
      i += 1 while used_priorities.include?(i) && current_priority != i
      i
    end
  end
end
