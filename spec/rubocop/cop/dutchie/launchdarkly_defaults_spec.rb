# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/ExampleLength
RSpec.describe RuboCop::Cop::Dutchie::LaunchDarklyDefaults do
  subject(:cop) { described_class.new }

  describe "DutchieFeatureFlags.flag" do
    context "when missing default value" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          DutchieFeatureFlags.flag("some.flag")
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.flag must have a default value as 2nd parameter
        RUBY

        expect_correction(<<~RUBY)
          DutchieFeatureFlags.flag("some.flag", false)
        RUBY
      end
    end

    context "when default value is provided" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.flag("some.flag", false)
        RUBY
      end

      it "accepts true as default" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.flag("some.flag", true)
        RUBY
      end

      it "accepts additional arguments after default" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.flag("some.flag", false, custom_attributes)
        RUBY
      end
    end
  end

  describe "DutchieFeatureFlags.context_flag" do
    context "when missing default: keyword" do
      it "registers an offense with no other arguments" do
        expect_offense(<<~RUBY)
          DutchieFeatureFlags.context_flag("some.flag")
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.context_flag must have a default: parameter
        RUBY

        expect_correction(<<~RUBY)
          DutchieFeatureFlags.context_flag("some.flag", default: false)
        RUBY
      end

      it "registers an offense with other keyword arguments" do
        expect_offense(<<~RUBY)
          DutchieFeatureFlags.context_flag("some.flag", dispensary_id: id)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.context_flag must have a default: parameter
        RUBY

        expect_correction(<<~RUBY)
          DutchieFeatureFlags.context_flag("some.flag", dispensary_id: id, default: false)
        RUBY
      end
    end

    context "when default: keyword is provided" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.context_flag("some.flag", default: false, dispensary_id: id)
        RUBY
      end

      it "accepts default at any position in kwargs" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.context_flag("some.flag", dispensary_id: id, default: false)
        RUBY
      end
    end
  end

  describe "DutchieFeatureFlags.dispensary_flag" do
    context "when missing default: keyword" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          DutchieFeatureFlags.dispensary_flag("some.flag", dispensary_id: id)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.dispensary_flag must have a default: parameter
        RUBY

        expect_correction(<<~RUBY)
          DutchieFeatureFlags.dispensary_flag("some.flag", dispensary_id: id, default: false)
        RUBY
      end
    end

    context "when default: keyword is provided" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.dispensary_flag("some.flag", dispensary_id: id, default: false)
        RUBY
      end
    end
  end

  describe "DutchieFeatureFlags.enterprise_flag" do
    context "when missing default: keyword" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          DutchieFeatureFlags.enterprise_flag("some.flag", enterprise_id: id)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.enterprise_flag must have a default: parameter
        RUBY

        expect_correction(<<~RUBY)
          DutchieFeatureFlags.enterprise_flag("some.flag", enterprise_id: id, default: false)
        RUBY
      end
    end

    context "when default: keyword is provided" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.enterprise_flag("some.flag", enterprise_id: id, default: false)
        RUBY
      end
    end
  end

  describe "DutchieFeatureFlags.on?" do
    context "when missing default" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          DutchieFeatureFlags.on?("some.flag")
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.on? should have a default: parameter
        RUBY

        expect_correction(<<~RUBY)
          DutchieFeatureFlags.on?("some.flag", default: false)
        RUBY
      end
    end

    context "when default is provided" do
      it "does not register an offense with keyword arg" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.on?("some.flag", default: false)
        RUBY
      end

      it "does not register an offense with positional arg" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.on?("some.flag", false)
        RUBY
      end
    end
  end

  describe "DutchieFeatureFlags.off?" do
    context "when missing default" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          DutchieFeatureFlags.off?("some.flag")
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.off? should have a default: parameter
        RUBY

        expect_correction(<<~RUBY)
          DutchieFeatureFlags.off?("some.flag", default: false)
        RUBY
      end
    end

    context "when default is provided" do
      it "does not register an offense with keyword arg" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.off?("some.flag", default: true)
        RUBY
      end

      it "does not register an offense with positional arg" do
        expect_no_offenses(<<~RUBY)
          DutchieFeatureFlags.off?("some.flag", true)
        RUBY
      end
    end
  end

  describe "edge cases" do
    it "handles calls that are not DutchieFeatureFlags" do
      expect_no_offenses(<<~RUBY)
        SomeOtherClass.flag("some.flag")
      RUBY
    end

    it "handles nested method calls" do
      expect_offense(<<~RUBY)
        if DutchieFeatureFlags.on?("feature.enabled")
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.on? should have a default: parameter
          do_something
        end
      RUBY
    end

    it "handles multiple flags in same file" do
      expect_offense(<<~RUBY)
        DutchieFeatureFlags.flag("first.flag")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.flag must have a default value as 2nd parameter
        DutchieFeatureFlags.on?("second.flag")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/LaunchDarklyDefaults: DutchieFeatureFlags.on? should have a default: parameter
      RUBY
    end
  end
end
# rubocop:enable RSpec/ExampleLength
