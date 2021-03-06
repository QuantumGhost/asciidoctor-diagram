require 'asciidoctor/extensions'
require_relative 'version'

Asciidoctor::Extensions.register do
  require_relative 'meme/extension'

  block_macro Asciidoctor::Diagram::MemeBlockMacroProcessor, :meme
end
