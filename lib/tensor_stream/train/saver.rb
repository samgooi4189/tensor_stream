require 'json'
require "zlib"

module TensorStream
  module Train
    # High level class used for loading and saving variables
    class Saver
      include TensorStream::OpHelper

      def save(session, outputdir, global_step: nil,
               latest_filename: nil,
               meta_graph_suffix: 'meta',
               write_meta_graph: true,
               write_state: true,
               strip_default_attrs: false)
        graph = TensorStream::Graph.get_default_graph
        vars = graph.get_collection(GraphKeys::GLOBAL_VARIABLES)

        variables = {}

        gs = eval_global_step(session, global_step)
        output_dump = {
          'variables' => variables,
          'global_step' => gs
        }

        vars.each do |variable|
          val = variable.read_value
          packed_data = Zlib::Deflate.deflate(TensorStream::Packer.pack(val, variable.data_type))
          variables[variable.name] = {
            'shape' => shape_eval(val),
            'data' => Base64.strict_encode64(packed_data)
          }
        end

        FileUtils.mkdir_p(outputdir)
        basename = 'model'
        File.write(File.join(outputdir, "#{basename}.meta"), { "gs" => gs }.to_json)
        new_filename = File.join(outputdir, [basename, gs, '.ckpt'].compact.join('-'))
        File.write(new_filename, output_dump.to_yaml)
        if write_meta_graph
          graph_filename = "#{basename}.yaml"
          TensorStream.train.write_graph(graph, outputdir, graph_filename, serializer: :yaml)
        end
        outputdir
      end

      def restore(_session, modelpath)
        meta_data = JSON.parse(File.read(File.join(modelpath, "model.meta")))
        gs = meta_data['gs']
        input_dump = YAML.safe_load(File.read(File.join(modelpath, ['model', gs, '.ckpt'].compact.join('-'))))

        vars = TensorStream::Graph.get_default_graph.get_collection(GraphKeys::GLOBAL_VARIABLES)
        vars.each do |variable|
          next unless input_dump['variables'].key?(variable.name)

          data = TensorStream::Packer.unpack(Zlib::Inflate.inflate(Base64.decode64(input_dump['variables'][variable.name]['data'])), variable.data_type)
          shape = input_dump['variables'][variable.name]['shape']
          variable.buffer = nil
          variable.value = TensorShape.reshape(data, shape)
        end
      end

      private

      def build_internal(names_to_saveables, reshape: false, sharded: false, max_to_keep: 5,
        keep_checkpoint_every_n_hours: 10000.0,
        name: nil,
        restore_sequentially: false,
        filename: "model",
        build_save: true,
        build_restore: true)
        saveables = _validate_and_slice_inputs(names_to_saveables)
      end

      def _validate_and_slice_inputs(names_to_saveables)
        saveables = []
        seen_ops = []

        names_to_saveables.values.sort_by { |item| item[0] }.each do |name, op|
          _saveable_objects_for_op(op, name).each do |converted_saveable_object|
            _add_saveable(saveables, seen_ops, converted_saveable_object)
          end
        end
        saveables
      end

      def _add_saveable(saveables, seen_ops, saveable)
        raise TensorStream::ValueError, "The same saveable will be restored with two names: #{saveable.name}" if seen_ops.include?(saveable.op)

        saveables << saveable
        seen_ops << saveable.op
      end

      def save_op(filename_tensor, saveables)
        tensor_names = []
        tensors = []
        tensor_slices = []

        saveables.each do |saveable|
          saveable.specs.each do |spec|
            tensor_names << spec.name
            tensors << spec.tensor
            tensor_slices << spec.slice_spec
          end
        end
        i_op(:save_ts, filename_tensor, *tensors)
      end

      def eval_global_step(session, global_step)
        return nil if global_step.nil?

        if global_step.is_a?(Tensor)
          session.last_session_context(global_step.name)
        elsif global_step.is_a?(String) || global_step.is_a?(Symbol)
          session.last_session_context(global_step)
        else
          global_step.to_i
        end
      end
    end
  end
end
