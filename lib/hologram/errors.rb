module Hologram
  class CommentLoadError < StandardError
  end
end

module Hologram
  class NoCategoryError < StandardError
    def message
      "Hologram comments found with no defined category. Are there other warnings/errors that need to be resolved?"
    end
  end
end
