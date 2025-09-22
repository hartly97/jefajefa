#provides related, relate_to!, unrelate_from!

module Relatable
  extend ActiveSupport::Concern

  included do
    has_many :outgoing_relations, class_name: "Relation", as: :from, dependent: :destroy
    has_many :incoming_relations, class_name: "Relation", as: :to, dependent: :destroy
  end

  def related_records
    (outgoing_relations.includes(:to).map(&:to) + incoming_relations.includes(:from).map(&:from)).uniq
  end

  def relate_to!(other, type: "related")
    Relation.create!(from: self, to: other, relation_type: type)
  end
end


