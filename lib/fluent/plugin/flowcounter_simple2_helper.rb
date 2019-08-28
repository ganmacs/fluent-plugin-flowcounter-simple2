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

module Fluent
  module Plugin
    module FlowcounterSimple2Helper
      def self.included(klass)
        klass.helpers :timer

        klass.config_param :delay_commit, :bool, default: false
        klass.config_param :indicator, :string, default: 'num'
        klass.config_param :unit, :string, default: 'second'
        klass.config_param :comment, :string
      end

      UNIT_TABLE = {
        second: 1,
        minute: 60,
        hour: 60 * 60,
        day: 60 * 60 * 24,
      }.freeze

      def initialize(*)
        super

        @count = 0
        @mutex = Mutex.new
      end

      def prefer_delayed_commit
        @delay
      end

      def configure(conf)
        super

        @flowcounter_indicator_proc =
          case @indicator
          when 'num'
            proc { |c| c.size }
          when 'byte'
            proc { |c| c.bytesize }
          else
            raise Fluent::ConfigError, 'flowcounter-simple2 count allows num/byte'
          end

        @flowcounter_indicator_proc2 =
          case @indicator
          when 'num'
            proc { |_| 1 }
          when 'byte'
            proc { |r| Fluent::MessagePackFactory.thread_local_msgpack_packer.pack(r).full_pack.size }
          else
            raise Fluent::ConfigError, 'flowcounter-simple2 count allows num/byte'
          end

        unless %w[second minute hour day].include?(@unit)
          raise Fluent::ConfigError, 'flowcounter unit allows second/minute/hour/day'
        end
        @tick = UNIT_TABLE[@unit.to_sym]
        unless @tick
          raise RuntimeError, '`unit` must be one of second/minute/hour/day'
        end

        @flowcounter_output_proc =
          if @comment
            proc { |count| "plugin:out_flowcounter_simple2\tcount:#{count}\tindicator:#{@indicator}\tunit:#{@unit}\tcomment:#{@comment}" }
          else
            proc { |count| "plugin:out_flowcounter_simple2\tcount:#{count}\tindicator:#{@indicator}\tunit:#{@unit}" }
          end
      end

      def start
        super

        t = Time.now.to_i
        timer_execute("flowcounter_#{t}".to_sym, @tick) do
          flowcounter_log
        end
      end

      private

      def flowcounter_packer
        if Fluent::MessagePackFactory.respond_to?(:thread_local_msgpack_packer)
          Fluent::MessagePackFactory.thread_local_msgpack_packer
        else
          Thread.current[:local_msgpack_packer] ||= MessagePackFactory.engine_factory.packer
        end
      end

      def flowcounter_out_count(chunk)
        count = @flowcounter_indicator_proc.call(chunk)
        @mutex.synchronize do
          @count += count
        end
      end

      def flowcounter_filter_count(record)
        count = @flowcounter_indicator_proc2.call(record)
        @mutex.synchronize do
          @count += count
        end
      end

      def flowcounter_log
        count = 0
        @mutex.synchronize do
          count = @count
          @count = 0
        end

        if count == 0
          return
        end

        log.info(@flowcounter_output_proc.call(count))
      end
    end
  end
end
