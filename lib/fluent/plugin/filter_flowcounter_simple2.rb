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

require 'fluent/plugin/filter'
require_relative './flowcounter_simple2_helper'

module Fluent
  module Plugin
    class FlowcounterSimple2Fileter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter('flowcounter_simple2', self)

      include Fluent::Plugin::FlowcounterSimple2Helper
      config_set_default :comment, 'filter_flowcounter'

      def multi_workers_ready?
        true
      end

      def filter(_tag, _time, record)
        flowcounter_filter_count(record)
        record
      end
    end
  end
end
