require 'spec_helper'

describe Cleanroom do
  let(:klass) do
    Class.new do
      NULL = Object.new.freeze unless defined?(NULL)

      include Cleanroom

      def method1(val = NULL)
        if val.equal?(NULL)
          @method1
        else
          @method1 = val
        end
      end
      expose :method1

      def method2(val = NULL)
        if val.equal?(NULL)
          @method2
        else
          @method2 = val
        end
      end
      expose :method2

      def method3
        @method3 = true
      end

      def method_without_kwargs(arg1)
        @method_without_kwargs_args = {
          arg1: arg1
        }
      end
      expose :method_without_kwargs
      attr_reader :method_without_kwargs_args

      def method_with_kwargs(arg1, kwarg1: 'kwarg_value_1')
        @method_with_kwargs_args = {
          arg1: arg1,
          kwarg1: kwarg1
        }
      end
      expose :method_with_kwargs
      attr_reader :method_with_kwargs_args
    end
  end

  let(:instance) { klass.new }

  describe '#evaluate_file' do
    let(:path) { tmp_path('file.rb') }

    before do
      File.write(path, <<-FILE_CONTENTS.gsub(/^ {10}/, ''))
          method1 'hello'
          method2 false
      FILE_CONTENTS
    end

    it 'evaluates the file' do
      instance.evaluate_file(path)
      expect(instance.method1).to eq('hello')
      expect(instance.method2).to be(false)
    end
  end

  describe '#evaluate' do
    let(:contents) do
      <<-DSL_CODE.gsub(/^ {8}/, '')
        method1 'hello'
        method2 false
      DSL_CODE
    end

    it 'evaluates the file' do
      instance.evaluate(contents)
      expect(instance.method1).to eq('hello')
      expect(instance.method2).to be(false)
    end
  end

  describe 'security' do
    it 'restricts access to __instance__' do
      expect do
        instance.evaluate('__instance__')
      end.to raise_error(Cleanroom::InaccessibleError)
    end

    it 'restricts access to __instance__ using :send' do
      expect do
        instance.evaluate('send(:__instance__)')
      end.to raise_error(Cleanroom::InaccessibleError)
    end

    it 'restricts access to defining new methods' do
      expect do
        instance.evaluate <<-DSL_CODE.gsub(/^ {12}/, '')
          self.class.class_eval do
            def new_method
              __instance__.method3
            end
          end
        DSL_CODE
      end.to raise_error(Cleanroom::InaccessibleError)
      expect(instance.instance_variables).not_to include(:@method3)
    end
  end

  describe 'kwargs handling' do
    it 'does not generate warnings when passing kwargs' do
      expect do
        instance.evaluate <<~DSL_CODE
          method_with_kwargs('arg1_value', kwarg1: 'kwarg_value')
        DSL_CODE
      end.not_to output.to_stderr
      expect(instance.method_with_kwargs_args).to eq(
        arg1: 'arg1_value',
        kwarg1: 'kwarg_value'
      )
    end

    it 'does not extrapolate objects using to_hash to methods not receiving kwargs' do
      instance.evaluate <<~DSL_CODE
        string_with_to_hash = 'Hello'
        string_with_to_hash.define_singleton_method(:to_hash) { { string: self.to_s } }
        method_without_kwargs(string_with_to_hash)
      DSL_CODE
      expect(instance.method_without_kwargs_args).to eq(
        arg1: 'Hello'
      )
    end

    it 'does extrapolate objects using to_hash to methods receiving kwargs without warnings' do
      expect do
        instance.evaluate <<~DSL_CODE
          string_with_to_hash = 'Hello'
          string_with_to_hash.define_singleton_method(:to_hash) { { kwarg1: self.to_s } }
          method_with_kwargs(string_with_to_hash, **string_with_to_hash)
        DSL_CODE
      end.not_to output.to_stderr
      expect(instance.method_with_kwargs_args).to eq(
        arg1: 'Hello',
        kwarg1: 'Hello'
      )
    end
  end
end
