# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Dutchie
      # Flags usage of safety_assured in migrations
      #
      # The safety_assured block bypasses strong_migrations safety checks,
      # which should only be used when you're certain the operation is safe
      # and have documented why it's necessary.
      #
      # @example
      #   # bad
      #   def change
      #     safety_assured do
      #       remove_column :users, :email
      #     end
      #   end
      #
      #   # good - avoid safety_assured when possible
      #   def change
      #     # Use strong_migrations approved patterns instead
      #     remove_column :users, :email, type: :string
      #   end
      #
      #   # acceptable - with clear documentation
      #   def change
      #     # This operation is safe because:
      #     # 1. The column was already removed from the model
      #     # 2. No code references this column anymore
      #     # 3. We've verified in production logs that no queries use this column
      #     safety_assured do
      #       remove_column :users, :deprecated_field
      #     end
      #   end
      #
      class MigrationSafetyAssured < ::RuboCop::Cop::Base
        MSG = 'Avoid `safety_assured` in migrations. It bypasses strong_migrations safety checks. ' \
              'Ensure this operation is truly safe, consider safer alternatives, and document why ' \
              'safety_assured is necessary.'

        # Matches: safety_assured do...end or safety_assured {...}
        def_node_matcher :safety_assured_block?, <<~PATTERN
          (block
            (send nil? :safety_assured)
            ...
          )
        PATTERN

        def on_block(node)
          return unless safety_assured_block?(node)

          add_offense(node)
        end
      end
    end
  end
end
