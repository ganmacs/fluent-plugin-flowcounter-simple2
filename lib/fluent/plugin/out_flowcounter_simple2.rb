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
require_relative './flowcounter_simple2_helper'

module Fluent
  module Plugin
    class FlowcounterOut < Fluent::Plugin::Output
      Fluent::Plugin.register_output('flowcounter_simple2', self)

      include Fluent::Plugin::FlowcounterSimple2Helper
      config_set_default :comment, 'out_flowcounter'

      def multi_workers_ready?
        true
      end

      def write(chunk)
        flowcounter_out_count(chunk)
      end

      def try_write(chunk)
        flowcounter_out_count(chunk)
        commit_write(chunk.unique_id)
      end
    end
  end
end
