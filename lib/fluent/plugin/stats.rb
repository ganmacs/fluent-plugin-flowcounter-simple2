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

module Fluent::Plugin
  class Stats
    def initialize(log)
      @count = 0
      @num = 0
      @total = 0
      @max = 0
      @min = 100000000
      @p = []
      @log = log
    end

    def inc(r)
      unless r.zero?
        @p << r
        if @max < r
          @max = r
        end

        if @min > r
          @min = r
        end

        @total += r
        @num += 1
      end
    end

    def cal
      txt = "flowcounter_simple2_total\tsample:#{@num}\tmax:#{@max}\tmin:#{@min}\t"
      if @num != 0
        txt += "avg:#{@total/@num}\t"
      end

      @p.sort!
      s = @p.size
      unless @p.empty?
        txt += "p10:#{@p[(s * 0.1).to_i]}\tp50:#{@p[(s * 0.5).to_i]}\tp80:#{@p[(s * 0.8).to_i]}\tp90:#{@p[(s * 0.9).to_i]}\tp95:#{@p[(s * 0.95).to_i]}\tp98:#{@p[(s * 0.98).to_i]}"
      end
      @log.info(txt)
    end
  end
end
