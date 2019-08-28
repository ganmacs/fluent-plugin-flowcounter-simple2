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

require 'fluent/plugin/input'
require_relative './flowcounter_simple2_helper'

module Fluent
  module Plugin
    class FlowcounterInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input('flowcounter_simple2', self)

      include Fluent::Plugin::FlowcounterSimple2Helper

      helpers :server

      config_set_default :comment, 'input_flowcounter'

      LISTEN_PORT = 24224

      desc 'The port to listen to.'
      config_param :port, :integer, default: LISTEN_PORT
      desc 'The bind address to listen to.'
      config_param :bind, :string, default: '0.0.0.0'

      def start
        super
        server_create_connection(:in_forward_server, @port, bind: @bind, &method(:handle_connection))
      end

      def handle_connection(conn)
        conn.data do |data|
          begin
            unpacker = Fluent::Engine.msgpack_factory.unpacker
            unpacker.feed_each(data) do |msg|
              next if msg.nil?

              unless msg.is_a?(Array)
                # broken
                next
              end

              entries = msg[1]
              case entries
              when String
                o = msg[2]
                if o && o['size']
                  flowcounter_input_count2(o['size'].to_i)
                  next
                end
              when Array
                flowcounter_input_count(msg[1][1]) # TODO
              else
                flowcounter_input_count(msg[1])
              end
            end
          rescue => _
            # nothing
          end
        end
      end
    end
  end
end
