require 'set'

# Diff 2 hashes to show the added, changed, and removed keys
class HashDiff
  class << self
    def diff(target, current)
      target_keys = Set.new target.keys
      current_keys = Set.new current.keys
      added = target_keys - current_keys
      removed = current_keys - target_keys
      changed = target.keys.select { |k| !current[k].nil? && target[k] != current[k] }
      [added, changed, removed]
    end
  end
end