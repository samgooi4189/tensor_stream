module TensorStream
  class Serializer
    def initialize
    end

    def serialize(filename, tensor, session = nil)
      File.write(filename, get_string(session, tensor.graph))
    end

    def get_string(tensor, session = nil)
    end
  end
end