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
    def initialize(log, machine_stats: true)
      @stats = []
      @mem = []

      @log = log
      @machine_stats = machine_stats
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

      txt = "flowcounter_simple2_total\tsample:#{size}\tmax:#{@stats.max}\tmin:#{@stats.min}"
      total = @stats.reduce(0, &:+)
      txt += "\tavg:#{total/size}"

      @stats.sort!
      unless @stats.empty?
        txt += "\tp10:#{@stats[(size * 0.1).to_i]}\tp50:#{@stats[(size * 0.5).to_i]}\tp80:#{@stats[(size * 0.8).to_i]}\tp90:#{@stats[(size * 0.9).to_i]}\tp95:#{@stats[(size * 0.95).to_i]}\tp98:#{@stats[(size * 0.98).to_i]}"
      end

      if @machine_stats
        t = @mem.reduce(0, &:+) / @mem.size
        txt += "\tmem_avg:#{t}MB"
      end

      @log.info(txt)
    end
  end
end
