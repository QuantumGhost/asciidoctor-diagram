require_relative 'test_helper'

describe Asciidoctor::Diagram::PlantUmlBlockMacroProcessor do
  it "should generate PNG images when format is set to 'png'" do
    code = <<-eos
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
    eos

    File.write('plantuml.txt', code)

    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

plantuml::plantuml.txt[format="png"]
    eos

    d = Asciidoctor.load StringIO.new(doc)
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    expect(b.content_model).to eq :empty

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(target).to match /\.png$/
    expect(File.exists?(target)).to be true

    expect(b.attributes['width']).to_not be_nil
    expect(b.attributes['height']).to_not be_nil
  end

  it "should support substitutions" do
    code = <<-eos
class {parent-class}
class {child-class}
{parent-class} <|-- {child-class}
    eos

    File.write('plantuml.txt', code)

    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>
:parent-class: ParentClass
:child-class: ChildClass

== First Section

plantuml::plantuml.txt[format="svg", subs=attributes+]
    eos

    d = Asciidoctor.load StringIO.new(doc), :attributes => {'backend' => 'html5'}
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    target = b.attributes['target']
    expect(File.exists?(target)).to be true

    content = File.read(target)
    expect(content).to include('ParentClass')
    expect(content).to include('ChildClass')
  end
end

describe Asciidoctor::Diagram::PlantUmlBlockProcessor do
  it "should generate PNG images when format is set to 'png'" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="png"]
----
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
----
    eos

    d = Asciidoctor.load StringIO.new(doc)
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    expect(b.content_model).to eq :empty

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(target).to match /\.png$/
    expect(File.exists?(target)).to be true

    expect(b.attributes['width']).to_not be_nil
    expect(b.attributes['height']).to_not be_nil
  end

  it "should generate SVG images when format is set to 'svg'" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="svg"]
----
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
----
    eos

    d = Asciidoctor.load StringIO.new(doc)
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    expect(b.content_model).to eq :empty

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(target).to match /\.svg/
    expect(File.exists?(target)).to be true

    expect(b.attributes['width']).to_not be_nil
    expect(b.attributes['height']).to_not be_nil
  end

  it "should generate literal blocks when format is set to 'txt'" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="txt"]
----
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
----
    eos

    d = Asciidoctor.load StringIO.new(doc)
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :literal }
    expect(b).to_not be_nil

    expect(b.content_model).to eq :verbatim

    expect(b.attributes['target']).to be_nil
  end

  it "should raise an error when when format is set to an invalid value" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="foobar"]
----
----
    eos

    expect { Asciidoctor.load StringIO.new(doc) }.to raise_error /support.*format/i
  end

  it "should use plantuml configuration when specified as a document attribute" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>
:plantumlconfig: test.config

== First Section

[plantuml, format="svg"]
----
actor Foo1
boundary Foo2
Foo1 -> Foo2 : To boundary
----
    eos

    config = <<-eos
ArrowColor #DEADBE
    eos

    File.open('test.config', 'w') do |f|
      f.write config
    end

    d = Asciidoctor.load StringIO.new(doc)
    b = d.find { |b| b.context == :image }

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(File.exists?(target)).to be true

    svg = File.read(target)
    expect(svg).to match /<path.*fill="#DEADBE"/
  end

  it "should not regenerate images when source has not changed" do
    code = <<-eos
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
    eos

    File.write('plantuml.txt', code)

    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

plantuml::plantuml.txt

[plantuml, format="png"]
----
actor Foo1
boundary Foo2
Foo1 -> Foo2 : To boundary
----
    eos

    d = Asciidoctor.load StringIO.new(doc)
    b = d.find { |b| b.context == :image }
    target = b.attributes['target']
    mtime1 = File.mtime(target)

    sleep 1

    d = Asciidoctor.load StringIO.new(doc)

    mtime2 = File.mtime(target)

    expect(mtime2).to eq mtime1
  end

  it "should handle two block macros with the same source" do
    code = <<-eos
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
    eos

    File.write('plantuml.txt', code)

    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

plantuml::plantuml.txt[]
plantuml::plantuml.txt[]
    eos

    Asciidoctor.load StringIO.new(doc)
    expect(File.exists?('plantuml.png')).to be true
  end

  it "should respect target attribute in block macros" do
    code = <<-eos
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
    eos

    File.write('plantuml.txt', code)

    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

plantuml::plantuml.txt["foobar"]
plantuml::plantuml.txt["foobaz"]
    eos

    Asciidoctor.load StringIO.new(doc)
    expect(File.exists?('foobar.png')).to be true
    expect(File.exists?('foobaz.png')).to be true
    expect(File.exists?('plantuml.png')).to be false
  end

  it "should respect target attribute values with relative paths in block macros" do
    code = <<-eos
User -> (Start)
User --> (Use the application) : Label

:Main Admin: ---> (Use the application) : Another label
    eos

    File.write('plantuml.txt', code)

    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

plantuml::plantuml.txt["test/foobar"]
plantuml::plantuml.txt["test2/foobaz"]
    eos

    Asciidoctor.load StringIO.new(doc)
    expect(File.exists?('test/foobar.png')).to be true
    expect(File.exists?('test2/foobaz.png')).to be true
    expect(File.exists?('plantuml.png')).to be false
  end

  it "should write files to outdir if set" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="svg"]
