module PlaceFields
  extend ActiveSupport::Concern

  class_methods do
    def place_field(method_name, parts, alias_to: nil, sep: ", ")
      define_method(method_name) do
        parts.map { |p| respond_to?(p) ? send(p) : nil }.compact_blank.join(sep)
      end
      alias_method alias_to, method_name if alias_to
    end
  end
end
