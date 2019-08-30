# frozen_string_literal: true

#
# Copyright 2019- Yuta Iwama
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/output'
require 'get_process_mem'

module Fluent::Plugin
  class Stats
    def initialize(log, machine_stats: true, file_path: '')
      @stats = []
      @mem = []

      @log = log
      @machine_stats = machine_stats
      unless file_path.empty?
        require 'json'
        require 'pathname'
        require 'fileutils'
        file_path = Pathname(file_path)
        # FIXME
        FileUtils.mkdir_p(file_path.dirname)
        @name = file_path.basename.to_s.gsub('.json', '')
        @file_path = file_path
      end
    end

    def inc(r)
      unless r.zero?
        @stats << r

        if @machine_stats
          @mem << GetProcessMem.new.mb
        end
      end
    end

    def cal
      size = @stats.size
      if size < 0
        return
      end

      total = @stats.reduce(0, &:+)

      ret = {
        smaple: size,
        max: @stats.max,
        min: @stats.min,
        avg: total / size,
      }

      @stats.sort!
      unless @stats.empty?
        ret.merge!(
          p10: @stats[(size * 0.1).to_i],
          p50: @stats[(size * 0.5).to_i],
          p80: @stats[(size * 0.8).to_i],
          p90: @stats[(size * 0.90).to_i],
          p98: @stats[(size * 0.98).to_i],
        )
      end

      if @machine_stats
        t = @mem.reduce(0, &:+) / @mem.size
        ret[:mem_avg] = "#{t}MB"
      end

      if @file_path
        File.write(@file_path, ret.merge(name: @name).to_json)
      end

      @log.info("flowcounter_simple2_total\t" + ret.map { |k, v| "#{k}:#{v}" }.join("\t"))
    end
  end
end
