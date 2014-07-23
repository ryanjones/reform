require 'test_helper'


require 'reform/form/scalar'

class SelfNestedTest < BaseTest
  class Form < Reform::Form
    property :title  do

     end
  end

  let (:song) { Song.new("Crash And Burn") }
  it do
    Form.new(song)

  end

  it do
    form = Form.new(song)

    form.title = Class.new(Reform::Form) do
      @form_name = "ficken"
      def self.name # needed by ActiveModel::Validation and I18N.
          @form_name
        end

      validates :model, :length => {:minimum => 10}


      def update!(object)
        model.replace(object)
      end

    end.new("Crash And Burn") # gets initialized with string (or image object, or whatever).

    form.validate({"title" => "Teaser"})

    form.errors.messages.must_equal({:"title.model"=>["is too short (minimum is 10 characters)"]})


    # validation only kicks in when value present
    form = Form.new(song)
    form.validate({})
    form.errors.messages.must_equal({})
  end

  module Blaa
    def size; model.size; end
      def type; model.class.to_s; end
  end


  class ImageForm < Reform::Form
    # property :image, populate_if_empty: lambda { |object, args| object }  do
    property :image, :features => [Reform::Form::Scalar], :populate_if_empty => Object do
      validates :size,  numericality: { less_than: 10 }
      validates :length, numericality: { greater_than: 1 } # TODO: make better validators and remove AM::Validators at some point.

      # FIXME: does that only work with representable 2.0?
      # def size; model.size; end
      # def type; model.class.to_s; end
    end
  end

  AlbumCover = Struct.new(:image)

  # no image in params AND model.
  it do
    form = ImageForm.new(AlbumCover.new(nil))


    form.validate({})
    form.errors.messages.must_equal({})
  end

  # no image in params but in model.
  it do
    # TODO: implement validations that only run when requested (only_validate_params: true)
    form = ImageForm.new(AlbumCover.new("i don't know how i got here but i'm invalid"))


    form.validate({})
    form.errors.messages.must_equal({})
  end

  # image in params but NOT in model.
  it do
    form = ImageForm.new(AlbumCover.new(nil))

    form.validate({"image" => "I'm OK!"})
    puts form.inspect
    form.errors.messages.must_equal({})
    form.image.model.must_equal "I'm OK!"
  end

  # OK image.
  it "hello" do
    form = ImageForm.new(AlbumCover.new("nil"))

    form.image.model.must_equal "nil"

    form.validate({"image" => "I'm OK!"})
    form.errors.messages.must_equal({})
  end

  # invalid image.
  it "xx"do
    form = ImageForm.new(AlbumCover.new("nil"))


    form.validate({"image" => "I'm too long, is that a problem?"})
    form.errors.messages.must_equal({:"image.size"=>["must be less than 10"]})
  end



  # validate string only if it's in params.
  class StringForm < Reform::Form
    property :image, :features => [Reform::Form::Scalar],
      populate_if_empty: Object do # creates "empty" form

        validates :length => {:minimum => 10}
    end
  end


  # validates when present.
  it do
    form = StringForm.new(AlbumCover.new(nil))
    form.validate("image" => "0x123").must_equal false
    form.image.model.must_equal("0x123")
    # TODO: errors, save
  end

  # does not validate when absent (that's the whole point of this directive).
  it do
    form = StringForm.new(AlbumCover.new(nil))
    form.validate({}).must_equal true
  end

  # DISCUSS: when AlbumCover.new("Hello").validate({}), does that fail?
end