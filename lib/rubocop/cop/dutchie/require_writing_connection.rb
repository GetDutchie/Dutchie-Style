# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Dutchie
      # Flags write calls that aren't explicitly wrapped in
      # `connected_to(role: :writing)`.
      #
      # ActiveRecord::Middleware::DatabaseSelector routes GET requests to a
      # read replica by default. Code that can be reached from a GET request
      # but still performs a write must force the writing role, or the write
      # will raise ActiveRecord::ReadOnlyError (or misbehave during an RDS
      # failover). This cop is scoped (via Include in config/default.yml) to
      # the files/directories known to contain that kind of code.
      #
      # @example
      #   # bad
      #   def attempt_create
      #     create_unique_code
      #   end
      #
      #   # good
      #   def attempt_create
      #     ApplicationRecord.connected_to(role: :writing) { create_unique_code }
      #   end
      class RequireWritingConnection < ::RuboCop::Cop::Base
        MSG = 'Wrap this write in `connected_to(role: :writing)`. This code can be reached from a GET ' \
              'request, which ActiveRecord::Middleware::DatabaseSelector routes to a read replica, and an ' \
              'unwrapped write there will raise ActiveRecord::ReadOnlyError.'

        WRITE_METHODS = %i[
          create create! save save! update update! update_all
          destroy destroy! delete delete_all touch
          increment! decrement! upsert insert insert_all toggle!
        ].freeze

        def_node_matcher :connected_to_writing?, <<~PATTERN
          (send _ :connected_to (hash <(pair (sym :role) (sym :writing)) ...>))
        PATTERN

        def on_send(node)
          return unless WRITE_METHODS.include?(node.method_name)
          return if wrapped_in_writing_block?(node)

          add_offense(node)
        end

        private

        def wrapped_in_writing_block?(node)
          node.each_ancestor(:block, :numblock).any? do |ancestor|
            connected_to_writing?(ancestor.send_node)
          end
        end
      end
    end
  end
end