----
actor Foo1
boundary Foo2
Foo1 -> Foo2 : To boundary
----
    eos

    d = Asciidoctor.load StringIO.new(doc), {:attributes => {'outdir' => 'foo'}}
    b = d.find { |b| b.context == :image }

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(File.exists?(target)).to be false
    expect(File.exists?(File.expand_path(target, 'foo'))).to be true
  end

  it "should write files to imagesoutdir if set" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="svg"]
----
actor Foo1
boundary Foo2
Foo1 -> Foo2 : To boundary
----
    eos

    d = Asciidoctor.load StringIO.new(doc), {:attributes => {'imagesoutdir' => 'bar', 'outdir' => 'foo'}}
    b = d.find { |b| b.context == :image }

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(File.exists?(target)).to be false
    expect(File.exists?(File.expand_path(target, 'bar'))).to be true
    expect(File.exists?(File.expand_path(target, 'foo'))).to be false
  end

  it "should omit width/height attributes when generating docbook" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="png"]
----
User -> (Start)
----
    eos

    d = Asciidoctor.load StringIO.new(doc), :attributes => {'backend' => 'docbook5'}
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    target = b.attributes['target']
    expect(File.exists?(target)).to be true

    expect(b.attributes['width']).to be_nil
    expect(b.attributes['height']).to be_nil
  end

  it "should support salt diagrams using salt block type" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[salt, format="png"]
----
{
  Just plain text
  [This is my button]
  ()  Unchecked radio
  (X) Checked radio
  []  Unchecked box
  [X] Checked box
  "Enter text here   "
  ^This is a droplist^
}
----
    eos

    d = Asciidoctor.load StringIO.new(doc), :attributes => {'backend' => 'docbook5'}
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    target = b.attributes['target']
    expect(File.exists?(target)).to be true

    expect(b.attributes['width']).to be_nil
    expect(b.attributes['height']).to be_nil
  end

  it "should support salt diagrams using plantuml block type" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="png"]
----
salt
{
  Just plain text
  [This is my button]
  ()  Unchecked radio
  (X) Checked radio
  []  Unchecked box
  [X] Checked box
  "Enter text here   "
  ^This is a droplist^
}
----
    eos

    d = Asciidoctor.load StringIO.new(doc), :attributes => {'backend' => 'docbook5'}
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    target = b.attributes['target']
    expect(File.exists?(target)).to be true

    expect(b.attributes['width']).to be_nil
    expect(b.attributes['height']).to be_nil
  end

  it "should support salt diagrams containing tree widgets" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="png"]
----
salt
{
{T
+A
++a
}
}
----
    eos

    d = Asciidoctor.load StringIO.new(doc), :attributes => {'backend' => 'docbook5'}
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    target = b.attributes['target']
    expect(File.exists?(target)).to be true

    expect(b.attributes['width']).to be_nil
    expect(b.attributes['height']).to be_nil
  end

  it "should support scaling diagrams" do
    doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="png"]
----
A -> B
----
    eos

    scaled_doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="png", scale="1.5"]
----
A -> B
----
    eos

    d = Asciidoctor.load StringIO.new(doc), :attributes => {'backend' => 'html5'}
    unscaled_image = d.find { |b| b.context == :image }

    d = Asciidoctor.load StringIO.new(scaled_doc), :attributes => {'backend' => 'html5'}
    scaled_image = d.find { |b| b.context == :image }

    expect(scaled_image.attributes['width']).to be_within(1).of(unscaled_image.attributes['width'] * 1.5)
    expect(scaled_image.attributes['height']).to be_within(1).of(unscaled_image.attributes['height'] * 1.5)
  end

  it "should handle embedded creole images correctly" do
    creole_doc = <<-eos
= Hello, PlantUML!
Doc Writer <doc@example.com>

== First Section

[plantuml, format="png"]
----
:* You can change <color:red>text color</color>
* You can change <back:cadetblue>background color</back>
* You can change <size:18>size</size>
* You use <u>legacy</u> <b>HTML <i>tag</i></b>
* You use <u:red>color</u> <s:green>in HTML</s> <w:#0000FF>tag</w>
* Use image : <img:sourceforge.jpg>
* Use image : <img:http://www.foo.bar/sourceforge.jpg>
* Use image : <img:file:///sourceforge.jpg>

;
----
    eos

    Asciidoctor.load StringIO.new(creole_doc), :attributes => {'backend' => 'html5'}

    # No real way to assert this since PlantUML doesn't produce an error on file not found
  end

  it "should support substitutions" do
    doc = <<-eos
= Hello, PlantUML!
:parent-class: ParentClass
:child-class: ChildClass

[plantuml,class-inheritence,svg,subs=attributes+]
....
class {parent-class}
class {child-class}
{parent-class} <|-- {child-class}
....
    eos

    d = Asciidoctor.load StringIO.new(doc), :attributes => {'backend' => 'html5'}
    expect(d).to_not be_nil

    b = d.find { |b| b.context == :image }
    expect(b).to_not be_nil

    target = b.attributes['target']
    expect(File.exists?(target)).to be true

    content = File.read(target)
    expect(content).to include('ParentClass')
    expect(content).to include('ChildClass')
  end
end
