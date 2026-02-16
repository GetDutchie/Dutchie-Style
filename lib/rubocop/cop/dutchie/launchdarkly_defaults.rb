# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Dutchie
      # Ensures all LaunchDarkly feature flag calls have default values
      # to prevent failures during LaunchDarkly service outages
      #
      # This cop supports two LaunchDarkly patterns:
      # 1. Armageddon pattern: DutchieFeatureFlags.flag(), .context_flag(), etc.
      # 2. MenuConnector pattern: ld_client.variation(), MenuConnector::App[:launchdarkly].variation()
      #
      # @example Armageddon pattern
      #   # bad
      #   DutchieFeatureFlags.flag("some.flag")
      #   DutchieFeatureFlags.context_flag("some.flag", dispensary_id: id)
      #   DutchieFeatureFlags.on?("some.flag")
      #
      #   # good
      #   DutchieFeatureFlags.flag("some.flag", false)
      #   DutchieFeatureFlags.context_flag("some.flag", default: false, dispensary_id: id)
      #   DutchieFeatureFlags.on?("some.flag", default: false)
      #
      # @example MenuConnector pattern
      #   # bad
      #   ld_client.variation("flag", context)
      #   MenuConnector::App[:launchdarkly].variation("flag", context)
      #
      #   # good
      #   ld_client.variation("flag", context, false)
      #   MenuConnector::App[:launchdarkly].variation("flag", context, false)
      #
      class LaunchDarklyDefaults < ::RuboCop::Cop::Base
        extend AutoCorrector

        MSG_FLAG = 'DutchieFeatureFlags.flag must have a default value as 2nd parameter'
        MSG_CONTEXT_FLAG = 'DutchieFeatureFlags.context_flag must have a default: parameter'
        MSG_DISPENSARY_FLAG = 'DutchieFeatureFlags.dispensary_flag must have a default: parameter'
        MSG_ENTERPRISE_FLAG = 'DutchieFeatureFlags.enterprise_flag must have a default: parameter'
        MSG_ON = 'DutchieFeatureFlags.on? should have a default: parameter'
        MSG_OFF = 'DutchieFeatureFlags.off? should have a default: parameter'
        MSG_VARIATION = 'LaunchDarkly variation must have a default value as 3rd parameter'

        # DutchieFeatureFlags.flag("key", default, ...)
        def_node_matcher :dutchie_flag_call?, <<~PATTERN
          (send
            (const nil? :DutchieFeatureFlags) :flag
            $_
            $...
          )
        PATTERN

        # DutchieFeatureFlags.context_flag("key", ...)
        def_node_matcher :context_flag_call?, <<~PATTERN
          (send
            (const nil? :DutchieFeatureFlags) :context_flag
            $_
            $...
          )
        PATTERN

        # DutchieFeatureFlags.dispensary_flag("key", ...)
        def_node_matcher :dispensary_flag_call?, <<~PATTERN
          (send
            (const nil? :DutchieFeatureFlags) :dispensary_flag
            $_
            $...
          )
        PATTERN

        # DutchieFeatureFlags.enterprise_flag("key", ...)
        def_node_matcher :enterprise_flag_call?, <<~PATTERN
          (send
            (const nil? :DutchieFeatureFlags) :enterprise_flag
            $_
            $...
          )
        PATTERN

        # DutchieFeatureFlags.on?("key", ...)
        def_node_matcher :on_call?, <<~PATTERN
          (send
            (const nil? :DutchieFeatureFlags) :on?
            $_
            $...
          )
        PATTERN

        # DutchieFeatureFlags.off?("key", ...)
        def_node_matcher :off_call?, <<~PATTERN
          (send
            (const nil? :DutchieFeatureFlags) :off?
            $_
            $...
          )
        PATTERN

        # Direct variation calls on ld_client or MenuConnector::App[:launchdarkly]
        def_node_matcher :variation_call?, <<~PATTERN
          (send
            {
              (send nil? :ld_client)
              (send
                (const (const nil? :MenuConnector) :App)
                :[]
                (sym :launchdarkly)
              )
              (send _ :ld_client)
            }
            :variation
            $_
            $...
          )
        PATTERN

        # MockLaunchDarkly variation calls (for test environments)
        def_node_matcher :mock_variation_call?, <<~PATTERN
          (send
            (const (const nil? :MenuConnector) :MockLaunchDarkly)
            :variation
            $_
            $...
          )
        PATTERN

        def on_send(node)
          # Check Armageddon patterns
          check_flag_method(node)
          check_context_flag_method(node)
          check_dispensary_flag_method(node)
          check_enterprise_flag_method(node)
          check_on_method(node)
          check_off_method(node)

          # Check MenuConnector patterns
          check_variation_method(node)
          check_mock_variation_method(node)
        end

        private

        # Armageddon pattern checks

        def check_flag_method(node)
          flag_key, args = dutchie_flag_call?(node)
          return unless flag_key

          # Need at least one more argument after the key (the default value)
          return if args.any?

          add_offense(node, message: MSG_FLAG) do |corrector|
            corrector.insert_after(flag_key, ', false')
          end
        end

        def check_context_flag_method(node)
          flag_key, args = context_flag_call?(node)
          return unless flag_key

          return if has_default_kwarg?(args)

          add_offense(node, message: MSG_CONTEXT_FLAG) do |corrector|
            insert_default_kwarg(corrector, flag_key, args)
          end
        end

        def check_dispensary_flag_method(node)
          flag_key, args = dispensary_flag_call?(node)
          return unless flag_key

          return if has_default_kwarg?(args)

          add_offense(node, message: MSG_DISPENSARY_FLAG) do |corrector|
            insert_default_kwarg(corrector, flag_key, args)
          end
        end

        def check_enterprise_flag_method(node)
          flag_key, args = enterprise_flag_call?(node)
          return unless flag_key

          return if has_default_kwarg?(args)

          add_offense(node, message: MSG_ENTERPRISE_FLAG) do |corrector|
            insert_default_kwarg(corrector, flag_key, args)
          end
        end

        def check_on_method(node)
          flag_key, args = on_call?(node)
          return unless flag_key

          # on? accepts default: as keyword or as second positional argument
          # Return if there's a positional default (non-hash arg) or default: kwarg
          return if has_positional_default?(args) || has_default_kwarg?(args)

          add_offense(node, message: MSG_ON) do |corrector|
            insert_default_kwarg(corrector, flag_key, args)
          end
        end

        def check_off_method(node)
          flag_key, args = off_call?(node)
          return unless flag_key

          # off? accepts default: as keyword or as second positional argument
          # Return if there's a positional default (non-hash arg) or default: kwarg
          return if has_positional_default?(args) || has_default_kwarg?(args)

          add_offense(node, message: MSG_OFF) do |corrector|
            insert_default_kwarg(corrector, flag_key, args)
          end
        end

        # MenuConnector pattern checks

        def check_variation_method(node)
          flag_key, args = variation_call?(node)
          return unless flag_key

          # variation(flag, context, default) - need at least 2 args after flag
          return if args.size >= 2

          add_offense(node, message: MSG_VARIATION) do |corrector|
            if args.empty?
              # No context provided, add both context and default
              corrector.insert_after(flag_key, ', nil, false')
            elsif args.size == 1
              # Context provided but no default
              corrector.insert_after(args.last, ', false')
            end
          end
        end

        def check_mock_variation_method(node)
          # Don't check mock variation calls in test code
          return if in_test_file?(node)

          flag_key, args = mock_variation_call?(node)
          return unless flag_key

          # Same logic as regular variation
          return if args.size >= 2

          add_offense(node, message: MSG_VARIATION) do |corrector|
            if args.empty?
              corrector.insert_after(flag_key, ', nil, false')
            elsif args.size == 1
              corrector.insert_after(args.last, ', false')
            end
          end
        end

        # Helper methods

        def has_default_kwarg?(args)
          args.any? do |arg|
            next false unless arg.hash_type?

            arg.pairs.any? do |pair|
              pair.key.sym_type? && pair.key.value == :default
            end
          end
        end

        def has_positional_default?(args)
          args.any? { |arg| !arg.hash_type? }
        end

        def insert_default_kwarg(corrector, flag_key, args)
          if args.any? && args.last.hash_type?
            # Add to existing hash
            corrector.insert_after(args.last.source_range.end.adjust(begin_pos: -1), ', default: false')
          elsif args.any?
            # Add as new keyword argument after existing args
            corrector.insert_after(args.last, ', default: false')
          else
            # Add as first argument after flag key
            corrector.insert_after(flag_key, ', default: false')
          end
        end

        def in_test_file?(node)
          processed_source.file_path.include?('spec/')
        end
      end
    end
  end
end
