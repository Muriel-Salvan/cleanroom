require 'spec_helper'

describe Cleanroom do
  let(:klass) do
    Class.new do
      NULL = Object.new.freeze unless defined?(NULL)

      include Cleanroom

      def method_1(val = NULL)
        if val.equal?(NULL)
          @method_1
        else
          @method_1 = val
        end
      end
      expose :method_1

      def method_2(val = NULL)
        if val.equal?(NULL)
          @method_2
        else
          @method_2 = val
        end
      end
      expose :method_2

      def method_3
        @method_3 = true
      end

      def method_without_kwargs(arg_1)
        @method_without_kwargs_args = {
          arg_1: arg_1
        }
      end
      expose :method_without_kwargs
      attr_reader :method_without_kwargs_args

      def method_with_kwargs(arg_1, kwarg_1: 'kwarg_value_1')
        @method_with_kwargs_args = {
          arg_1: arg_1,
          kwarg_1: kwarg_1
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
      File.open(path, 'w') do |f|
        f.write <<-EOH.gsub(/^ {10}/, '')
          method_1 'hello'
          method_2 false
        EOH
      end
    end

    it 'evaluates the file' do
      instance.evaluate_file(path)
      expect(instance.method_1).to eq('hello')
      expect(instance.method_2).to be(false)
    end
  end

  describe '#evaluate' do
    let(:contents) do
      <<-EOH.gsub(/^ {8}/, '')
        method_1 'hello'
        method_2 false
      EOH
    end

    it 'evaluates the file' do
      instance.evaluate(contents)
      expect(instance.method_1).to eq('hello')
      expect(instance.method_2).to be(false)
    end
  end

  describe 'security' do
    it 'restricts access to __instance__' do
      expect {
        instance.evaluate("__instance__")
      }.to raise_error(Cleanroom::InaccessibleError)
    end

    it 'restricts access to __instance__ using :send' do
      expect {
        instance.evaluate("send(:__instance__)")
      }.to raise_error(Cleanroom::InaccessibleError)
    end

    it 'restricts access to defining new methods' do
      expect {
        instance.evaluate <<-EOH.gsub(/^ {12}/, '')
          self.class.class_eval do
            def new_method
              __instance__.method_3
            end
          end
        EOH
      }.to raise_error(Cleanroom::InaccessibleError)
      expect(instance.instance_variables).to_not include(:@method_3)
    end
  end

  describe 'kwargs handling' do
    it 'does not generate warnings when passing kwargs' do
      expect do
        instance.evaluate <<~EOH
          method_with_kwargs('arg_1_value', kwarg_1: 'kwarg_value')
        EOH
      end.not_to output.to_stderr
      expect(instance.method_with_kwargs_args).to eq(
        arg_1: 'arg_1_value',
        kwarg_1: 'kwarg_value'
      )
    end

    it 'does not extrapolate objects using to_hash to methods not receiving kwargs' do
      instance.evaluate <<~EOH
        string_with_to_hash = 'Hello'
        string_with_to_hash.define_singleton_method(:to_hash) { { string: self.to_s } }
        method_without_kwargs(string_with_to_hash)
      EOH
      expect(instance.method_without_kwargs_args).to eq(
        arg_1: 'Hello'
      )
    end

    it 'does extrapolate objects using to_hash to methods receiving kwargs without warnings' do
      expect do
        instance.evaluate <<~EOH
          string_with_to_hash = 'Hello'
          string_with_to_hash.define_singleton_method(:to_hash) { { kwarg_1: self.to_s } }
          method_with_kwargs(string_with_to_hash, **string_with_to_hash)
        EOH
      end.not_to output.to_stderr
      expect(instance.method_with_kwargs_args).to eq(
        arg_1: 'Hello',
        kwarg_1: 'Hello'
      )
    end
  end
end
